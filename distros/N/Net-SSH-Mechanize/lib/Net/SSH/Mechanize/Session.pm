package Net::SSH::Mechanize::Session;
use Moose;
use MooseX::Params::Validate;
use AnyEvent;
use Carp qw(croak);
our @CARP_NOT = qw(Net::SSH::Mechanize AnyEvent);

our $VERSION = '0.1.3'; # VERSION

extends 'AnyEvent::Subprocess::Running';

my $passwd_prompt_re = qr/assword:\s*/;

my $initial_prompt_re = qr/^.*?\Q$ \E$/m;
my $sudo_initial_prompt_re = qr/^.*?\Q$ \E$/m;

# Create a random text delimiter
# We want chars A-Z, a-z, 0-9, _- => 26+26+10 = 64 different characters.
# First we generate a random string of ASCII chars 1..65,
my $delim = pack "C*", map { int(rand 64)+1 } 1..20;

# Then we map it to the characters we want.
$delim =~ tr/\x01-\x40/A-Za-z0-9_-/;

my $prompt = "$delim";

my $sudo_passwd_prompt = "$delim-passwd";

my $prompt_re = qr/\Q$prompt\E$/sm;

my $sudo_passwd_prompt_re = qr/^$sudo_passwd_prompt$/;


has 'connection_params' => (
    isa => 'Net::SSH::Mechanize::ConnectParams',
    is => 'rw',
    # Note: this made rw and unrequired so that it can be supplied
    # after AnyEvent::Subprocess::Job constructs the instance
);

has 'is_logged_in' => (
    isa => 'Bool',
    is => 'ro',
    writer => '_set_logged_in',
);

has '_error_event' => (
    is => 'rw',
    isa => 'AnyEvent::CondVar',
    default => sub { return AnyEvent->condvar },
);


# The log-in timeout limit in seconds
has 'login_timeout' => (
    is => 'rw',
    isa => 'Int',
    default => 30,
);

# helper function

sub _croak_with {
    my ($msg, $cv) = @_;
    sub {
        my $h = shift;
        return unless my $text = $h->rbuf;
        $h->{rbuf} = '';
        $cv->croak("$msg: $text");
    }
}

sub _warn_with {
    my ($msg) = @_;
    sub {
        my $h = shift;
        return unless my $text = $h->rbuf;
        $h->{rbuf} = '';
        warn "$msg: $text";
    }
}

sub _push_write {
    my $handle = shift;

#    print qq(writing: "@_"\n); # DB
    $handle->push_write(@_);
}


sub _match {
    my $handle = shift;
    my $re = shift;
    return unless $handle->{rbuf};
    my @captures = $handle->{rbuf} =~ /$re/;
    if (!@captures) {
#        print qq(not matching $re: "$handle->{rbuf}"\n); # DB    
        return;
    }

#    printf qq(matching $re with: "%s"\n), substr $handle->{rbuf}, 0, $+[0]; # DB

    substr $handle->{rbuf}, 0, $+[0], "";
    return @captures;
}

sub _define_automation {
    my $self = shift;
    my $states = {@_};
    my $function = (caller 1)[3];
    
    my ($stdin, $stderr) = map { $self->delegate($_)->handle } qw(pty stderr);

    my $state = 'start';
    my $cb;
    $cb = sub {
#        printf "before: state is %s %s\n", $function, $state; # DB 
        $state = $states->{$state}->(@_);
        exists $states->{$state}
            or die "something is wrong, next state returned is an unknown name: '$state'";

#        printf "after: state is %s %s\n", $function, $state; # DB 
        if (!$states->{$state}) { # terminal state, stop reading
#            $stderr->on_read(undef); # cancel errors on stderr
            $stdin->{rbuf} = '';
            return 1;
        }

#        $stdin->push_read($cb);
        return;
    };
    $stdin->push_read($cb);

#    printf "$Coro::current exiting _define_automation\n"; # DB 
    return $state;
};

# FIXME check code for possible self-ref closures which may cause mem leaks


sub login_async {
    my $self = shift;
    my $done = AnyEvent->condvar;

    my $stdin = $self->delegate('pty')->handle;
    my $stderr = $self->delegate('stderr')->handle;

    # Make this a no-op if we've already logged in
    if ($self->is_logged_in) {
        $done->send($stdin, $self);
        return $done;
    }

    $self->_error_event->cb(sub {
#        print "_error_event sent\n"; # DB
        $done->croak(shift->recv);
    });

    my $timeout;
    my $delay = $self->login_timeout;
    $timeout = AnyEvent->timer(
        after => $delay, 
        cb    => sub { 
            undef $timeout;
#            print "timing out login\n"; # DB
            $done->croak("login timed out after $delay seconds");
        },
    );

    # capture stderr output, interpret as an error
    $stderr->on_read(_croak_with "error" => $done);

    $self->_define_automation(
        start => sub {
            if (_match($stdin => $passwd_prompt_re)) {
                if (!$self->connection_params->has_password) {
                    $done->croak('password requested but none provided');
                    return 'auth_failure';
                }
                my $passwd = $self->connection_params->password;
                _push_write($stdin => "$passwd\n");
                return 'sent_passwd';
            }
            
            if (_match($stdin => $initial_prompt_re)) {
                _push_write($stdin => qq(PS1=$prompt; export PS1\n));
                return 'expect_prompt';
            }
            # FIXME limit buffer size and time
            return 'start';
        },
        
        sent_passwd => sub {
            if (_match($stdin => $passwd_prompt_re)) {
                my $msg = $stderr->{rbuf} || '';
                $done->croak("auth failure: $msg");
                return 'auth_failure';
            }
            
            if (_match($stdin => $initial_prompt_re)) {
                _push_write($stdin => qq(PS1=$prompt; export PS1\n));
                return 'expect_prompt';
            }
            
            return 'sent_passwd';
        },
        
        expect_prompt => sub {
            if (_match($stdin => $prompt_re)) {
                # Cancel stderr monitor
                $stderr->on_read(undef);

                $self->_set_logged_in(1);
                $done->send($stdin, $self); # done
                return 'finished';
            }
            
            return 'expect_prompt';
        },
        
        auth_failure => 0,
        finished => 0,
    );

    return $done;
}

    
sub login {
#    return (shift->login_async(@_)->recv)[1];
    my ($cv) = shift->login_async(@_);
#        printf "$Coro::current about to call recv\n"; # DB 
    my $v = ($cv->recv)[1];
#        printf "$Coro::current about to called recv\n"; # DB 
    return $v;
}

sub logout {
    my $self = shift;
    croak "cannot use session yet, as it is not logged in"
        if !$self->is_logged_in;

    _push_write($self->delegate('pty')->handle => "exit\n");
    return $self;
}

sub capture_async {
    my $self = shift;
    my ($cmd) = pos_validated_list(
        \@_,
        { isa => 'Str' },
    );

    croak "cannot use session yet, as it is not logged in"
        if !$self->is_logged_in;

    my $stdin = $self->delegate('pty')->handle;
    my $stderr = $self->delegate('stderr')->handle;

    $cmd =~ s/\s*\z/\n/ms;

    # send command
    _push_write($stdin => $cmd);

    # read result
    my $cumdata = '';

    # we want the _error_event condvar to trigger a croak sent to $done.
    my $done = AnyEvent->condvar;
    # FIXME check _error_event for expiry?
    $self->_error_event->cb(sub {
#        print "xxxx _error_event\n"; # DB
        $done->croak(shift->recv);
    });

    # capture stderr output, interpret as a warning
    $stderr->on_read(_warn_with "unexpected stderr from command");

    my $read_output_cb = sub {
        my ($handle) = @_;
        return unless defined $handle->{rbuf};
        
#        print "got: $handle->{rbuf}\n"; # DB
        
        $cumdata .= $handle->{rbuf};
        $handle->{rbuf} = '';
        
        $cumdata =~ /(.*?)$prompt_re/ms
            or return;

        # cancel stderr monitor
        $stderr->on_read(undef);

        $done->send($handle, $1);
        return 1;
    };
    
    $stdin->push_read($read_output_cb);
    
    return $done;
}


sub capture {
    return (shift->capture_async(@_)->recv)[1];
}


sub sudo_capture_async {
    my $self = shift;
    my ($cmd) = pos_validated_list(
        \@_,
        { isa => 'Str' },
    );

    croak "cannot use session yet, as it is not logged in"
        if !$self->is_logged_in;

    my $done = AnyEvent->condvar;
    $self->_error_event->cb(sub { 
#        print "_error_event sent\n"; DB
        $done->croak(shift->recv);
    });

    # we know we'll need the password, so check this up-front
    if (!$self->connection_params->has_password) {
        croak 'password requested but none provided';
    }

    my $stdin = $self->delegate('pty')->handle;
    my $stderr = $self->delegate('stderr')->handle;

    my $timeout;
    my $delay = $self->login_timeout;
    $timeout = AnyEvent->timer(
        after => $delay, 
        cb    => sub { 
            undef $timeout;
#            print "timing out login\n"; # DB
            $done->croak("sudo_capture timed out after $delay seconds");
        },
    );

    # capture stderr output, interpret as an error
    $stderr->on_read(_croak_with "error" => $done);

    # ensure command has a trailing newline
    $cmd =~ s/\s*\z/\n/ms;

    # get captured result here
    my $cumdata = '';

# FIXME escape/untaint $passwd_prompt_re
# use full path names

    # Authenticate. Erase any cached sudo authentication first - we
    # want to guarantee that we will get a password prompt.  Then
    # start a new shell with sudo.
    _push_write($stdin => "sudo -K; sudo -p '$sudo_passwd_prompt' sh\n");

    $self->_define_automation(
        start => sub {
            if (_match($stdin => $sudo_passwd_prompt_re)) {
                my $passwd = $self->connection_params->password;
#                print "sending password\n"; # DB
                _push_write($stdin => "$passwd\n");
                return 'sent_passwd';
            }
            
            # FIXME limit buffer size and time
            return 'start';
        },
        
        sent_passwd => sub {
            if (_match($stdin => $sudo_passwd_prompt_re)) {
                my $msg = $stderr->{rbuf} || '';
                $done->croak("auth failure: $msg");
                return 'auth_failure';
            }
            
            if (_match($stdin => $prompt_re)) {
                # Cancel stderr monitor
                $stderr->on_read(undef);

                _push_write($stdin => $cmd);
                return 'sent_cmd';
            }
            
            return 'sent_passwd';
        },
        
        sent_cmd => sub {
            if (my ($data) = _match($stdin => qr/(.*?)$prompt_re/sm)) {
                $cumdata .= $data;
#                print "got data: $data\n<$stdin->{rbuf}>\n"; # DB

                $stdin->{rbuf} = '';

                # capture stderr output, interpret as a warning
                $stderr->on_read(_warn_with "unexpected stderr from sudo command");

                # exit sudo shell
                _push_write($stdin => "exit\n");
                
                return 'exited_shell';
            }
            
            $cumdata .= $stdin->{rbuf};
            $stdin->{rbuf} = '';
            return 'sent_cmd';
        },

        exited_shell => sub {
            if (_match($stdin => $prompt_re)) {
                # Cancel stderr monitor
                $stderr->on_read(undef);

                # remove any output from the exit
                # FIXME should this check that everything has been consumed?
                $stdin->{rbuf} = ''; 

                $done->send($stdin, $cumdata); # done, send data collected
                return 'finished';
            }
            
            return 'exited_shell';
        },

        auth_failure => 0,
        finished => 0,
    );

    return $done;
}

sub sudo_capture {
    return (shift->sudo_capture_async(@_)->recv)[1];
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Net::SSH::Mechanize::Session - manage a running ssh process.

=head1 VERSION

version 0.1.3

=head1 SYNOPSIS

This class represents a sunning C<ssh> process. It is a subclass of
C<AnyEvent::Subprocess::Running>, with methods to manage the
authentication and other interaction with the sub-process.

Typically you will not create one directly, but obtain one via 
C<< Net::SSH::Mechanize::Session->login >>, 
or C<< Net::SSH::Mechanize->session >>

You might invoke methods directly, or via C<Net::SSH::Mechanize>
instance's methods which delegate to the instance's C<session>
attribute (which is an instance of this class).

   use Net::SSH::Mechanize;

   my $mech = Net::SSH::Mechanize->new(hostname => 'somewhere');

   my $session = $mech->session;
   # ...

=head1 CLASS METHODS

=head2 C<< $obj = $class->new(%params) >>

Creates a new instance.  Not intended for public use.  Use 
C<< Net::SSH::Mechanize->session >> instead.

=head1 INSTANCE ATTRIBUTES

=head2 C<< $params = $obj->connection_params >>

This is a read-only accessor for the C<connection_params> instance
passed to the constructor by C<Net::SSH::Mechanize>.

=head2 C<< $obj->login_timeout($integer) >>
=head2 C<< $integer = $obj->login_timeout >>

This is a read-write accessor to the log-in timeout parameter passed
to the constructor.

If you plan to modify it, do so before C<< ->login >> or 
C<< ->login_async >> has been invoked or it will not have any effect
on anything.

=head1 INSTANCE METHODS

Note, all of these will throw an exception if used before C<< ->login >>
 or before C<< ->login_async >> has successfully completed, except
of course C<< ->login >> and C<< ->login_async >> themselves.  
These latter methods do nothing after the first invocation.

=head2 C<< $session = $obj->login >>

This method logs into the remote host using the defined connection
parameters, and returns a C<Net::SSH::Mechanize::Session> instance on
success, or throws an exception on failure.

It is safe to use in C<AnyEvent> applications or C<Coro> co-routines,
because the implementation is asynchronous and will not block the
whole process.

=head2 C<< $condvar = $obj->login_async >>

This is an asynchronous method used to implement the synchronous 
C<< ->login >> method.  It returns an AnyEvent::CondVar instance 
immediately, which can be used to wait for completion, or register a
callback to be notified when the log-in has completed.

=head2 C<< $obj->logout >>

Logs out of the remote host by issuing an "exit" command.

=head2 C<< $condvar = $obj->capture_async($command) >>

The returns a condvar immediately, which can be used to wait for
successful completion (or otherwise) of the command(s) defined by
C<$command>.

=head2 C<< $result = $obj->capture($command) >>

This invokes the command(s) defined by C<$command> on the remote host,
and returns the result.

=head2 C<< $condvar = $obj->sudo_capture_async($command) >>

The returns a condvar immediately, which can be used to wait for
successful completion (or otherwise) in a sudo'ed sub-shell of the
command(s) defined by C<$command>.

A password is required in C<connection_params> for this to
authenticate with sudo.

=head2 C<< $result = $obj->sudo_capture($command) >>

This invokes the command(s) defined by C<$command> in a sudo'ed sub-shell
on the remote host, and returns the result.


=head1 AUTHOR

Nick Stokoe  C<< <wulee@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011, Nick Stokoe C<< <wulee@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
