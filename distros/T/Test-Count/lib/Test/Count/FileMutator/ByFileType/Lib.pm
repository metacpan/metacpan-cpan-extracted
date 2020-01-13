package Test::Count::FileMutator::ByFileType::Lib;
$Test::Count::FileMutator::ByFileType::Lib::VERSION = '0.1101';
use strict;
use warnings;

use parent 'Test::Count::Base';
use Test::Count::FileMutator ();


sub _ft_params
{
    my $self = shift;

    if (@_)
    {
        $self->{_ft_params} = shift;
    }

    return $self->{_ft_params};
}

sub _filename
{
    my $self = shift;

    if (@_)
    {
        $self->{_filename} = shift;
    }

    return $self->{_filename};
}

sub _init
{
    my ( $self, $args ) = @_;

    my $filetype = $args->{filetype};
    my $filename = $args->{filename};

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
        'cc'     => "c",
        'cpp'    => "c",
        'cxx'    => "c",
        'p6'     => "perl",
        'pl'     => "perl",
        'py'     => "python",
        'scheme' => "lisp",
        't'      => "perl",
    );

    if ( !defined($filetype) )
    {
        ($filetype) = $filename =~ m#\.([^\./\\]+)\z#
            or die "Cannot determine extension from filename '$filename'!";
    }
    $filetype = exists( $aliases{$filetype} ) ? $aliases{$filetype} : $filetype;
    my $ft_params = exists( $params{$filetype} ) ? $params{$filetype} : +{};
    $self->{_filename}  = $filename;
    $self->{_ft_params} = $ft_params;

    return;
}

sub run
{
    my ($self) = @_;
    my $mutator = Test::Count::FileMutator->new(
        {
            filename => $self->_filename,
            %{ $self->_ft_params },
        }
    );

    $mutator->modify();

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 VERSION

version 0.1101

=head1 SYNOPSIS

    my $obj = Test::Count::FileMutator::ByFileType::Lib->new(
        {
            filename => "./t/test.t",
            filetype => "perl",
        }
    );

    $obj->run;

=head1 NAME

Test::Count::FileMutator::ByFileType::Lib - API to mutate files in place.

=head1 FUNCTIONS

=head2 run()

Runs the mutation process;

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

This module is free software, available under the MIT X11 Licence:

L<http://www.opensource.org/licenses/mit-license.php>

Copyright by Shlomi Fish, 2009.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

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

This software is Copyright (c) 2006 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
