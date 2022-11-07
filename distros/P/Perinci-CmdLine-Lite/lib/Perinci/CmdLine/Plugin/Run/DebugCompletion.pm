package Perinci::CmdLine::Plugin::Run::DebugCompletion;

# put pragmas + Log::ger here
use strict;
use warnings;
use Log::ger;
use parent 'Perinci::CmdLine::PluginBase';

# put other modules alphabetically here

# put global variables alphabetically here
our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-11-04'; # DATE
our $DIST = 'Perinci-CmdLine-Lite'; # DIST
our $VERSION = '1.926'; # VERSION

sub meta {
    return {
        summary => 'Debug completion',
        description => <<'_',

This plugin will make your script log tab completion information to a log file
then exit instead of doing a normal run. It can be used to debug tab completion
issues. An example of log line it produces:

    [/path/to/your-script] [prog PROGNAME] [pid 12345] [uid 1000] COMP_LINE=<your-script > (%d char(s)) COMP_POINT=<%s>\n",

This plugin is not included by default. To activate this plugin from the
command-line of bash shell:

    % PERINCI_CMDLINE_PLUGINS="-Run::DebugCompletion" your-script ...

By default it logs to `/tmp/pericmd-completion.log`. To customize the log file
location:

    % PERINCI_CMDLINE_PLUGINS="-Run::DebugCompletion,log_file,/path/to/log.file" your-script ...

This plugin runs at the C<run> event at a very high priority (1) then skips
all the other run handlers (return 201 status).

_
        conf => {
            log_file => {
                summary => 'Location of log file',
                schema => 'filename*',
                description => <<'_',

If not specified, will use `/tmp/pericmd-completion.log`.

_
            },
        },
        prio => 1, # very high
        tags => ['category:run-handler', 'category:debugging'],
    };
}

sub on_run {
    my ($self, $r) = @_;

    my $log_file = $self->{log_file};
    unless (defined $log_file) {
        require File::Spec;
        my $tmpdir = File::Spec->tmpdir;
        $log_file = File::Spec->catfile($tmpdir, "pericmd-completion.log");
    }

  LOG: {
        open my $fh, ">>", $log_file
            or do { warn "Can't open completion log file, skipped: $!"; last };
        print $fh sprintf(
            "[%s] [prog %s] [pid %d] [uid %d] COMP_LINE=<%s> (%d char(s)) COMP_POINT=<%s>\n",
            scalar(localtime),
            $0,
            $$,
            $>,
            $ENV{COMP_LINE},
            length($ENV{COMP_LINE}),
            $ENV{COMP_POINT},
        );
        print $fh join("", map {"  $_=$ENV{$_}\n"} sort keys %ENV);
        close $fh;
    }

    [201, "OK"]; # skip the rest of the event handlers
}

1;
# ABSTRACT: Debug completion

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::Plugin::Run::DebugCompletion - Debug completion

=head1 VERSION

This document describes version 1.926 of Perinci::CmdLine::Plugin::Run::DebugCompletion (from Perl distribution Perinci-CmdLine-Lite), released on 2022-11-04.

=for Pod::Coverage ^(.+)$

=head1 DESCRIPTION

This plugin will make your script log tab completion information to a log file
then exit instead of doing a normal run. It can be used to debug tab completion
issues. An example of log line it produces:

 [/path/to/your-script] [prog PROGNAME] [pid 12345] [uid 1000] COMP_LINE=<your-script > (%d char(s)) COMP_POINT=<%s>\n",

This plugin is not included by default. To activate this plugin from the
command-line of bash shell:

 % PERINCI_CMDLINE_PLUGINS="-Run::DebugCompletion" your-script ...

By default it logs to C</tmp/pericmd-completion.log>. To customize the log file
location:

 % PERINCI_CMDLINE_PLUGINS="-Run::DebugCompletion,log_file,/path/to/log.file" your-script ...

This plugin runs at the C<run> event at a very high priority (1) then skips
all the other run handlers (return 201 status).

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-Lite>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
