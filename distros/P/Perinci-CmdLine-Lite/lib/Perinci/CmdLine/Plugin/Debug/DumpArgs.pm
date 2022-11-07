package Perinci::CmdLine::Plugin::Debug::DumpArgs;

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
        summary => 'Dump command-line arguments ($r->{args}), by default after argument validation',
        conf => {
        },
        tags => ['category:debugging'],
    };
}

sub after_validate_args {
    require Data::Dump::Color;

    my ($self, $r) = @_;

    Data::Dump::Color::dd($r->{args});
    [200, "OK"];
}

1;
# ABSTRACT: Dump command-line arguments ($r->{args}), by default after argument validation

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::Plugin::Debug::DumpArgs - Dump command-line arguments ($r->{args}), by default after argument validation

=head1 VERSION

This document describes version 1.926 of Perinci::CmdLine::Plugin::Debug::DumpArgs (from Perl distribution Perinci-CmdLine-Lite), released on 2022-11-04.

=head1 SYNOPSIS

To use, either specify in environment variable:

 PERINCI_CMDLINE_PLUGINS=-Debug::DumpArgs

or in code instantiating L<Perinci::CmdLine>:

 my $app = Perinci::CmdLine::Any->new(
     ...
     plugins => ["Debug::DumpArgs"],
 );

By default this plugin acts after the C<validate_args> event. If you want to
use at different event(s):

 my $app = Perinci::CmdLine::Any->new(
     ...
     plugins => [
         'Debug::DumpArgs@before_validate_args',
         'Debug::DumpArgs@before_output',
     ],
 );

For list of plugin events available, see L<Perinci::CmdLine::Base/"Plugin
events">.

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

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
