package Perinci::CmdLine::Plugin::Run::Normal;

# put pragmas + Log::ger here
use strict;
use warnings;
use Log::ger;
use parent 'Perinci::CmdLine::PluginBase';

# put other modules alphabetically here
use IO::Interactive qw(is_interactive);

# put global variables alphabetically here
our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-12-01'; # DATE
our $DIST = 'Perinci-CmdLine-Lite'; # DIST
our $VERSION = '1.912'; # VERSION

sub meta {
    return {
        summary => 'Normal run',
        description => <<'_',

This plugin is included by default, run at the `run` event for a normal run.

_
        conf => {
        },
        prio => 50, # normal
        tags => ['category:run-handler'],
    };
}

sub on_run {
    my ($self, $r) = @_;

    # dump object is special case, we delegate to do_dump_object()
    if ($ENV{PERINCI_CMDLINE_DUMP_OBJECT} //
        $ENV{PERINCI_CMDLINE_DUMP} # old name that will be removed
    ) {
        $r->{res} = $self->cmdline->do_dump_object($r);
        goto FORMAT;
    }

    # completion is special case, we delegate to do_completion()
    if ($self->cmdline->_detect_completion($r)) {
        $r->{res} = $self->cmdline->do_completion($r);
        goto FORMAT;
    }

    my $co = $r->{common_opts};

    # set default from common options
    $r->{naked_res} = $co->{naked_res}{default} if $co->{naked_res};
    $r->{format}    = $co->{format}{default} if $co->{format};

    # EXPERIMENTAL, set default format to json if we are running in a pipeline
    # and the right side of the pipe is the 'td' program
    {
        last if is_interactive(*STDOUT) || $r->{format};
        last unless eval { require Pipe::Find; 1 };
        my $pipeinfo = Pipe::Find::get_stdout_pipe_process();
        last unless $pipeinfo;
        last unless $pipeinfo->{exe} =~ m![/\\]td\z! ||
            $pipeinfo->{cmdline} =~ m!\A([^\0]*[/\\])?perl\0([^\0]*[/\\])?td\0!;
        $r->{format} = 'json';
    }

    $r->{format} //= $self->cmdline->default_format;

    if ($self->cmdline->read_config) {
        # note that we will be reading config file
        $r->{read_config} = 1;
    }

    if ($self->cmdline->read_env) {
        # note that we will be reading env for default options
        $r->{read_env} = 1;
    }

    eval {
        log_trace("[pericmd] Running hook_before_run ...");
        $self->cmdline->hook_before_run($r);

        log_trace("[pericmd] Running hook_before_parse_argv ...");
        $self->cmdline->hook_before_parse_argv($r);

        my $parse_res = $self->cmdline->parse_argv($r);
        if ($parse_res->[0] == 501) {
            # we'll need to send ARGV to the server, because it's impossible to
            # get args from ARGV (e.g. there's a cmdline_alias with CODE, which
            # has been transformed into string when crossing network boundary)
            $r->{send_argv} = 1;
        } elsif ($parse_res->[0] != 200) {
            die $parse_res;
        }
        $r->{parse_argv_res} = $parse_res;
        $r->{args} = $parse_res->[2] // {};

        # set defaults
        $r->{action} //= 'call';

        # init logging
        if ($self->cmdline->log) {
            require Log::ger::App;
            my $default_level = do {
                my $dry_run = $r->{dry_run} // $self->cmdline->default_dry_run;
                $dry_run ? 'info' : 'warn';
            };
            Log::ger::App->import(
                level => $r->{log_level} // $self->cmdline->log_level // $default_level,
                name  => $self->cmdline->program_name,
            );
        }

        log_trace("[pericmd] Running hook_after_parse_argv ...");
        $self->cmdline->hook_after_parse_argv($r);

        if ($ENV{PERINCI_CMDLINE_DUMP_CONFIG}) {
            log_trace "[pericmd] Dumping config ...";
            $r->{res} = $self->cmdline->do_dump_config($r);
            goto FORMAT;
        }

        $self->cmdline->parse_cmdline_src($r);

        #log_trace("TMP: parse_res: %s", $parse_res);

        my $missing = $parse_res->[3]{"func.missing_args"};
        die [400, "Missing required argument(s): ".join(", ", @$missing)]
            if $missing && @$missing;

        my $scd = $r->{subcommand_data};
        if ($scd->{pass_cmdline_object} // $self->cmdline->pass_cmdline_object) {
            $r->{args}{-cmdline} = $self->cmdline;
            $r->{args}{-cmdline_r} = $r;
        }

        log_trace("[pericmd] Running hook_before_action ...");
        $self->cmdline->hook_before_action($r);

        my $meth = "action_$r->{action}";
        die [500, "Unknown action $r->{action}"] unless $self->cmdline->can($meth);
        if ($ENV{PERINCI_CMDLINE_DUMP_ARGS}) {
            log_trace "[pericmd] Dumping arguments ...";
            $r->{res} = $self->cmdline->do_dump_args($r);
            goto FORMAT;
        }
        log_trace("[pericmd] Running %s() ...", $meth);
        $self->cmdline->_plugin_run_event(
            name => 'action',
            on_success => sub {
                $r->{res} = $self->cmdline->$meth($r);
            },
        );

        log_trace("[pericmd] Running hook_after_action ...");
        $self->cmdline->hook_after_action($r);
    };

    my $err = $@;
    if ($err || !$r->{res}) {
        if ($err) {
            $err = [500, "Died: $err"] unless ref($err) eq 'ARRAY';
            if (%Devel::Confess::) {
                no warnings 'once';
                require Scalar::Util;
                my $id = Scalar::Util::refaddr($err);
                my $stack_trace = $Devel::Confess::MESSAGES{$id};
                $err->[1] .= "\n$stack_trace" if $stack_trace;
            }
            $err->[1] =~ s/\n+$//;
            $r->{res} = $err;
        } else {
            $r->{res} = [500, "Bug: no response produced"];
        }
    } elsif (ref($r->{res}) ne 'ARRAY') {
        log_trace("[pericmd] res=%s", $r->{res}); #2
        $r->{res} = [500, "Bug in program: result not an array"];
    }

    if (!$r->{res}[0] || $r->{res}[0] < 200 || $r->{res}[0] > 555) {
        $r->{res}[3]{'x.orig_status'} = $r->{res}[0];
        $r->{res}[0] = 555;
    }

    $r->{format} //= $r->{res}[3]{'cmdline.default_format'};
    $r->{format} //= $r->{meta}{'cmdline.default_format'};
    my $restore_orig_result;
    my $orig_result;
    if (exists $r->{res}[3]{'cmdline.result.noninteractive'} && !is_interactive(*STDOUT)) {
        $restore_orig_result = 1;
        $orig_result = $r->{res}[2];
        $r->{res}[2] = $r->{res}[3]{'cmdline.result.noninteractive'};
    } elsif (exists $r->{res}[3]{'cmdline.result.interactive'} && is_interactive(*STDOUT)) {
        $restore_orig_result = 1;
        $orig_result = $r->{res}[2];
        $r->{res}[2] = $r->{res}[3]{'cmdline.result.interactive'};
    } elsif (exists $r->{res}[3]{'cmdline.result'}) {
        $restore_orig_result = 1;
        $orig_result = $r->{res}[2];
        $r->{res}[2] = $r->{res}[3]{'cmdline.result'};
    }
  FORMAT:
    my $is_success = $r->{res}[0] =~ /\A2/ || $r->{res}[0] == 304;

    if (defined $ENV{PERINCI_CMDLINE_OUTPUT_DIR}) {
        $self->cmdline->save_output($r);
    }

    if ($is_success &&
            ($self->cmdline->skip_format ||
             $r->{meta}{'cmdline.skip_format'} ||
             $r->{res}[3]{'cmdline.skip_format'})) {
        $r->{fres} = $r->{res}[2] // '';
    } elsif ($is_success &&
                 ($r->{res}[3]{stream} // $r->{meta}{result}{stream})) {
        # stream will be formatted as displayed by display_result()
    }else {
        log_trace("[pericmd] Running hook_format_result ...");
        $r->{res}[3]{stream} = 0;
        $r->{fres} = $self->cmdline->hook_format_result($r) // '';
    }
    $self->cmdline->select_output_handle($r);
    log_trace("[pericmd] Running hook_display_result ...");
    $self->cmdline->hook_display_result($r);
    log_trace("[pericmd] Running hook_after_run ...");
    $self->cmdline->hook_after_run($r);

    if ($restore_orig_result) {
        $r->{res}[2] = $orig_result;
    }

    my $exitcode;
    if ($r->{res}[3] && defined($r->{res}[3]{'cmdline.exit_code'})) {
        $exitcode = $r->{res}[3]{'cmdline.exit_code'};
    } else {
        $exitcode = $self->cmdline->status2exitcode($r->{res}[0]);
    }
    if ($self->cmdline->exit) {
        log_trace("[pericmd] exit(%s)", $exitcode);
        exit $exitcode;
    } else {
        # so this can be tested
        log_trace("[pericmd] <- run(), exitcode=%s", $exitcode);
        $r->{res}[3]{'x.perinci.cmdline.base.exit_code'} = $exitcode;
        return $r->{res};
    }
}

1;
# ABSTRACT: Normal run

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::Plugin::Run::Normal - Normal run

=head1 VERSION

This document describes version 1.912 of Perinci::CmdLine::Plugin::Run::Normal (from Perl distribution Perinci-CmdLine-Lite), released on 2021-12-01.

=for Pod::Coverage ^(.+)$

=head1 DESCRIPTION

This plugin is included by default, run at the C<run> event for a normal run.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-Lite>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-Lite>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-Lite>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
