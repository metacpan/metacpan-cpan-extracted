package Test::Count::Filter::ByFileType::App;
$Test::Count::Filter::ByFileType::App::VERSION = '0.1001';
use strict;
use warnings;

use Test::Count::Filter;
use Getopt::Long;

use base 'Exporter';

our @EXPORT = (qw(run));


sub run
{
    my $filetype = "perl";
    GetOptions( 'ft=s' => \$filetype );

    my %params = (
        'lisp' => {
            assert_prefix_regex => qr{; TEST},
            plan_prefix_regex   => qr{\(plan\s+},
        },
        'c' => {
            assert_prefix_regex => qr{/[/\*]\s+TEST},
            plan_prefix_regex   => qr{\s*plan_tests\s*\(\s*},
        },
        'python' => {
            plan_prefix_regex => qr{plan\s*\(\s*},
        },
    );

    my %aliases = (
        'arc'    => "lisp",
        'scheme' => "lisp",
        'cpp'    => "c",
    );

    $filetype = exists( $aliases{$filetype} ) ? $aliases{$filetype} : $filetype;
    my $ft_params = exists( $params{$filetype} ) ? $params{$filetype} : +{};

    my $filter = Test::Count::Filter->new( { %{$ft_params}, } );

    $filter->process();

    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 VERSION

version 0.1001

=head1 SYNOPSIS

    # To filter C code
    $ perl -MTest::Count::Filter::ByFileType::App -e 'run()' --ft=c

    # To filter Perl 5 code
    $ perl -MTest::Count::Filter::ByFileType::App -e 'run()'

=head1 NAME

Test::Count::Filter::ByFileType::App - a standalone command line application
that filters according to the filetype.

=head1 FUNCTIONS

=head2 run()

Runs the program.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-count at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test::Count>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Count

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test::Count>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test::Count>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test::Count>

=item * Search CPAN

L<http://search.cpan.org/dist/Test::Count>

=back

=head1 SEE ALSO

L<Test::Count>, L<Test::Count::Parser>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2009 Shlomi Fish.

This program is released under the following license: MIT X11.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Test-Count>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Test-Count>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Count>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Test-Count>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Test-Count>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Test-Count>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/T/Test-Count>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Test-Count>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Test::Count>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-test-count at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Test-Count>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-test-count>

  git clone git://github.com/shlomif/perl-test-count.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/perl-test-count/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
