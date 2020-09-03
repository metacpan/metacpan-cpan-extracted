package ScriptX;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-09-03'; # DATE
our $DIST = 'ScriptX'; # DIST
our $VERSION = '0.000001'; # VERSION

# IFUNBUILT
# use strict;
# use warnings;
# END IFUNBUILT
use Log::ger;

our %Plugins;
our %Handlers;

my $Stash = {
    plugins => \%Plugins,
    handlers => \%Handlers,
};

sub run_event {
    my %args = @_;

    my $name = $args{name};
    log_trace "[scriptx] -> run_event(%s)", \%args;
    defined $name or die "Please supply 'name'";
    $Handlers{$name} ||= [];

    my $before_name = "before_$name";
    $Handlers{$before_name} ||= [];

    my $after_name = "after_$name";
    $Handlers{$after_name} ||= [];

    my $req_handler                          = $args{req_handler};                          $req_handler                          = 0 unless defined $req_handler;
    my $run_all_handlers                     = $args{run_all_handlers};                     $run_all_handlers                     = 1 unless defined $run_all_handlers;
    my $allow_before_handler_to_cancel_event = $args{allow_before_handler_to_cancel_event}; $allow_before_handler_to_cancel_event = 1 unless defined $allow_before_handler_to_cancel_event;
    my $allow_before_handler_to_skip_rest    = $args{allow_before_handler_to_skip_rest};    $allow_before_handler_to_skip_rest    = 1 unless defined $allow_before_handler_to_skip_rest;
    my $allow_handler_to_skip_rest           = $args{allow_handler_to_skip_rest};           $allow_handler_to_skip_rest           = 1 unless defined $allow_handler_to_skip_rest;
    my $allow_handler_to_repeat_event        = $args{allow_handler_to_repeat_event};        $allow_handler_to_repeat_event        = 1 unless defined $allow_handler_to_repeat_event;
    my $allow_after_handler_to_repeat_event  = $args{allow_after_handler_to_repeat_event};  $allow_after_handler_to_repeat_event  = 1 unless defined $allow_after_handler_to_repeat_event;
    my $allow_after_handler_to_skip_rest     = $args{allow_after_handler_to_skip_rest};     $allow_after_handler_to_skip_rest     = 1 unless defined $allow_after_handler_to_skip_rest;
    my $stop_after_first_handler_failure     = $args{stop_after_first_handler_failure};     $stop_after_first_handler_failure     = 1 unless defined $stop_after_first_handler_failure;

    my ($res, $is_success);

  RUN_BEFORE_EVENT_HANDLERS:
    {
        last if $name =~ /\A(after|before)_/;
        local $Stash->{event} = $before_name;
        my $i = 0;
        for my $rec (@{ $Handlers{$before_name} }) {
            $i++;
            my ($label, $prio, $handler) = @$rec;
            log_trace "[scriptx] [event %s] [%d/%d] -> handler %s ...",
                $before_name, $i, scalar(@{ $Handlers{$before_name} }), $label;
            $res = $handler->($Stash);
            $is_success = $res->[0] =~ /\A[123]/;
            log_trace "[scriptx] [event %s] [%d/%d] <- handler %s: %s (%s)",
                $before_name, $i, scalar(@{ $Handlers{$before_name} }), $label,
                $res, $is_success ? "success" : "fail";
            if ($res->[0] == 601) {
                if ($allow_before_handler_to_cancel_event) {
                    log_trace "[scriptx] Cancelling event $name (status 601)";
                    goto RETURN;
                } else {
                    die "$before_name handler returns 601 when allow_before_handler_to_cancel_event is set to false";
                }
            }
            if ($res->[0] == 201) {
                if ($allow_before_handler_to_skip_rest) {
                    log_trace "[scriptx] Skipping the rest of the $before_name handlers (status 201)";
                    last RUN_BEFORE_EVENT_HANDLERS;
                } else {
                    log_trace "[scriptx] $before_name handler returns 201, but we ignore it because allow_before_handler_to_skip_rest is set to false";
                }
            }
        }
    }

  RUN_EVENT_HANDLERS:
    {
        local $Stash->{event} = $name;
        my $i = 0;
        $res = [304, "There is no handler for event $name"];
        $is_success = 1;
        if ($req_handler) {
            die "There is no handler for event $name"
                unless @{ $Handlers{$name} };
        }

        for my $rec (@{ $Handlers{$name} }) {
            $i++;
            my ($label, $prio, $handler) = @$rec;
            log_trace "[scriptx] [event %s] [%d/%d] -> handler %s ...",
                $name, $i, scalar(@{ $Handlers{$name} }), $label;
            $res = $handler->($Stash);
            $is_success = $res->[0] =~ /\A[123]/;
            log_trace "[scriptx] [event %s] [%d/%d] <- handler %s: %s (%s)",
                $name, $i, scalar(@{ $Handlers{$name} }), $label,
                $res, $is_success ? "success" : "fail";
            last RUN_EVENT_HANDLERS if $is_success && !$run_all_handlers;
            if ($res->[0] == 601) {
                die "$name handler is not allowed to return 601";
            }
            if ($res->[0] == 602) {
                if ($allow_handler_to_repeat_event) {
                    log_trace "[scriptx] Repeating event $name (handler returns 602)";
                    goto RUN_EVENT_HANDLERS;
                } else {
                    die "$name handler returns 602 when allow_handler_to_repeat_event is set to false";
                }
            }
            if ($res->[0] == 201) {
                if ($allow_handler_to_skip_rest) {
                    log_trace "[scriptx] Skipping the rest of the $name handlers (status 201)";
                    last RUN_EVENT_HANDLERS;
                } else {
                    log_trace "[scriptx] $name handler returns 201, but we ignore it because allow_handler_to_skip_rest is set to false";
                }
            }
            last RUN_EVENT_HANDLERS if !$is_success && $stop_after_first_handler_failure;
        }
    }

    if ($is_success && $args{on_success}) {
        log_trace "[scriptx] Running on_success ...";
        $args{on_success}->($Stash);
    } elsif (!$is_success && $args{on_failure}) {
        log_trace "[scriptx] Running on_failure ...";
        $args{on_failure}->($Stash);
    }

  RUN_AFTER_EVENT_HANDLERS:
    {
        last if $name =~ /\A(after|before)_/;
        local $Stash->{event} = $after_name;
        my $i = 0;
        for my $rec (@{ $Handlers{$after_name} }) {
            $i++;
            my ($label, $prio, $handler) = @$rec;
            log_trace "[scriptx] [event %s] [%d/%d] -> handler %s ...",
                $after_name, $i, scalar(@{ $Handlers{$after_name} }), $label;
            $res = $handler->($Stash);
            $is_success = $res->[0] =~ /\A[123]/;
            log_trace "[scriptx] [event %s] [%d/%d] <- handler %s: %s (%s)",
                $after_name, $i, scalar(@{ $Handlers{$after_name} }), $label,
                $res, $is_success ? "success" : "fail";
            if ($res->[0] == 602) {
                if ($allow_after_handler_to_repeat_event) {
                    log_trace "[scriptx] Repeating event $name (status 602)";
                    goto RUN_EVENT_HANDLERS;
                } else {
                    die "$after_name handler returns 602 when allow_after_handler_to_repeat_event it set to false";
                }
            }
            if ($res->[0] == 201) {
                if ($allow_after_handler_to_skip_rest) {
                    log_trace "[scriptx] Skipping the rest of the $after_name handlers (status 201)";
                    last RUN_AFTER_EVENT_HANDLERS;
                } else {
                    log_trace "[scriptx] $after_name handler returns 201, but we ignore it because allow_after_handler_to_skip_rest is set to false";
                }
            }
        }
    }

  RETURN:
    log_trace "[scriptx] <- run_event(name=%s)", $name;
    undef;
}

sub run {
    run_event(
        name => 'run',
    );
}

sub add_handler {
    my ($event, $label, $prio, $handler) = @_;

    # XXX check for known events?
    $Handlers{$event} ||= [];

    # keep sorted
    splice @{ $Handlers{$event} }, 0, scalar(@{ $Handlers{$event} }),
        (sort { $a->[1] <=> $b->[1] } @{ $Handlers{$event} }, [$label, $prio, $handler]);
}

sub activate_plugin {
    my ($plugin_name0, $args) = @_;

    my ($plugin_name, $wanted_event, $wanted_prio) =
        $plugin_name0 =~ /\A(\w+(?:::\w+)*)(?:\@(\w+)(?:\@(\d+))?)?\z/
        or die "Invalid plugin name syntax, please use Foo::Bar or ".
        "Foo::Bar\@event or Foo::Bar\@event\@prio\n";

    local $Stash->{plugin_name} = $plugin_name;
    local $Stash->{plugin_args} = $args;

    run_event(
        name => 'activate_plugin',
        on_success => sub {
            my $package = "ScriptX::$plugin_name";
            (my $package_pm = "$package.pm") =~ s!::!/!g;
            log_trace "[scriptx] Loading module $package ...";
            require $package_pm;
            my $obj = $package->new(%{ $args || {} });
            $obj->activate($wanted_event, $wanted_prio);
        },
        on_failure => sub {
            die "Cannot activate plugin $plugin_name";
        },
    );
}

sub _import {
    #log_trace "_import(%s)", \@_;
    while (@_) {
        my $plugin_name0 = shift;
        my $plugin_args = @_ && ref($_[0]) eq 'HASH' ? shift : {};
        activate_plugin($plugin_name0, $plugin_args);
    }
}

sub _unflatten_import {
    my ($env, $what) = @_;

    $what ||= "import";
    my @imports;
    my $plugin_name0;
    my @plugin_args;

    my @elems = ref $env eq 'ARRAY' ? @$env : split /,/, $env;
    while (@elems) {
        my $el = shift @elems;
        # dash prefix to disambiguate between plugin name and arguments, e.g.
        # '-PluginName,argname,argval,argname2,argval2,-Plugin2Name,...'
        if ($el =~ /\A-(\w+(?:::\w+)*(?:\@.+)?)\z/) {
            if (defined $plugin_name0) {
                push @imports, $plugin_name0;
                push @imports, {@plugin_args} if @plugin_args;
            }
            $plugin_name0 = $1;
            @plugin_args = ();
            if (!@elems) {
                push @imports, $1;
            }
        } else {
            die "Invalid syntax in $what, first element needs to be ".
                "a plugin name (e.g. -Foo), not '$el'"
                unless defined $plugin_name0;
                push @plugin_args, $el;
            if (!@elems) {
                push @imports, $plugin_name0;
                push @imports, {@plugin_args} if @plugin_args;
            }
        }
    }
    @imports;
}

my $read_env;
sub import {
    my $class = shift;

  READ_ENV:
    {
        last if $read_env;
      READ_SCRIPTX_IMPORT:
        {
            last unless defined $ENV{SCRIPTX_IMPORT};
            log_trace "[scriptx] Reading env variable SCRIPTX_IMPORT ...";
            _import(_unflatten_import($ENV{SCRIPTX_IMPORT}, "SCRIPTX_IMPORT"));
            $read_env++;
            last READ_ENV;
        }

      READ_SCRIPTX_IMPORT_JSON:
        {
            last unless defined $ENV{SCRIPTX_IMPORT_JSON};
            require JSON::PP;
            log_trace "[scriptx] Reading env variable SCRIPTX_IMPORT_JSON ...";
            my $imports = JSON::PP::decode_json($ENV{SCRIPTX_IMPORT_JSON});
            _import(@$imports);
            $read_env++;
            last READ_ENV;
        }
    }

    if (@_ && $_[0] =~ /\A-/) {
        # user that specify imports on command-line, e.g. using -MScriptX=...
        # can use the ENV syntax so she can specify plugin arguments more
        # easily: -MScriptX=-Run,command,foobar,-AnotherPlugin,...
        _import(_unflatten_import(\@_, "import arguments"));
    } else {
        _import(@_);
    }
}

1;
# ABSTRACT: A plugin-based script framework

__END__

=pod

=encoding UTF-8

=head1 NAME

ScriptX - A plugin-based script framework

=head1 VERSION

This document describes version 0.000001 of ScriptX (from Perl distribution ScriptX), released on 2020-09-03.

=head1 SYNOPSIS

In your script:

 use ScriptX Rinci => {func => 'MyApp::app'};
 ScriptX->run;

=head1 DESCRIPTION

B<EXPERIMENTAL, EARLY RELEASE.>

For now, see the included example scripts.

=head2 Glossary

=head3 Event

A named point in code when L<plugins|/Plugin> have a chance to do stuffs, by
registering a handler for it. In other frameworks, an event sometimes this is
called a hook.

=head3 Event handler

A coderef that will be called by ScriptX on an L<event|/Event>. The event
handler will be passed an argument C<$stash> (a hashref) which contains various
information (see L</Stash>). The event handler is expected to return an
enveloped result (see L<Rinci::function>).

=head3 Plugin

A Perl module under the C<ScriptX::> namespace that supplies additional
behavior/functionality. When you activate a plugin, the plugin registers
L<handler(s)|/"Event handler"> to one or more L<events|/Event>.

=head3 Priority

An attribute of event handler. A number between 0 and 100, where smaller
number means higher priority. Handlers for an event are executed in order of
descending priority (higher priority first, which means smaller number first).

=for Pod::Coverage ^(run)$

=head1 CLASS METHODS

=head2 run

Usage:

 ScriptX->run;

This is actually just a shortcut for running the C<run> event:

 run_event(name => 'run');

=head1 VARIABLES

=head2 %Handlers

This is where event handlers are registered. Keys are event names. Values are
arrayrefs containing list of handler records:

 [ [$label, $prio, $handler], ... ]

=head2 %Plugins

A hash of activated plugins. Keys are plugin names without the C<ScriptX::>
prefix (e.g. L<Exit|ScriptX::Exit>) and values are plugin instances.

=head1 STASH KEYS

=head2 event

The name of current event.

=head2 handlers

Reference to the L<%Handlers> package variable, for convenience.

=head2 plugins

Reference to the L<%Plugins> package variable, for convenience.

=head2 plugin_name

Set for C<activate_plugin> event.

=head2 plugin_args

Set for C<activate_plugin> event.

=head1 EVENT HANDLER RETURN STATUS CODES

The following are known event handler return status codes. They roughly follow
HTTP semantics.

=head2 201

This signifies success with exit ("OK, Skip Rest"), meaning the handler
instructs L</run_event>() to skip moving to the next handler for the event and
use this status as the status of the event.

=head2 204

This signifies declination ("Decline"), meaning the handler opts to not do
anything for the event. L</run_event>() will move to the next handler,
regardless of the value of L</run_all_handlers>.

=head2 Other 1xx, 2xx, 3xx

Including 200 ("OK"), these also signify success. When L</run_all_handlers> is
set to true, L</run_event>() will move to the next handler. When
C<run_all_handlers> is set to false, run_event will finish the execution of
handlers for the event and use the status as the status of the event.

=head2 4xx, 5xx

This signifies failure. When L</stop_after_first_handler_failure> is set to
true, L</run_event>() will use the status as the last status. Otherwise, it will
move to the next handler when L</run_all_handlers> is set to true.

=head2 601

This signifies event cancellation ("Cancel"), meaning the handler instructs
L</run_event>() to cancel the event.

=head2 602

This signifies repeating of event ("Repeat"), meaning the handler instructs
L</run_event>() to cancel the event.

=head1 FUNCTIONS

None exported by default, but they are exportable.

=head2 activate_plugin

Usage:

 activate_plugin($name [, \%args ]);

Examples:

 activate_plugin('CLI::Log');
 activate_plugin('Rinci', {func=>'MyPackage::myfunc'});

Load plugin named C<$name> (by loading Perl module C<ScriptX::$name>),
instantiate it with arguments %$args, then call the object method C<activate()>.

Note: there is a special plugin C<DisablePlugin|ScriptX::DisablePlugin> which
can block other plugins from being activated.

=head2 add_handler

Usage:

 add_handler($event, $label, $prio, $handler);

Add handler. Usually called by plugins to add handler to events of their
choosing.

=head2 run_event

Usage:

 run_event(%args);

Run an event by calling event handlers.

If the name of the event (hereby called C<$name>) does not match
/^(after|before)_/, first call the C<before_$name> event handlers. A handler for
C<before_$name> event can B<cancel> the C<$name> event by returning 601 status,
unless L</allow_before_handler_to_cancel_event> argument is set to false. When
the C<$name> event is cancelled, L</run_event>() ends prematurely: no handlers
for the C<$name> as well as C<after_$name> events are run, no C<on_success> and
C<on_failure> code will also be called.

Then the C<$name> event handlers are run. A handler for C<$name> event can skip
the rest of the handlers by returning status 201, unless
L</allow_handler_to_skip_rest> argument is set to false.

A handler for C<$name> event can also repeat the event by returning status 602,
unless L</allow_handler_to_repeat_event> is set to false. When an event is
repeated, the first C<$name> event handler is executed again. The
C<before_$name> handlers are not re-executed.

When the last C<$name> handler returns success (1xx, 2xx, 3xx status) then the
C<on_success> code is run; otherwise the C<on_failure> code is run.

After that, the C<after_$name> event handlers are run. Unless
L</allow_after_handler_to_repeat_event> is set to false, the handler for this
event can repeat the event by returning 602 status, in which case the routine
stops running the C<after_$name> handlers and starts running the C<$name>
handlers again. The handler which instructs repeat must be careful not to cause
an infinite loop.

Arguments:

=over

=item * name

Str. Required. Name of the event, for example: C<get_args>.

=item * req_handler

Bool. Optional, defaults to 0. When set to true, will die when there is no
handler for the event C<$name>.

=item * run_all_handlers

Bool. Optional, defaults to 1. When set to false, will stop calling event
handlers for the C<$name> event after the first successful handler (success is
defined as codes 1xx, 2xx, and 3xx). Otherwise, all handlers are run regardless
of success status.

=item * allow_before_handler_to_cancel_event

Bool. Optional, defaults to 1. When set to true, an event handler in the
C<before_$name> event can cancel the event by returning 601 status. When set to
false, will die whenever an event handler returns 601.

When the C<$name> event is called by the C<before_$name> event handler,

=item * allow_before_handler_to_skip_rest

Bool. Optional, defaults to 1. When set to true, an event handler can skip the
rest of the event handlers in the C<before_$name> event by returning 201 status.
When set to false, the next event handler will be called anyway even though an
event handler returns 201.

=item * allow_handler_to_repeat_event

Bool. Optional, defaults to 1. When set to true, an event handler in the
C<$name> event can repeat the event by returning 602 status. When set to false,
will die whenever an event handler returns 602.

=item * allow_handler_to_skip_rest

Bool. Optional, defaults to 1. When set to true, an event handler can skip the
rest of the event handlers in the C<$name> event by returning 201 status. When
set to false, the next event handler will be called anyway even though an event
handler returns 201.

=item * allow_after_handler_to_repeat_event

Bool. Optional, defaults to 1. When set to true, an event handler in the
C<after_$name> event can repeat the event by returning 602 status. When set to
false, will die whenever an event handler returns 602.

=item * allow_after_handler_to_skip_rest

Bool. Optional, defaults to 1. When set to true, an event handler can skip the
rest of the event handlers in the C<after_$name> event by returning 201 status.
When set to false, the next event handler will be called anyway even though an
event handler returns 201.

=item * stop_after_first_handler_failure

Bool. Optional, defaults to 1. When set to true, the first failure status
(4xx/5xx) from an event is used as the status of the event and the rest of the
handlers will be skipped. Otherwise, will ignore the failure status and move on
to the next handler.

=item * on_success

Coderef. Optional.

Will be executed after the last executed C<$name> handler returns 2xx code
(including 200, 201, 204).

=item * on_failure

Coderef. Optional.

Will be executed after the last executed C<$name> handler returns 4xx/5xx code.

=back

=head1 ENVIRONMENT

=head2 SCRIPTX_IMPORT

String. Additional import, will be added at the first import() before the usual
import arguments. Used to add plugins for a running script, e.g. to add
debugging plugins. The syntax is:

 -<PLUGIN_NAME0>,<arg1>,<argval1>,...,-<PLUGIN_NAME0>,...

For example, this:

 use ScriptX
     'CLI::Log',
     'Rinci::CLI::Debug::DumpStashAfterGetArgs',
     Exit => {after => 'after_get_args'};

should be written as:

 SCRIPTX_IMPORT=-CLI::Log,-Rinci::CLI::Debug::DumpStashAfterGetArgs,-Exit,after,after_get_args

If your script is:

 use ScriptX Rinci => {func=>'MyPackage::myfunc'};

then with the injection of the above environment, effectively it will become:

 use ScriptX
     'CLI::Log',
     'Rinci::CLI::Debug::DumpStashAfterGetArgs',
     Exit => {after => 'after_get_args'},
     Rinci => {func=>'MyPackage::myfunc'};

Note that PLUGIN_NAME0 is plugin name that can optionally be followed with
C<@EVENT> or C<@EVENT@PRIO>. For example: C<Debug::DumpStash@after_run@99> to
put the L<ScriptX::Debug::DumpStash|Debug::DumpStash> plugin handler in the
C<after_run> event at priority 99.

=head2 SCRIPTX_IMPORT_JSON

String (JSON-encoded array). This is an alternative to L</SCRIPTX_IMPORT> and
has a lower precedence (will not be evaluated when SCRIPTX_IMPORT is defined).
Useful if a plugin accept data structure instead of plain scalars.

Example:

 SCRIPTX_IMPORT_JSON='["CLI::Log", "Rinci::CLI::Debug::DumpStashAfterGetArgs", "Exit", {"after":"after_get_args"}, "Rinci", {"func":"MyPackage::myfunc"}]'

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ScriptX>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ScriptX>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ScriptX>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

The various plugins under the C<ScriptX::> namespace.

Older projects: L<Perinci::CmdLine>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
