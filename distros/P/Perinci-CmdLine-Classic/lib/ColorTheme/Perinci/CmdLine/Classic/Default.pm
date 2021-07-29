package ColorTheme::Perinci::CmdLine::Classic::Default;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-11'; # DATE
our $DIST = 'Perinci-CmdLine-Classic'; # DIST
our $VERSION = '1.815'; # VERSION

use strict;
use warnings;
use parent 'ColorThemeBase::Static';

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

This document describes version 1.815 of ColorTheme::Perinci::CmdLine::Classic::Default (from Perl distribution Perinci-CmdLine-Classic), released on 2021-07-11.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-Classic>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-Classic>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-Classic>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
