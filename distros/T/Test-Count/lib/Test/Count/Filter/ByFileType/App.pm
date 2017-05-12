package Test::Count::Filter::ByFileType::App;

use strict;
use warnings;

use Test::Count::Filter;
use Getopt::Long;

use base 'Exporter';

our @EXPORT = (qw(run));

=encoding utf8

=head1 NAME

Test::Count::Filter::ByFileType::App - a standalone command line application
that filters according to the filetype.

=head1 SYNOPSIS

    # To filter C code
    $ perl -MTest::Count::Filter::ByFileType::App -e 'run()' --ft=c

    # To filter Perl 5 code
    $ perl -MTest::Count::Filter::ByFileType::App -e 'run()'

=head1 FUNCTIONS

=head2 run()

Runs the program.

=cut

sub run
{
    my $filetype = "perl";
    GetOptions('ft=s' => \$filetype);

    my %params =
    (
        'lisp' =>
        {
            assert_prefix_regex => qr{; TEST},
            plan_prefix_regex => qr{\(plan\s+},
        },
        'c' =>
        {
            assert_prefix_regex => qr{/[/\*]\s+TEST},
            plan_prefix_regex => qr{\s*plan_tests\s*\(\s*},
        },
        'python' =>
        {
            plan_prefix_regex => qr{plan\s*\(\s*},
        },
    );

    my %aliases =
    (
        'arc' => "lisp",
        'scheme' => "lisp",
        'cpp' => "c",
    );

    $filetype = exists($aliases{$filetype}) ? $aliases{$filetype} : $filetype;
    my $ft_params = exists($params{$filetype}) ? $params{$filetype} : +{};

    my $filter =
        Test::Count::Filter->new(
            {
                %{$ft_params},
            }
        );

    $filter->process();

    return 0;
}

1;

__END__

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

=cut

