package Perinci::CmdLine::Plugin::Run::DumpObject;

# put pragmas + Log::ger here
use strict;
use warnings;
use Log::ger;
use parent 'Perinci::CmdLine::PluginBase';

# put other modules alphabetically here

# put global variables alphabetically here
our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-04-21'; # DATE
our $DIST = 'Perinci-CmdLine-Lite'; # DIST
our $VERSION = '1.920'; # VERSION

sub meta {
    return {
        summary => 'Dump object mode',
        description => <<'_',

This plugin is included by default at a high priority and activated if the
PERINCI_CMDLINE_DUMP_OBJECT environmnent is true.

_
        conf => {
        },
        prio => 10, # high
        tags => ['category:run-handler', 'category:debugging'],
    };
}

sub on_run {
    my ($self, $r) = @_;

    return [100] unless $ENV{PERINCI_CMDLINE_DUMP_OBJECT};

    require Data::Dump;

    local $r->{in_dump_object} = 1;

    # check whether subcommand is defined. try to search from --cmd, first
    # command-line argument, or default_subcommand.
    $self->cmdline->hook_before_parse_argv($r);
    $self->cmdline->_parse_argv1($r);

    if ($r->{read_env}) {
        my $env_words = $self->cmdline->_read_env($r);
        unshift @ARGV, @$env_words;
    }

    my $scd = $r->{subcommand_data};
    # we do get_meta() currently because some common option like dry_run is
    # added in hook_after_get_meta().
    my $meta = $self->cmdline->get_meta($r, $scd->{url} // $self->cmdline->{url});

    # additional information, because scripts often put their metadata in 'main'
    # package
    {
        no warnings 'once';
        $self->cmdline->{'x.main.spec'} = \%main::SPEC;
    }

    my $label = $ENV{PERINCI_CMDLINE_DUMP_OBJECT};
    my $dump = join(
        "",
        "# BEGIN DUMP $label\n",
        Data::Dump::dump($self->cmdline), "\n",
        "# END DUMP $label\n",
    );

    $r->{res} = [
        200, "OK", $dump,
        {
            stream => 0,
            "cmdline.skip_format" => 1,
        },
    ];

    $self->cmdline->_format($r);

    [201, "OK"]; # skip the rest of the event handlers
}

1;
# ABSTRACT: Dump object mode

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::Plugin::Run::DumpObject - Dump object mode

=head1 VERSION

This document describes version 1.920 of Perinci::CmdLine::Plugin::Run::DumpObject (from Perl distribution Perinci-CmdLine-Lite), released on 2022-04-21.

=head1 DESCRIPTION

A C<Run::> plugin is the main plugin that runs at the C<run> event, which is
fired by Perinci::CmdLine's C<run()> method.

Multiple C<Run::*> plugins can be registered at the C<run> event, but only one
will actually run because they return C<201> code which instruct
Perinci::CmdLine to end the event early.

The C<Run::DumpObject> plugin handler first check if the
PERINCI_CMDLINE_DUMP_OBJECT variable is set to a true value (containing some
label e.g. foo). If not, then the handler declines.

The handler then dumps the main Perinci::CmdLine object and exits.

This mode can be used by tools like L<shcompgen> to extract the command-line
options.

=for Pod::Coverage ^(.+)$

=head1 ENVIRONMENT

=head2 PERINCI_CMDLINE_DUMP_OBJECT

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

This software is copyright (c) 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-Lite>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
