#line 1
package Test2::API::Context;
use strict;
use warnings;

our $VERSION = '1.302175';


use Carp qw/confess croak/;
use Scalar::Util qw/weaken blessed/;
use Test2::Util qw/get_tid try pkg_to_file get_tid/;

use Test2::EventFacet::Trace();
use Test2::API();

# Preload some key event types
my %LOADED = (
    map {
        my $pkg  = "Test2::Event::$_";
        my $file = "Test2/Event/$_.pm";
        require $file unless $INC{$file};
        ( $pkg => $pkg, $_ => $pkg )
    } qw/Ok Diag Note Plan Bail Exception Waiting Skip Subtest Pass Fail V2/
);

use Test2::Util::ExternalMeta qw/meta get_meta set_meta delete_meta/;
use Test2::Util::HashBase qw{
    stack hub trace _on_release _depth _is_canon _is_spawn _aborted
    errno eval_error child_error thrown
};

# Private, not package vars
# It is safe to cache these.
my $ON_RELEASE = Test2::API::_context_release_callbacks_ref();
my $CONTEXTS   = Test2::API::_contexts_ref();

sub init {
    my $self = shift;

    confess "The 'trace' attribute is required"
        unless $self->{+TRACE};

    confess "The 'hub' attribute is required"
        unless $self->{+HUB};

    $self->{+_DEPTH} = 0 unless defined $self->{+_DEPTH};

    $self->{+ERRNO}       = $! unless exists $self->{+ERRNO};
    $self->{+EVAL_ERROR}  = $@ unless exists $self->{+EVAL_ERROR};
    $self->{+CHILD_ERROR} = $? unless exists $self->{+CHILD_ERROR};
}

sub snapshot { bless {%{$_[0]}, _is_canon => undef, _is_spawn => undef, _aborted => undef}, __PACKAGE__ }

sub restore_error_vars {
    my $self = shift;
    ($!, $@, $?) = @$self{+ERRNO, +EVAL_ERROR, +CHILD_ERROR};
}

sub DESTROY {
    return unless $_[0]->{+_IS_CANON} || $_[0]->{+_IS_SPAWN};
    return if $_[0]->{+_ABORTED} && ${$_[0]->{+_ABORTED}};
    my ($self) = @_;

    my $hub = $self->{+HUB};
    my $hid = $hub->{hid};

    # Do not show the warning if it looks like an exception has been thrown, or
    # if the context is not local to this process or thread.
    {
        # Sometimes $@ is uninitialized, not a problem in this case so do not
        # show the warning about using eq.
        no warnings 'uninitialized';
        if($self->{+EVAL_ERROR} eq $@ && $hub->is_local) {
            require Carp;
            my $mess = Carp::longmess("Context destroyed");
            my $frame = $self->{+_IS_SPAWN} || $self->{+TRACE}->frame;
            warn <<"            EOT";
A context appears to have been destroyed without first calling release().
Based on \$@ it does not look like an exception was thrown (this is not always
a reliable test)

This is a problem because the global error variables (\$!, \$@, and \$?) will
not be restored. In addition some release callbacks will not work properly from
inside a DESTROY method.

Here are the context creation details, just in case a tool forgot to call
release():
  File: $frame->[1]
  Line: $frame->[2]
  Tool: $frame->[3]

Here is a trace to the code that caused the context to be destroyed, this could
be an exit(), a goto, or simply the end of a scope:
$mess

Cleaning up the CONTEXT stack...
            EOT
        }
    }

    return if $self->{+_IS_SPAWN};

    # Remove the key itself to avoid a slow memory leak
    delete $CONTEXTS->{$hid};
    $self->{+_IS_CANON} = undef;

    if (my $cbk = $self->{+_ON_RELEASE}) {
        $_->($self) for reverse @$cbk;
    }
    if (my $hcbk = $hub->{_context_release}) {
        $_->($self) for reverse @$hcbk;
    }
    $_->($self) for reverse @$ON_RELEASE;
}

# release exists to implement behaviors like die-on-fail. In die-on-fail you
# want to die after a failure, but only after diagnostics have been reported.
# The ideal time for the die to happen is when the context is released.
# Unfortunately die does not work in a DESTROY block.
sub release {
    my ($self) = @_;

    ($!, $@, $?) = @$self{+ERRNO, +EVAL_ERROR, +CHILD_ERROR} and return if $self->{+THROWN};

    ($!, $@, $?) = @$self{+ERRNO, +EVAL_ERROR, +CHILD_ERROR} and return $self->{+_IS_SPAWN} = undef
        if $self->{+_IS_SPAWN};

    croak "release() should not be called on context that is neither canon nor a child"
        unless $self->{+_IS_CANON};

    my $hub = $self->{+HUB};
    my $hid = $hub->{hid};

    croak "context thinks it is canon, but it is not"
        unless $CONTEXTS->{$hid} && $CONTEXTS->{$hid} == $self;

    # Remove the key itself to avoid a slow memory leak
    $self->{+_IS_CANON} = undef;
    delete $CONTEXTS->{$hid};

    if (my $cbk = $self->{+_ON_RELEASE}) {
        $_->($self) for reverse @$cbk;
    }
    if (my $hcbk = $hub->{_context_release}) {
        $_->($self) for reverse @$hcbk;
    }
    $_->($self) for reverse @$ON_RELEASE;

    # Do this last so that nothing else changes them.
    # If one of the hooks dies then these do not get restored, this is
    # intentional
    ($!, $@, $?) = @$self{+ERRNO, +EVAL_ERROR, +CHILD_ERROR};

    return;
}

sub do_in_context {
    my $self = shift;
    my ($sub, @args) = @_;

    # We need to update the pid/tid and error vars.
    my $clone = $self->snapshot;
    @$clone{+ERRNO, +EVAL_ERROR, +CHILD_ERROR} = ($!, $@, $?);
    $clone->{+TRACE} = $clone->{+TRACE}->snapshot(pid => $$, tid => get_tid());

    my $hub = $clone->{+HUB};
    my $hid = $hub->hid;

    my $old = $CONTEXTS->{$hid};

    $clone->{+_IS_CANON} = 1;
    $CONTEXTS->{$hid} = $clone;
    weaken($CONTEXTS->{$hid});
    my ($ok, $err) = &try($sub, @args);
    my ($rok, $rerr) = try { $clone->release };
    delete $clone->{+_IS_CANON};

    if ($old) {
        $CONTEXTS->{$hid} = $old;
        weaken($CONTEXTS->{$hid});
    }
    else {
        delete $CONTEXTS->{$hid};
    }

    die $err  unless $ok;
    die $rerr unless $rok;
}

sub done_testing {
    my $self = shift;
    $self->hub->finalize($self->trace, 1);
    return;
}

sub throw {
    my ($self, $msg) = @_;
    $self->{+THROWN} = 1;
    ${$self->{+_ABORTED}}++ if $self->{+_ABORTED};
    $self->release if $self->{+_IS_CANON} || $self->{+_IS_SPAWN};
    $self->trace->throw($msg);
}

sub alert {
    my ($self, $msg) = @_;
    $self->trace->alert($msg);
}

sub send_ev2_and_release {
    my $self = shift;
    my $out  = $self->send_ev2(@_);
    $self->release;
    return $out;
}

sub send_ev2 {
    my $self = shift;

    my $e;
    {
        local $Carp::CarpLevel = $Carp::CarpLevel + 1;
        $e = Test2::Event::V2->new(
            trace => $self->{+TRACE}->snapshot,
            @_,
        );
    }

    if ($self->{+_ABORTED}) {
        my $f = $e->facet_data;
        ${$self->{+_ABORTED}}++ if $f->{control}->{halt} || defined($f->{control}->{terminate}) || defined($e->terminate);
    }
    $self->{+HUB}->send($e);
}

sub build_ev2 {
    my $self = shift;

    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    Test2::Event::V2->new(
        trace => $self->{+TRACE}->snapshot,
        @_,
    );
}

sub send_event_and_release {
    my $self = shift;
    my $out = $self->send_event(@_);
    $self->release;
    return $out;
}

sub send_event {
    my $self  = shift;
    my $event = shift;
    my %args  = @_;

    my $pkg = $LOADED{$event} || $self->_parse_event($event);

    my $e;
    {
        local $Carp::CarpLevel = $Carp::CarpLevel + 1;
        $e = $pkg->new(
            trace => $self->{+TRACE}->snapshot,
            %args,
        );
    }

    if ($self->{+_ABORTED}) {
        my $f = $e->facet_data;
        ${$self->{+_ABORTED}}++ if $f->{control}->{halt} || defined($f->{control}->{terminate}) || defined($e->terminate);
    }
    $self->{+HUB}->send($e);
}

sub build_event {
    my $self  = shift;
    my $event = shift;
    my %args  = @_;

    my $pkg = $LOADED{$event} || $self->_parse_event($event);

    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    $pkg->new(
        trace => $self->{+TRACE}->snapshot,
        %args,
    );
}

sub pass {
    my $self = shift;
    my ($name) = @_;

    my $e = bless(
        {
            trace => bless({%{$self->{+TRACE}}}, 'Test2::EventFacet::Trace'),
            name  => $name,
        },
        "Test2::Event::Pass"
    );

    $self->{+HUB}->send($e);
    return $e;
}

sub pass_and_release {
    my $self = shift;
    my ($name) = @_;

    my $e = bless(
        {
            trace => bless({%{$self->{+TRACE}}}, 'Test2::EventFacet::Trace'),
            name  => $name,
        },
        "Test2::Event::Pass"
    );

    $self->{+HUB}->send($e);
    $self->release;
    return 1;
}

sub fail {
    my $self = shift;
    my ($name, @diag) = @_;

    my $e = bless(
        {
            trace => bless({%{$self->{+TRACE}}}, 'Test2::EventFacet::Trace'),
            name  => $name,
        },
        "Test2::Event::Fail"
    );

    for my $msg (@diag) {
        if (ref($msg) eq 'Test2::EventFacet::Info::Table') {
            $e->add_info({tag => 'DIAG', debug => 1, $msg->info_args});
        }
        else {
            $e->add_info({tag => 'DIAG', debug => 1, details => $msg});
        }
    }

    $self->{+HUB}->send($e);
    return $e;
}

sub fail_and_release {
    my $self = shift;
    my ($name, @diag) = @_;

    my $e = bless(
        {
            trace => bless({%{$self->{+TRACE}}}, 'Test2::EventFacet::Trace'),
            name  => $name,
        },
        "Test2::Event::Fail"
    );

    for my $msg (@diag) {
        if (ref($msg) eq 'Test2::EventFacet::Info::Table') {
            $e->add_info({tag => 'DIAG', debug => 1, $msg->info_args});
        }
        else {
            $e->add_info({tag => 'DIAG', debug => 1, details => $msg});
        }
    }

    $self->{+HUB}->send($e);
    $self->release;
    return 0;
}

sub ok {
    my $self = shift;
    my ($pass, $name, $on_fail) = @_;

    my $hub = $self->{+HUB};

    my $e = bless {
        trace => bless( {%{$self->{+TRACE}}}, 'Test2::EventFacet::Trace'),
        pass  => $pass,
        name  => $name,
    }, 'Test2::Event::Ok';
    $e->init;

    $hub->send($e);
    return $e if $pass;

    $self->failure_diag($e);

    if ($on_fail && @$on_fail) {
        $self->diag($_) for @$on_fail;
    }

    return $e;
}

sub failure_diag {
    my $self = shift;
    my ($e) = @_;

    # Figure out the debug info, this is typically the file name and line
    # number, but can also be a custom message. If no trace object is provided
    # then we have nothing useful to display.
    my $name  = $e->name;
    my $trace = $e->trace;
    my $debug = $trace ? $trace->debug : "[No trace info available]";

    # Create the initial diagnostics. If the test has a name we put the debug
    # info on a second line, this behavior is inherited from Test::Builder.
    my $msg = defined($name)
        ? qq[Failed test '$name'\n$debug.\n]
        : qq[Failed test $debug.\n];

    $self->diag($msg);
}

sub skip {
    my $self = shift;
    my ($name, $reason, @extra) = @_;
    $self->send_event(
        'Skip',
        name => $name,
        reason => $reason,
        pass => 1,
        @extra,
    );
}

sub note {
    my $self = shift;
    my ($message) = @_;
    $self->send_event('Note', message => $message);
}

sub diag {
    my $self = shift;
    my ($message) = @_;
    my $hub = $self->{+HUB};
    $self->send_event(
        'Diag',
        message => $message,
    );
}

sub plan {
    my ($self, $max, $directive, $reason) = @_;
    $self->send_event('Plan', max => $max, directive => $directive, reason => $reason);
}

sub bail {
    my ($self, $reason) = @_;
    $self->send_event('Bail', reason => $reason);
}

sub _parse_event {
    my $self = shift;
    my $event = shift;

    my $pkg;
    if ($event =~ m/^\+(.*)/) {
        $pkg = $1;
    }
    else {
        $pkg = "Test2::Event::$event";
    }

    unless ($LOADED{$pkg}) {
        my $file = pkg_to_file($pkg);
        my ($ok, $err) = try { require $file };
        $self->throw("Could not load event module '$pkg': $err")
            unless $ok;

        $LOADED{$pkg} = $pkg;
    }

    confess "'$pkg' is not a subclass of 'Test2::Event'"
        unless $pkg->isa('Test2::Event');

    $LOADED{$event} = $pkg;

    return $pkg;
}

1;

__END__

#line 1019
