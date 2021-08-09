package Perinci::CmdLine::Plugin::DumpR;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-06'; # DATE
our $DIST = 'Perinci-CmdLine-Lite'; # DIST
our $VERSION = '1.907'; # VERSION

# IFUNBUILT
# use strict;
# use warnings;
# END IFUNBUILT
use Log::ger;

use parent 'Perinci::CmdLine::PluginBase';

sub meta {
    return {
        summary => 'Dump request stash ($r), by default after action',
        conf => {
        },
    };
}

sub after_action {
    require Data::Dump::Color;

    my ($self, $r) = @_;

    Data::Dump::Color::dd($r);
    [200, "OK"];
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::Plugin::DumpR

=head1 VERSION

This document describes version 1.907 of Perinci::CmdLine::Plugin::DumpR (from Perl distribution Perinci-CmdLine-Lite), released on 2021-08-06.

=head1 SYNOPSIS

To use, either specify in environment variable:

 PERINCI_CMDLINE_PLUGINS=-DumpR

or in code instantiating L<Perinci::CmdLine>:

 my $app = Perinci::CmdLine::Any->new(
     ...
     plugins => ["DumpR"],
 );

If you want to dump at different events:

 my $app = Perinci::CmdLine::Any->new(
     ...
     plugins => [
         'DumpArgs@before_end',
     ],
 );

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-Lite>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-Lite>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-Lite>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
