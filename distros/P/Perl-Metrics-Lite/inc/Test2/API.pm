#line 1
package Test2::API;
use strict;
use warnings;

BEGIN {
    $ENV{TEST_ACTIVE} ||= 1;
    $ENV{TEST2_ACTIVE} = 1;
}

our $VERSION = '1.302073';


my $INST;
my $ENDING = 0;
sub test2_set_is_end { ($ENDING) = @_ ? @_ : (1) }
sub test2_get_is_end { $ENDING }

use Test2::API::Instance(\$INST);
# Set the exit status
END {
    test2_set_is_end(); # See gh #16
    $INST->set_exit();
}

# See gh #16
{
    no warnings;
    INIT { eval 'END { test2_set_is_end() }; 1' or die $@ }
}

BEGIN {
    no warnings 'once';
    if($] ge '5.014' || $ENV{T2_CHECK_DEPTH} || $Test2::API::DO_DEPTH_CHECK) {
        *DO_DEPTH_CHECK = sub() { 1 };
    }
    else {
        *DO_DEPTH_CHECK = sub() { 0 };
    }
}

use Test2::Util::Trace();

use Test2::Hub::Subtest();
use Test2::Hub::Interceptor();
use Test2::Hub::Interceptor::Terminator();

use Test2::Event::Ok();
use Test2::Event::Diag();
use Test2::Event::Note();
use Test2::Event::Plan();
use Test2::Event::Bail();
use Test2::Event::Exception();
use Test2::Event::Waiting();
use Test2::Event::Skip();
use Test2::Event::Subtest();

use Carp qw/carp croak confess longmess/;
use Scalar::Util qw/blessed weaken/;
use Test2::Util qw/get_tid/;

our @EXPORT_OK = qw{
    context release
    context_do
    no_context
    intercept
    run_subtest

    test2_init_done
    test2_load_done

    test2_set_is_end
    test2_get_is_end

    test2_pid
    test2_tid
    test2_stack
    test2_no_wait

    test2_add_callback_context_aquire
    test2_add_callback_context_acquire
    test2_add_callback_context_init
    test2_add_callback_context_release
    test2_add_callback_exit
    test2_add_callback_post_load
    test2_list_context_aquire_callbacks
    test2_list_context_acquire_callbacks
    test2_list_context_init_callbacks
    test2_list_context_release_callbacks
    test2_list_exit_callbacks
    test2_list_post_load_callbacks

    test2_ipc
    test2_ipc_drivers
    test2_ipc_add_driver
    test2_ipc_polling
    test2_ipc_disable_polling
    test2_ipc_enable_polling
    test2_ipc_get_pending
    test2_ipc_set_pending
    test2_ipc_enable_shm

    test2_formatter
    test2_formatters
    test2_formatter_add
    test2_formatter_set
};
BEGIN { require Exporter; our @ISA = qw(Exporter) }

my $STACK       = $INST->stack;
my $CONTEXTS    = $INST->contexts;
my $INIT_CBS    = $INST->context_init_callbacks;
my $ACQUIRE_CBS = $INST->context_acquire_callbacks;

sub test2_init_done { $INST->finalized }
sub test2_load_done { $INST->loaded }

sub test2_pid     { $INST->pid }
sub test2_tid     { $INST->tid }
sub test2_stack   { $INST->stack }
sub test2_no_wait {
    $INST->set_no_wait(@_) if @_;
    $INST->no_wait;
}

sub test2_add_callback_context_acquire   { $INST->add_context_acquire_callback(@_) }
sub test2_add_callback_context_aquire    { $INST->add_context_acquire_callback(@_) }
sub test2_add_callback_context_init      { $INST->add_context_init_callback(@_) }
sub test2_add_callback_context_release   { $INST->add_context_release_callback(@_) }
sub test2_add_callback_exit              { $INST->add_exit_callback(@_) }
sub test2_add_callback_post_load         { $INST->add_post_load_callback(@_) }
sub test2_list_context_aquire_callbacks  { @{$INST->context_acquire_callbacks} }
sub test2_list_context_acquire_callbacks { @{$INST->context_acquire_callbacks} }
sub test2_list_context_init_callbacks    { @{$INST->context_init_callbacks} }
sub test2_list_context_release_callbacks { @{$INST->context_release_callbacks} }
sub test2_list_exit_callbacks            { @{$INST->exit_callbacks} }
sub test2_list_post_load_callbacks       { @{$INST->post_load_callbacks} }

sub test2_ipc                 { $INST->ipc }
sub test2_ipc_add_driver      { $INST->add_ipc_driver(@_) }
sub test2_ipc_drivers         { @{$INST->ipc_drivers} }
sub test2_ipc_polling         { $INST->ipc_polling }
sub test2_ipc_enable_polling  { $INST->enable_ipc_polling }
sub test2_ipc_disable_polling { $INST->disable_ipc_polling }
sub test2_ipc_get_pending     { $INST->get_ipc_pending }
sub test2_ipc_set_pending     { $INST->set_ipc_pending(@_) }
sub test2_ipc_enable_shm      { $INST->ipc_enable_shm }

sub test2_formatter     { $INST->formatter }
sub test2_formatters    { @{$INST->formatters} }
sub test2_formatter_add { $INST->add_formatter(@_) }
sub test2_formatter_set {
    my ($formatter) = @_;
    croak "No formatter specified" unless $formatter;
    croak "Global Formatter already set" if $INST->formatter_set;
    $INST->set_formatter($formatter);
}

# Private, for use in Test2::API::Context
sub _contexts_ref                  { $INST->contexts }
sub _context_acquire_callbacks_ref { $INST->context_acquire_callbacks }
sub _context_init_callbacks_ref    { $INST->context_init_callbacks }
sub _context_release_callbacks_ref { $INST->context_release_callbacks }

# Private, for use in Test2::IPC
sub _set_ipc { $INST->set_ipc(@_) }

sub context_do(&;@) {
    my $code = shift;
    my @args = @_;

    my $ctx = context(level => 1);

    my $want = wantarray;

    my @out;
    my $ok = eval {
        $want          ? @out    = $code->($ctx, @args) :
        defined($want) ? $out[0] = $code->($ctx, @args) :
                                   $code->($ctx, @args) ;
        1;
    };
    my $err = $@;

    $ctx->release;

    die $err unless $ok;

    return @out    if $want;
    return $out[0] if defined $want;
    return;
}

sub no_context(&;$) {
    my ($code, $hid) = @_;
    $hid ||= $STACK->top->hid;

    my $ctx = $CONTEXTS->{$hid};
    delete $CONTEXTS->{$hid};
    my $ok = eval { $code->(); 1 };
    my $err = $@;

    $CONTEXTS->{$hid} = $ctx;
    weaken($CONTEXTS->{$hid});

    die $err unless $ok;

    return;
};

sub context {
    # We need to grab these before anything else to ensure they are not
    # changed.
    my ($errno, $eval_error, $child_error) = (0 + $!, $@, $?);

    my %params = (level => 0, wrapped => 0, @_);

    # If something is getting a context then the sync system needs to be
    # considered loaded...
    $INST->load unless $INST->{loaded};

    croak "context() called, but return value is ignored"
        unless defined wantarray;

    my $stack   = $params{stack} || $STACK;
    my $hub     = $params{hub}   || (@$stack ? $stack->[-1] : $stack->top);
    my $hid     = $hub->{hid};
    my $current = $CONTEXTS->{$hid};

    $_->(\%params) for @$ACQUIRE_CBS;
    map $_->(\%params), @{$hub->{_context_acquire}} if $hub->{_context_acquire};

    # This is for https://github.com/Test-More/test-more/issues/16
    # and https://rt.perl.org/Public/Bug/Display.html?id=127774
    my $phase = ${^GLOBAL_PHASE} || 'NA';
    my $end_phase = $ENDING || $phase eq 'END' || $phase eq 'DESTRUCT';

    my $level = 1 + $params{level};
    my ($pkg, $file, $line, $sub) = $end_phase ? caller(0) : caller($level);
    unless ($pkg || $end_phase) {
        confess "Could not find context at depth $level" unless $params{fudge};
        ($pkg, $file, $line, $sub) = caller(--$level) while ($level >= 0 && !$pkg);
    }

    my $depth = $level;
    $depth++ while DO_DEPTH_CHECK && !$end_phase && (!$current || $depth <= $current->{_depth} + $params{wrapped}) && caller($depth + 1);
    $depth -= $params{wrapped};
    my $depth_ok = !DO_DEPTH_CHECK || $end_phase || !$current || $current->{_depth} < $depth;

    if ($current && $params{on_release} && $depth_ok) {
        $current->{_on_release} ||= [];
        push @{$current->{_on_release}} => $params{on_release};
    }

    # I know this is ugly....
    ($!, $@, $?) = ($errno, $eval_error, $child_error) and return bless(
        {
            %$current,
            _is_canon   => undef,
            errno       => $errno,
            eval_error  => $eval_error,
            child_error => $child_error,
            _is_spawn   => [$pkg, $file, $line, $sub],
        },
        'Test2::API::Context'
    ) if $current && $depth_ok;

    # Handle error condition of bad level
    if ($current) {
        unless (${$current->{_aborted}}) {
            _canon_error($current, [$pkg, $file, $line, $sub, $depth])
                unless $current->{_is_canon};

            _depth_error($current, [$pkg, $file, $line, $sub, $depth])
                unless $depth_ok;
        }

        $current->release if $current->{_is_canon};

        delete $CONTEXTS->{$hid};
    }

    # Directly bless the object here, calling new is a noticeable performance
    # hit with how often this needs to be called.
    my $trace = bless(
        {
            frame => [$pkg, $file, $line, $sub],
            pid   => $$,
            tid   => get_tid(),
        },
        'Test2::Util::Trace'
    );

    # Directly bless the object here, calling new is a noticeable performance
    # hit with how often this needs to be called.
    my $aborted = 0;
    $current = bless(
        {
            _aborted     => \$aborted,
            stack        => $stack,
            hub          => $hub,
            trace        => $trace,
            _is_canon    => 1,
            _depth       => $depth,
            errno        => $errno,
            eval_error   => $eval_error,
            child_error  => $child_error,
            $params{on_release} ? (_on_release => [$params{on_release}]) : (),
        },
        'Test2::API::Context'
    );

    $CONTEXTS->{$hid} = $current;
    weaken($CONTEXTS->{$hid});

    $_->($current) for @$INIT_CBS;
    map $_->($current), @{$hub->{_context_init}} if $hub->{_context_init};

    $params{on_init}->($current) if $params{on_init};

    ($!, $@, $?) = ($errno, $eval_error, $child_error);

    return $current;
}

sub _depth_error {
    _existing_error(@_, <<"    EOT");
context() was called to retrieve an existing context, however the existing
context was created in a stack frame at the same, or deeper level. This usually
means that a tool failed to release the context when it was finished.
    EOT
}

sub _canon_error {
    _existing_error(@_, <<"    EOT");
context() was called to retrieve an existing context, however the existing
context has an invalid internal state (!_canon_count). This should not normally
happen unless something is mucking about with internals...
    EOT
}

sub _existing_error {
    my ($ctx, $details, $msg) = @_;
    my ($pkg, $file, $line, $sub, $depth) = @$details;

    my $oldframe = $ctx->{trace}->frame;
    my $olddepth = $ctx->{_depth};

    my $mess = longmess();

    warn <<"    EOT";
$msg
Old context details:
   File: $oldframe->[1]
   Line: $oldframe->[2]
   Tool: $oldframe->[3]
  Depth: $olddepth

New context details:
   File: $file
   Line: $line
   Tool: $sub
  Depth: $depth

Trace: $mess

Removing the old context and creating a new one...
    EOT
}

sub release($;$) {
    $_[0]->release;
    return $_[1];
}

sub intercept(&) {
    my $code = shift;

    my $ctx = context();

    my $ipc;
    if (my $global_ipc = test2_ipc()) {
        my $driver = blessed($global_ipc);
        $ipc = $driver->new;
    }

    my $hub = Test2::Hub::Interceptor->new(
        ipc => $ipc,
        no_ending => 1,
    );

    my @events;
    $hub->listen(sub { push @events => $_[1] });

    $ctx->stack->top; # Make sure there is a top hub before we begin.
    $ctx->stack->push($hub);

    my ($ok, $err) = (1, undef);
    T2_SUBTEST_WRAPPER: {
        # Do not use 'try' cause it localizes __DIE__
        $ok = eval { $code->(hub => $hub, context => $ctx->snapshot); 1 };
        $err = $@;

        # They might have done 'BEGIN { skip_all => "whatever" }'
        if (!$ok && $err =~ m/Label not found for "last T2_SUBTEST_WRAPPER"/ || (blessed($err) && $err->isa('Test2::Hub::Interceptor::Terminator'))) {
            $ok  = 1;
            $err = undef;
        }
    }

    $hub->cull;
    $ctx->stack->pop($hub);

    my $trace = $ctx->trace;
    $ctx->release;

    die $err unless $ok;

    $hub->finalize($trace, 1)
        if $ok
        && !$hub->no_ending
        && !$hub->ended;

    return \@events;
}

sub run_subtest {
    my ($name, $code, $params, @args) = @_;

    $params = {buffered => $params} unless ref $params;
    my $buffered      = delete $params->{buffered};
    my $inherit_trace = delete $params->{inherit_trace};

    my $ctx = context();

    $ctx->note($name) unless $buffered;

    my $parent = $ctx->hub;

    my $stack = $ctx->stack || $STACK;
    my $hub = $stack->new_hub(
        class => 'Test2::Hub::Subtest',
        %$params,
    );

    my @events;
    $hub->set_nested( $parent->isa('Test2::Hub::Subtest') ? $parent->nested + 1 : 1 );
    $hub->listen(sub { push @events => $_[1] });

    if ($buffered) {
        if (my $format = $hub->format) {
            my $hide = $format->can('hide_buffered') ? $format->hide_buffered : 1;
            $hub->format(undef) if $hide;
        }
    }
    elsif (! $parent->format) {
        # If our parent has no format that means we're in a buffered subtest
        # and now we're trying to run a streaming subtest. There's really no
        # way for that to work, so we need to force the use of a buffered
        # subtest here as
        # well. https://github.com/Test-More/test-more/issues/721
        $buffered = 1;
    }

    if ($inherit_trace) {
        my $orig = $code;
        $code = sub {
            my $st_ctx = Test2::API::Context->new(
                trace => $ctx->trace,
                hub   => $hub,
            );
            $st_ctx->do_in_context($orig, @args);
        };
    }

    my ($ok, $err, $finished);
    T2_SUBTEST_WRAPPER: {
        # Do not use 'try' cause it localizes __DIE__
        $ok = eval { $code->(@args); 1 };
        $err = $@;

        # They might have done 'BEGIN { skip_all => "whatever" }'
        if (!$ok && $err =~ m/Label not found for "last T2_SUBTEST_WRAPPER"/ || (blessed($err) && blessed($err) eq 'Test::Builder::Exception')) {
            $ok  = undef;
            $err = undef;
        }
        else {
            $finished = 1;
        }
    }
    $stack->pop($hub);

    my $trace = $ctx->trace;

    if (!$finished) {
        if(my $bailed = $hub->bailed_out) {
            $ctx->bail($bailed->reason);
        }
        my $code = $hub->exit_code;
        $ok = !$code;
        $err = "Subtest ended with exit code $code" if $code;
    }

    $hub->finalize($trace, 1)
        if $ok
        && !$hub->no_ending
        && !$hub->ended;

    my $pass = $ok && $hub->is_passing;
    my $e = $ctx->build_event(
        'Subtest',
        pass       => $pass,
        name       => $name,
        subtest_id => $hub->id,
        buffered   => $buffered,
        subevents  => \@events,
    );

    my $plan_ok = $hub->check_plan;

    $ctx->hub->send($e);

    $ctx->failure_diag($e) unless $e->pass;

    $ctx->diag("Caught exception in subtest: $err") unless $ok;

    $ctx->diag("Bad subtest plan, expected " . $hub->plan . " but ran " . $hub->count)
        if defined($plan_ok) && !$plan_ok;

    $ctx->release;
    return $pass;
}

# There is a use-cycle between API and API/Context. Context needs to use some
# API functions as the package is compiling. Test2::API::context() needs
# Test2::API::Context to be loaded, but we cannot 'require' the module there as
# it causes a very noticeable performance impact with how often context() is
# called.
require Test2::API::Context;

1;

__END__

#line 1310
