use 5.008;
use strict;
use warnings;

package Test::CompanionClasses;
BEGIN {
  $Test::CompanionClasses::VERSION = '1.101370';
}
# ABSTRACT: Run tests defined in companion classes
use Test::CompanionClasses::Engine;
use Getopt::Long;
use Exporter qw(import);
our @EXPORT  = ('run_tests');

sub run_tests {
    my $exact;
    GetOptions(exact => \$exact)
      or die "usage: $0 [ --exact ] filter...\n";
    Test::CompanionClasses::Engine->new->run_tests(
        exact  => $exact,
        filter => [@main::ARGV],

        # inherited => [ $inherited_spec ],
    );
}
1;


__END__
=pod

=head1 NAME

Test::CompanionClasses - Run tests defined in companion classes

=head1 VERSION

version 1.101370

=head1 SYNOPSIS

    # Define a test file, for example C<t/01_companion_classes.t>:

    use Test::CompanionClasses;
    run_tests;

    # Then you can do:
    # perl t/01_companion_classes.t --exact Foo::Bar Baz

=head1 DESCRIPTION

This is a very basic frontend for L<Test::CompanionClasses::Engine> which you
can use for your distribution test files (in C<t/>).

The intention is that you use it as shown in the L</SYNOPSIS>.

=head1 METHODS

=head2 run_tests

Parses the command-line options, then calls the C<run_tests()> method of
L<Test::CompanionClasses::Engine>.

You might want to make sure that the companion tests work when run
individually as well. In that case you might use something like this:

    find lib/ -name \*_TEST.pm | \
        xargs ack -ho '(?<=^package )([\w:]+)(?=_TEST)' | \
        xargs -i{} perl t/01_companion_classes.t --exact {}

=head1 COMMAND-LINE USAGE

The following command-line arguments are supported:

=over 4

=item --exact

Specifies that the package filter is to be used exactly, i.e., substring
matching is not enough. See L<Test::CompanionClasses::Engine> for details.

=back

The rest of the command line is interpreted as a list of package filters.
Again, see L<Test::CompanionClasses::Engine> for details.

The C<inherited> mechanism is not supported (yet).

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Test-CompanionClasses>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Test-CompanionClasses/>.

The development version lives at
L<http://github.com/hanekomu/Test-CompanionClasses/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

