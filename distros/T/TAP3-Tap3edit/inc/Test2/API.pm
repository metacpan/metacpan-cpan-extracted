#line 1
package Test2::API;
use strict;
use warnings;

use Test2::Util qw/USE_THREADS/;

BEGIN {
    $ENV{TEST_ACTIVE} ||= 1;
    $ENV{TEST2_ACTIVE} = 1;
}

our $VERSION = '1.302175';


my $INST;
my $ENDING = 0;
sub test2_unset_is_end { $ENDING = 0 }
sub test2_get_is_end { $ENDING }

sub test2_set_is_end {
    my $before = $ENDING;
    ($ENDING) = @_ ? @_ : (1);

    # Only send the event in a transition from false to true
    return if $before;
    return unless $ENDING;

    return unless $INST;
    my $stack = $INST->stack or return;
    my $root = $stack->root or return;

    return unless $root->count;

    return unless $$ == $INST->pid;
    return unless get_tid() == $INST->tid;

    my $trace = Test2::EventFacet::Trace->new(
        frame  => [__PACKAGE__, __FILE__, __LINE__, __PACKAGE__ . '::test2_set_is_end'],
    );
    my $ctx = Test2::API::Context->new(
        trace => $trace,
        hub   => $root,
    );

    $ctx->send_ev2(control => { phase => 'END', details => 'Transition to END phase' });

    1;
}

use Test2::API::Instance(\$INST);

# Set the exit status
END {
    test2_set_is_end(); # See gh #16
    $INST->set_exit();
}

sub CLONE {
    my $init = test2_init_done();
    my $load = test2_load_done();

    return if $init && $load;

    require Carp;
    Carp::croak "Test2 must be fully loaded before you start a new thread!\n";
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

use Test2::EventFacet::Trace();
use Test2::Util::Trace(); # Legacy

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

use Carp qw/carp croak confess/;
use Scalar::Util qw/blessed weaken/;
use Test2::Util qw/get_tid clone_io pkg_to_file gen_uid/;

our @EXPORT_OK = qw{
    context release
    context_do
    no_context
    intercept intercept_deep
    run_subtest

    test2_init_done
    test2_load_done
    test2_load
    test2_start_preload
    test2_stop_preload
    test2_in_preload
    test2_is_testing_done

    test2_set_is_end
    test2_unset_is_end
    test2_get_is_end

    test2_pid
    test2_tid
    test2_stack
    test2_no_wait
    test2_ipc_wait_enable
    test2_ipc_wait_disable
    test2_ipc_wait_enabled

    test2_add_uuid_via

    test2_add_callback_testing_done

    test2_add_callback_context_aquire
    test2_add_callback_context_acquire
    test2_add_callback_context_init
    test2_add_callback_context_release
    test2_add_callback_exit
    test2_add_callback_post_load
    test2_add_callback_pre_subtest
    test2_list_context_aquire_callbacks
    test2_list_context_acquire_callbacks
    test2_list_context_init_callbacks
    test2_list_context_release_callbacks
    test2_list_exit_callbacks
    test2_list_post_load_callbacks
    test2_list_pre_subtest_callbacks

    test2_ipc
    test2_has_ipc
    test2_ipc_disable
    test2_ipc_disabled
    test2_ipc_drivers
    test2_ipc_add_driver
    test2_ipc_polling
    test2_ipc_disable_polling
    test2_ipc_enable_polling
    test2_ipc_get_pending
    test2_ipc_set_pending
    test2_ipc_get_timeout
    test2_ipc_set_timeout

    test2_formatter
    test2_formatters
    test2_formatter_add
    test2_formatter_set

    test2_stdout
    test2_stderr
    test2_reset_io
};
BEGIN { require Exporter; our @ISA = qw(Exporter) }

my $STACK       = $INST->stack;
my $CONTEXTS    = $INST->contexts;
my $INIT_CBS    = $INST->context_init_callbacks;
my $ACQUIRE_CBS = $INST->context_acquire_callbacks;

my $STDOUT = clone_io(\*STDOUT);
my $STDERR = clone_io(\*STDERR);
sub test2_stdout { $STDOUT ||= clone_io(\*STDOUT) }
sub test2_stderr { $STDERR ||= clone_io(\*STDERR) }

sub test2_post_preload_reset {
    test2_reset_io();
    $INST->post_preload_reset;
}

sub test2_reset_io {
    $STDOUT = clone_io(\*STDOUT);
    $STDERR = clone_io(\*STDERR);
}

sub test2_init_done { $INST->finalized }
sub test2_load_done { $INST->loaded }

sub test2_load          { $INST->load }
sub test2_start_preload { $ENV{T2_IN_PRELOAD} = 1; $INST->start_preload }
sub test2_stop_preload  { $ENV{T2_IN_PRELOAD} = 0; $INST->stop_preload }
sub test2_in_preload    { $INST->preload }

sub test2_pid              { $INST->pid }
sub test2_tid              { $INST->tid }
sub test2_stack            { $INST->stack }
sub test2_ipc_wait_enable  { $INST->set_no_wait(0) }
sub test2_ipc_wait_disable { $INST->set_no_wait(1) }
sub test2_ipc_wait_enabled { !$INST->no_wait }

sub test2_is_testing_done {
    # No instance? VERY DONE!
    return 1 unless $INST;

    # No stack? tests must be done, it is created pretty early
    my $stack = $INST->stack or return 1;

    # Nothing on the stack, no root hub yet, likely have not started testing
    return 0 unless @$stack;

    # Stack has a slot for the root hub (see above) but it is undefined, likely
    # garbage collected, test is done
    my $root_hub = $stack->[0] or return 1;

    # If the root hub is ended than testing is done.
    return 1 if $root_hub->ended;

    # Looks like we are still testing!
    return 0;
}

sub test2_no_wait {
    $INST->set_no_wait(@_) if @_;
    $INST->no_wait;
}

sub test2_add_callback_testing_done {
    my $cb = shift;

    test2_add_callback_post_load(sub {
        my $stack = test2_stack();
        $stack->top; # Insure we have a hub
        my ($hub) = Test2::API::test2_stack->all;

        $hub->set_active(1);

        $hub->follow_up($cb);
    });

    return;
}

sub test2_add_callback_context_acquire   { $INST->add_context_acquire_callback(@_) }
sub test2_add_callback_context_aquire    { $INST->add_context_acquire_callback(@_) }
sub test2_add_callback_context_init      { $INST->add_context_init_callback(@_) }
sub test2_add_callback_context_release   { $INST->add_context_release_callback(@_) }
sub test2_add_callback_exit              { $INST->add_exit_callback(@_) }
sub test2_add_callback_post_load         { $INST->add_post_load_callback(@_) }
sub test2_add_callback_pre_subtest       { $INST->add_pre_subtest_callback(@_) }
sub test2_list_context_aquire_callbacks  { @{$INST->context_acquire_callbacks} }
sub test2_list_context_acquire_callbacks { @{$INST->context_acquire_callbacks} }
sub test2_list_context_init_callbacks    { @{$INST->context_init_callbacks} }
sub test2_list_context_release_callbacks { @{$INST->context_release_callbacks} }
sub test2_list_exit_callbacks            { @{$INST->exit_callbacks} }
sub test2_list_post_load_callbacks       { @{$INST->post_load_callbacks} }
sub test2_list_pre_subtest_callbacks     { @{$INST->pre_subtest_callbacks} }

sub test2_add_uuid_via {
    $INST->set_add_uuid_via(@_) if @_;
    $INST->add_uuid_via();
}

sub test2_ipc                 { $INST->ipc }
sub test2_has_ipc             { $INST->has_ipc }
sub test2_ipc_disable         { $INST->ipc_disable }
sub test2_ipc_disabled        { $INST->ipc_disabled }
sub test2_ipc_add_driver      { $INST->add_ipc_driver(@_) }
sub test2_ipc_drivers         { @{$INST->ipc_drivers} }
sub test2_ipc_polling         { $INST->ipc_polling }
sub test2_ipc_enable_polling  { $INST->enable_ipc_polling }
sub test2_ipc_disable_polling { $INST->disable_ipc_polling }
sub test2_ipc_get_pending     { $INST->get_ipc_pending }
sub test2_ipc_set_pending     { $INST->set_ipc_pending(@_) }
sub test2_ipc_set_timeout     { $INST->set_ipc_timeout(@_) }
sub test2_ipc_get_timeout     { $INST->ipc_timeout() }
sub test2_ipc_enable_shm      { 0 }

sub test2_formatter     {
    if ($ENV{T2_FORMATTER} && $ENV{T2_FORMATTER} =~ m/^(\+)?(.*)$/) {
        my $formatter = $1 ? $2 : "Test2::Formatter::$2";
        my $file = pkg_to_file($formatter);
        require $file;
        return $formatter;
    }

    return $INST->formatter;
}

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
sub _add_uuid_via_ref              { \($INST->{Test2::API::Instance::ADD_UUID_VIA()}) }

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

my $UUID_VIA = _add_uuid_via_ref();
sub context {
    # We need to grab these before anything else to ensure they are not
    # changed.
    my ($errno, $eval_error, $child_error, $extended_error) = (0 + $!, $@, $?, $^E);

    my %params = (level => 0, wrapped => 0, @_);

    # If something is getting a context then the sync system needs to be
    # considered loaded...
    $INST->load unless $INST->{loaded};

    croak "context() called, but return value is ignored"
        unless defined wantarray;

    my $stack   = $params{stack} || $STACK;
    my $hub     = $params{hub}   || (@$stack ? $stack->[-1] : $stack->top);

    # Catch an edge case where we try to get context after the root hub has
    # been garbage collected resulting in a stack that has a single undef
    # hub
    if (!$hub && !exists($params{hub}) && @$stack) {
        my $msg = Carp::longmess("Attempt to get Test2 context after testing has completed (did you attempt a testing event after done_testing?)");

        # The error message is usually masked by the global destruction, so we have to print to STDER
        print STDERR $msg;

        # Make sure this is a failure, we are probably already in END, so set $? to change the exit code
        $? = 1;

        # Now we actually die to interrupt the program flow and avoid undefined his warnings
        die $msg;
    }

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
    ($!, $@, $?, $^E) = ($errno, $eval_error, $child_error, $extended_error) and return bless(
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
            frame  => [$pkg, $file, $line, $sub],
            pid    => $$,
            tid    => get_tid(),
            cid    => gen_uid(),
            hid    => $hid,
            nested => $hub->{nested},
            buffered => $hub->{buffered},

            $$UUID_VIA ? (
                huuid => $hub->{uuid},
                uuid  => ${$UUID_VIA}->('context'),
            ) : (),
        },
        'Test2::EventFacet::Trace'
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

    ($!, $@, $?, $^E) = ($errno, $eval_error, $child_error, $extended_error);

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

    # Older versions of Carp do not export longmess() function, so it needs to be called with package name
    my $mess = Carp::longmess();

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

    my $events = _intercept($code, deep => 0);

    $ctx->release;

    return $events;
}

sub intercept_deep(&) {
    my $code = shift;
    my $ctx = context();

    my $events = _intercept($code, deep => 1);

    $ctx->release;

    return $events;
}

sub _intercept {
    my $code = shift;
    my %params = @_;
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
    $hub->listen(sub { push @events => $_[1] }, inherit => $params{deep});

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

    $_->($name,$code,@args)
        for Test2::API::test2_list_pre_subtest_callbacks();

    $params = {buffered => $params} unless ref $params;
    my $inherit_trace = delete $params->{inherit_trace};

    my $ctx = context();

    my $parent = $ctx->hub;

    # If a parent is buffered then the child must be as well.
    my $buffered = $params->{buffered} || $parent->{buffered};

    $ctx->note($name) unless $buffered;

    my $stack = $ctx->stack || $STACK;
    my $hub = $stack->new_hub(
        class => 'Test2::Hub::Subtest',
        %$params,
        buffered => $buffered,
    );

    my @events;
    $hub->listen(sub { push @events => $_[1] });

    if ($buffered) {
        if (my $format = $hub->format) {
            my $hide = $format->can('hide_buffered') ? $format->hide_buffered : 1;
            $hub->format(undef) if $hide;
        }
    }

    if ($inherit_trace) {
        my $orig = $code;
        $code = sub {
            my $base_trace = $ctx->trace;
            my $trace = $base_trace->snapshot(nested => 1 + $base_trace->nested);
            my $st_ctx = Test2::API::Context->new(
                trace  => $trace,
                hub    => $hub,
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

    if ($params->{no_fork}) {
        if ($$ != $ctx->trace->pid) {
            warn $ok ? "Forked inside subtest, but subtest never finished!\n" : $err;
            exit 255;
        }

        if (get_tid() != $ctx->trace->tid) {
            warn $ok ? "Started new thread inside subtest, but thread never finished!\n" : $err;
            exit 255;
        }
    }
    elsif (!$parent->is_local && !$parent->ipc) {
        warn $ok ? "A new process or thread was started inside subtest, but IPC is not enabled!\n" : $err;
        exit 255;
    }

    $stack->pop($hub);

    my $trace = $ctx->trace;

    my $bailed = $hub->bailed_out;

    if (!$finished) {
        if ($bailed && !$buffered) {
            $ctx->bail($bailed->reason);
        }
        elsif ($bailed && $buffered) {
            $ok = 1;
        }
        else {
            my $code = $hub->exit_code;
            $ok = !$code;
            $err = "Subtest ended with exit code $code" if $code;
        }
    }

    $hub->finalize($trace->snapshot(huuid => $hub->uuid, hid => $hub->hid, nested => $hub->nested, buffered => $buffered), 1)
        if $ok
        && !$hub->no_ending
        && !$hub->ended;

    my $pass = $ok && $hub->is_passing;
    my $e = $ctx->build_event(
        'Subtest',
        pass         => $pass,
        name         => $name,
        subtest_id   => $hub->id,
        subtest_uuid => $hub->uuid,
        buffered     => $buffered,
        subevents    => \@events,
    );

    my $plan_ok = $hub->check_plan;

    $ctx->hub->send($e);

    $ctx->failure_diag($e) unless $e->pass;

    $ctx->diag("Caught exception in subtest: $err") unless $ok;

    $ctx->diag("Bad subtest plan, expected " . $hub->plan . " but ran " . $hub->count)
        if defined($plan_ok) && !$plan_ok;

    $ctx->bail($bailed->reason) if $bailed && $buffered;

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

#line 1689
