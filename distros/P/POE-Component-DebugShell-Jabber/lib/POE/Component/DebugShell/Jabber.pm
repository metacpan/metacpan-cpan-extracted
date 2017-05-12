package POE::Component::DebugShell::Jabber;

use warnings;
use strict;

use 5.006;

use Carp;

use POE qw( Component::Jabber Component::Jabber::Error);
use POE::API::Peek;
use POE::Filter::XML::Node;
use POE::Filter::XML::NS qw/ :JABBER :IQ /;

our $VERSION = '0.04';
our $RUNNING = 0;
our %COMMANDS = ( #{{{

    'reload' => {
        help => "Reload the shell to catch updates.",
        short_help => "Reload the shell to catch updates.",
        cmd => \&cmd_reload,
    },

    show_sessions => {
        help => 'Show a list of all sessions in the system. The output format is in the form of loggable session ids.',
        short_help => 'Show a list of all sessions',
        cmd => \&cmd_show_sessions,
    },

    'list_aliases' => {
        help => 'List aliases for a given session id. Provide one session id as a parameter.',
        short_help => 'List aliases for a given session id.',
        cmd => \&cmd_list_aliases,
    },

    'session_stats' => {
        help => 'Display various statistics for a given session id. Provide one session id as a parameter.',
        short_help => 'Display various statistics for a given session id.',
        cmd => \&cmd_session_stats,
    },

    'queue_dump' => {
        help => 'Dump the contents of the event queue.',
        short_help => 'Dump the contents of the event queue.',
        cmd => \&cmd_queue_dump,
    },

    'status' => {
        help => 'General shell status.',
        short_help => 'General shell status.',
        cmd => \&cmd_status,
    },

#    'shutdown' => {
#        help => 'Shutdown the jabber component',
#        short_help => 'Shutdown this component',
#        cmd => \&cmd_shutdown,
#    },
); #}}}
our $SPAWN_TIME;

sub spawn { #{{{
    my $class = shift;
    my %opts = @_;

    carp "".__PACKAGE__."::spawn() : 'jabber' must be a hash ref, read the docs"
        unless ($opts{jabber} && ref($opts{jabber}) eq 'HASH');

    carp "".__PACKAGE__."::spawn() : 'jabber_client' must be a package name like POE::Component::Jabber::Client::XMPP"
        unless ($opts{jabber_package} && $opts{jabber_package} =~ m/^POE::Component::Jabber/);

    # optional
    $opts{users} ||= {};
    
    # Singleton check {{{
    if($RUNNING) {
        carp "A ".__PACKAGE__." session is already running. Will not start a second.";
        return undef;
    } else {
        $RUNNING = 1;
    }
    # }}}

    my $api = POE::API::Peek->new() or croak "Unable to create POE::API::Peek object";

    if ($opts{cmds} && ref($opts{cmds}) eq 'HASH') {
        foreach (keys %{$opts{cmds}}) {
            $COMMANDS{$_} = $opts{cmds}->{$_};
        }
        delete $opts{cmds};
    }

    # Session creation {{{
    my $sess = POE::Session->create(
        inline_states => {
            _start      => \&_start,
            _stop       => \&_stop,

            jabber_input  => \&jabber_input,
            error_event => \&error_event,
            init_finished => \&init_finished,
        },
        heap => {
            %opts,
            api         => $api,
        },
    );
    # }}}

    if($sess) {
        $SPAWN_TIME = time();
        return $sess;
    } else {
        return undef;
    }
} #}}}



sub _start { #{{{
    $_[KERNEL]->alias_set(__PACKAGE__." controller");

    my $pkg = $_[HEAP]->{jabber_package};
    eval "use $pkg;";
    carp $@ if ($@);
    
	$pkg->new(
		ALIAS => __PACKAGE__." jabber",
		DEBUG => '0',
		STATE_PARENT => $_[SESSION]->ID,
		STATES => {
			InitFinish => 'init_finished',
			InputEvent => 'jabber_input',
			ErrorEvent => 'error_event',
		},
        %{$_[HEAP]->{jabber}},
	);

    unless ($_[HEAP]->{no_std_tie}) {
        tie *STDOUT, __PACKAGE__."::Output", 'stdout', \&_output;
        tie *STDERR, __PACKAGE__."::Output", 'stderr', \&_output;
    }

    if ($_[HEAP]->{ties}) {
        foreach (@{$_[HEAP]->{ties}}) {
            tie *$_, __PACKAGE__."::Output", $_, \&_output;
        }
    }

} #}}}



sub _stop { #{{{
    # Shut things down
    $_[HEAP]->{vt} && $_[HEAP]->{vt}->delete_window($_[HEAP]->{main_window});
} #}}}



sub old_input { #{{{
    my ($input, $exception) = @_[ARG0, ARG1];

    unless (defined $input) {
        croak("Received exception from UI: $exception");
    }

    if($input =~ /^help (.*?)$/) {
        my $cmd = $1;
        if($COMMANDS{$cmd}) {
            if($COMMANDS{$cmd}{help}) {
                _output("Help for $cmd:");
                _output($COMMANDS{$cmd}{help});
            } else {
                _output("Error: '$cmd' has no help.");
            }
        } else {
            _output("Error: '$cmd' is not a known command");
        }
    } elsif ( ($input eq 'help') or ($input eq '?') ) {
        my $text;
        _output(' ');
        _output("General help for ".__PACKAGE__." v$VERSION");
        _output("The following commands are available:");
        foreach my $cmd (sort keys %COMMANDS) {
            no warnings;
            my $short_help = $COMMANDS{$cmd}{short_help} || '[ No short help provided ]';
            _output("\t* $cmd - $short_help");
        }
        _output(' ');

    } else  {
        my ($cmd, @args);
        if($input =~ /^(.+?)\s+(.*)$/) {
            $cmd = $1;
            my $args = $2;
            @args = split('\s+',$args) if $args;
        } else {
            $cmd = $input;
        }

        if($COMMANDS{$cmd}) {
            my $txt = eval { $COMMANDS{$cmd}{cmd}->( api => $_[HEAP]->{api}, args => \@args); };
            if($@) {
                _output("Error running $cmd: $@");
            } else {
                my @lines = split(/\n/, $txt);
                _output($_) for @lines;
            }
        } else {
            _output("Error: '$cmd' is not a known command");
        }
    }

} #}}}



sub _output { #{{{
    my $msg = shift || ' ';
    my $heap = $poe_kernel->alias_resolve(__PACKAGE__." controller")->get_heap();
    return unless ($heap->{sid});
    my $hash = ($heap->{to}) ? {$heap->{to} => 1} : $heap->{users};
    foreach (keys %{$hash}) {
    	my $n = POE::Filter::XML::Node->new('message');
    	$n->attr('from',$heap->{jid});
    	$n->attr('to',$_);
    	$n->attr('xmlns','jabber:client');
    	$n->insert_tag('body')->data($msg);
        $poe_kernel->post($heap->{sid} => output_handler => $n);
    }
} #}}}

sub _raw_commands { #{{{
    return \%COMMANDS;
} #}}}

# {{{


###############

sub cmd_shutdown {
    
}

sub cmd_reload { #{{{
    my $ret;
    $ret .= "Reloading....\n";
    eval q|
        no warnings qw(redefine);
        $SIG{__WARN__} = sub { };

        my $p = __PACKAGE__;
        $p =~ s/\:\:/\//g;
        foreach my $key (keys %INC) {
            if($key =~ m#$p#) {
                delete $INC{$key};
            } elsif ($key =~ m#POE/API/Peek#) {
                delete $INC{$key};
            }
        }
        require __PACKAGE__;
    |;
    $ret .= "Error: $@\n" if $@;

    return $ret;
} #}}}

sub cmd_show_sessions { #{{{
    my %args = @_;
    my $api = $args{api};

    my $ret;
    $ret .= "Session List:\n";
    my @sessions = $api->session_list;
    foreach my $sess (@sessions) {
        my $id = $sess->ID. " [ ".$api->session_id_loggable($sess)." ]";
        $ret .= "\t* $id\n";
    }

    return $ret;
} #}}}

sub cmd_list_aliases { #{{{
    my %args = @_;
    my $user_args = $args{args};
    my $api = $args{api};

    my $ret;

    if(my $id = shift @$user_args) {
        if(my $sess = $api->resolve_session_to_ref($id)) {
            my @aliases = $api->session_alias_list($sess);
            if(@aliases) {
                $ret .= "Alias list for session $id\n";
                foreach my $alias (sort @aliases) {
                    $ret .= "\t* $alias\n";
                }
            } else {
                $ret .= "No aliases found for session $id\n";
            }
        } else {
            $ret .= "** Error: ID $id does not resolve to a session. Sorry.\n";
        }

    } else {
        $ret .= "** Error: Please provide a session id\n";
    }
    return $ret;
}

# }}}

sub cmd_session_stats { #{{{
    my %args = @_;
    my $user_args = $args{args};
    my $api = $args{api};

    my $ret;

    if(my $id = shift @$user_args) {
        if(my $sess = $api->resolve_session_to_ref($id)) {
            my $to = $api->event_count_to($sess);
            my $from = $api->event_count_from($sess);
            $ret .= "Statistics for Session $id\n";
            $ret .= "\tEvents coming from: $from\n";
            $ret .= "\tEvents going to: $to\n";

        } else {
            $ret .= "** Error: ID $id does not resolve to a session. Sorry.\n";
        }


    } else {
        $ret .= "** Error: Please provide a session id\n";
    }

    return $ret;
} #}}}

sub cmd_queue_dump { #{{{
    my %args = @_;
    my $api = $args{api};
    my $verbose;

    my $ret;

    if($args{args} && defined $args{args}) {
        if(ref $args{args} eq 'ARRAY') {
            if(@{$args{args}}[0] eq '-v') {
                $verbose = 1;
            }
        }
    }

    my @queue = $api->event_queue_dump();

    $ret .= "Event Queue:\n";

    foreach my $item (@queue) {
        $ret .= "\t* ID: ". $item->{ID}." - Index: ".$item->{index}."\n";
        $ret .= "\t\tPriority: ".$item->{priority}."\n";
        $ret .= "\t\tEvent: ".$item->{event}."\n";

        if($verbose) {
            $ret .= "\t\tSource: ".
                    $api->session_id_loggable($item->{source}).
                    "\n";
            $ret .= "\t\tDestination: ".
                    $api->session_id_loggable($item->{destination}).
                    "\n";
            $ret .= "\t\tType: ".$item->{type}."\n";
            $ret .= "\n";
        }
    }
    return $ret;
} #}}}

sub cmd_status { #{{{
    my %args = @_;
    my $api = $args{api};
    my $sess_count = $api->session_count;
    my $ret = "\n";
    $ret .= "This is ".__PACKAGE__." v".$VERSION."\n";
    $ret .= "running inside $0."."\n";
    $ret .= "This console was spawned at ".localtime($SPAWN_TIME).".\n";
    $ret .= "There are $sess_count known sessions (including the kernel).\n";
    $ret .= "\n";
    return $ret;
} # }}}

# }}}

sub init_finished() {
	my ($kernel, $sender, $heap, $jid) = @_[KERNEL, SENDER, HEAP, ARG0];
	
	$heap->{'jid'} = $jid;
	$heap->{'sid'} = $sender->ID();
	my $node = POE::Filter::XML::Node->new('presence');
	$node->insert_tag('status')->data('Online');
	$node->insert_tag('priority')->data('8');
	$node->attr('xmlns','jabber:client');
	$node->attr('from',$jid);
    
    $kernel->post($heap->{sid} => output_handler => $node);
    
    _output("Welcome to POE Debug Shell v$VERSION");
}

sub jabber_input() {
	my ($kernel, $heap, $self, $node) = @_[KERNEL, HEAP, OBJECT, ARG0];
	
	my $at = $node->get_attrs();
    my $from = $at->{from};
	$at->{from} =~ s/\/.+//;
    
	if ($node->name() eq 'presence') {
		
		if ($at->{from} && $at->{from} =~ m/\@/ && $at->{from} ne $at->{to}) {
			my $n = POE::Filter::XML::Node->new('presence');
			$n->insert_tag('status')->data('Online');
			$n->insert_tag('priority')->data('8');
			$n->attr('from',$heap->{'jid'});
			$n->attr('to',$from);
			$n->attr('xmlns','jabber:client');
	
            $kernel->post($heap->{sid} => output_handler => $n);
			return;
		}
	}

	if($node->name() eq 'message') {
		my $input = $node->get_tag('body')->data;
		return if ($at->{from} eq $at->{to});
		
        $heap->{users}->{$at->{from}} = 1;
        $heap->{to} = $from;

     if($input =~ /^help (.*?)$/) {
        my $cmd = $1;
        if($COMMANDS{$cmd}) {
            if($COMMANDS{$cmd}{help}) {
                _output("Help for $cmd:");
                _output($COMMANDS{$cmd}{help});
            } else {
                _output("Error: '$cmd' has no help.");
            }
        } else {
            _output("Error: '$cmd' is not a known command");
        }
    } elsif ( ($input eq 'help') or ($input eq '?') ) {
        my $text;
        _output(' ');
        _output("General help for ".__PACKAGE__." v$VERSION");
        _output("The following commands are available:");
        foreach my $cmd (sort keys %COMMANDS) {
            no warnings;
            my $short_help = $COMMANDS{$cmd}{short_help} || '[ No short help provided ]';
            _output("\t* $cmd - $short_help");
        }
        _output(' ');

    } else  {
        my ($cmd, @args);
        if($input =~ /^(.+?)\s+(.*)$/) {
            $cmd = $1;
            my $args = $2;
            @args = split('\s+',$args) if $args;
        } else {
            $cmd = $input;
        }

        if($COMMANDS{$cmd}) {
            my $txt = eval { $COMMANDS{$cmd}{cmd}->( api => $_[HEAP]->{api}, args => \@args); };
            if($@) {
                _output("Error running $cmd: $@");
            } else {
                if ($txt) {
                  my @lines = split(/\n/, $txt);
                   _output($_) for @lines;
                }
            }
        } else {
            _output("Error: '$cmd' is not a known command");
        }
    }
    delete $heap->{to};
    }
}

sub error_event() {
	my ($kernel, $sender, $heap, $error) = @_[KERNEL, SENDER, HEAP, ARG0];

	if($error == +PCJ_SOCKFAIL)
	{
		my ($call, $code, $err) = @_[ARG1..ARG3];
		print "Socket error: $call, $code, $err\n";
	
	} elsif($error == +PCJ_SOCKDISC) {
		
		print "We got disconneted\n";
		print "Reconnecting!\n";
		$kernel->post($sender, 'reconnect_to_server');

	} elsif ($error == +PCJ_AUTHFAIL) {

		print "Failed to authenticate\n";

	} elsif ($error == +PCJ_BINDFAIL) {

		print "Failed to bind a resource\n";
	
	} elsif ($error == +PCJ_SESSFAIL) {

		print "Failed to establish a session\n";
	}
}

1;

package POE::Component::DebugShell::Jabber::Output;

use strict;
#use warnings FATAL => "all";

sub PRINT { 
    my $self = shift;
    my $txt = join('',@_);
#    $txt =~ s/\r?\n$//;
    $self->{print}->($self->{type}."> $txt");
}

sub TIEHANDLE {
    my $class = shift;
    bless({
        type => shift,
        print => shift,
    }, $class);
}

1;
__END__

=pod

=head1 NAME

POE::Component::DebugShell::Jabber - Component to allow interactive peeking into a 
running POE application via Jabber

=head1 SYNOPSIS

    use POE::Component::DebugShell::Jabber;

    POE::Component::DebugShell::Jabber->spawn(
       jabber_package => 'POE::Component::Jabber::Client::XMPP',
       jabber => {
          IP => 'localhost',
          HOSTNAME => 'localhost',
          PORT => '5222',
          USERNAME => 'bot',
          PASSWORD => 'test', 
       },
       users => {
           'blah@somehost.com' => 1,
       },
    );

=head1 DESCRIPTION

This component allows for interactive peeking into a running POE
application.

C<spawn()> creates a Jabber client shell equipped with various debug
commands.  After it connects, stdout and stderr is redirected to all
users in the user hash, AND anyone who speaks to the bot.  Everyone
can issue commands.

The following commands are available.

=head1 COMMANDS

=head2 show_sessions

 debug> show_sessions
    * 3 [ session 3 (POE::Component::DebugShell::Jabber controller) ]
    * 2 [ session 2 (PIE, PIE2) ]

Show a list of all sessions in the system. The output format is in the
form of loggable session ids.

=head2 session_stats

 debug> session_stats 2
    Statistics for Session 2
        Events coming from: 1
        Events going to: 1

Display various statistics for a given session. Provide one session id
as a parameter.

=head2 list_aliases

 debug> list_aliases 2
    Alias list for session 2
        * PIE
        * PIE2

List aliases for a given session id. Provide one session id as a
parameter.

=head2 queue_dump

 debug> queue_dump
    Event Queue:
        * ID: 738 - Index: 0
            Priority: 1078459009.06715
            Event: _sigchld_poll
        * ID: 704 - Index: 1
            Priority: 1078459012.42691
            Event: ping

Dump the contents of the event queue. Add a C<-v> parameter to get
verbose output.

=head2 help

 debug> help
    The following commands are available:
        ...

Display help about available commands.

=head2 status

 debug> status
    This is POE::Component::DebugShell::Jabber v0.01
    running inside examples/foo.perl.
    This console spawned at Fri Apr 29 11:00:34 2004.
    There are 3 known sessions (including the kernel).

General shell status.

=head2 reload

 debug> reload
 Reloading...

Reload the shell

=head2 exit

 debug> exit
 Exiting...

Exit the shell

=head1 DEVELOPERS

Note from Matt:
For you wacky developers, I've provided access to the raw command data
via the C<_raw_commands> method. The underbar at the beginning should 
let you know that this is an experimental interface for developers only. 

C<_raw_commands> returns a hash reference. The keys of this hash are the
command names. The values are a hash of data about the command. This
hash contains the following data:

=over 4

=item * short_help

Short help text

=item * help

Long help text

=item * cmd

Code reference for the command. This command requires that a hash be
passed to it containing an C<api> parameter, which is a 
C<POE::API::Peek> object, and an C<args> parameter, which is an array
reference of arguments (think C<@ARGV>).

=head1 AUTHOR

David Davis (xantus@cpan.org)

=head2 THANKS

Matt Cashner (cpan@eekeek.org)

=head1 LICENSE

Copyright (c) 2005, David Davis

Permission is hereby granted, free of charge, to any person obtaining 
a copy of this software and associated documentation files (the 
"Software"), to deal in the Software without restriction, including 
without limitation the rights to use, copy, modify, merge, publish, 
distribute, sublicense, and/or sell copies of the Software, and to 
permit persons to whom the Software is furnished to do so, subject 
to the following conditions:

The above copyright notice and this permission notice shall be included 
in all copies or substantial portions of the Software.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

# sungo // vim: ts=4 sw=4 expandtab
