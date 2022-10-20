package ColorTheme::Perinci::CmdLine::Classic::Default;

use strict;
use warnings;
use parent 'ColorThemeBase::Static';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-10-19'; # DATE
our $DIST = 'Perinci-CmdLine-Classic'; # DIST
our $VERSION = '1.817'; # VERSION

our %THEME = (
    v => 2,
    summary => 'Default color theme for Perinci::CmdLine::Classic (for terminals with black background)',
    items => {
        heading       => 'ff9933',
        text          => undef,
        error_label   => 'cc0000',
        warning_label => 'cccc00',
        program_name  => {ansi_fg=>"\e[1m"}, # bold
        option_name   => 'cc6633',
        emphasis      => {ansi_fg=>"\e[1m"}, # bold
        #option_value  => undef,
        #argument      => undef,
    },
);

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTheme::Perinci::CmdLine::Classic::Default

=head1 VERSION

This document describes version 1.817 of ColorTheme::Perinci::CmdLine::Classic::Default (from Perl distribution Perinci-CmdLine-Classic), released on 2022-10-19.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-Classic>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-Classic>.

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

This software is copyright (c) 2022, 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-Classic>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
