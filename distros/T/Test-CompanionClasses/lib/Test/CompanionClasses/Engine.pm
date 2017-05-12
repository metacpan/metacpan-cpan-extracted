use 5.008;
use strict;
use warnings;

package Test::CompanionClasses::Engine;
BEGIN {
  $Test::CompanionClasses::Engine::VERSION = '1.101370';
}
# ABSTRACT: Run tests defined in companion classes
use FindBin '$Bin';
use File::Find;
use Test::More;
use UNIVERSAL::require;
use parent 'Class::Accessor::Complex';
__PACKAGE__->mk_new;

sub run_tests {
    my ($self, %args) = @_;
    our $package_filter = join '|' => map { "\Q$_\E" } @{ $args{filter} || [] };
    $package_filter = "^($package_filter)\$" if $args{exact};

    # default uses lib/ one level up, as the program using this class usually
    # lives in t/
    my $lib = $args{lib} || "$Bin/../lib";
    my @test_packages =
      map { { real_package => $_, test_package => $_ . '_TEST', } }
      grep { $package_filter ? m/$package_filter/ : 1 }
      @{ $args{inherited} || [] };
    find(
        sub {
            return unless -f && /_TEST\.pm$/;
            my $test_package;
            if ($File::Find::name =~ m!\Q$lib\E/(.*_TEST)\.pm$!) {
                ($test_package = $1) =~ s!/!::!g;
            } else {
                die "can't determine package from filename [$File::Find::name]";
            }
            (my $real_package = $test_package) =~ s/_TEST$//;
            return if $package_filter && ($real_package !~ $package_filter);
            push @test_packages => {
                real_package => $real_package,
                test_package => $test_package,
            };
        },
        $lib
    );
    plan tests => scalar @test_packages;
    for (@test_packages) {
        subtest $_->{test_package}, sub {
            $_->{test_package}->require;
            die $@ if $@;
            plan tests => $_->{test_package}->planned_test_count;
            $_->{test_package}->new('package' => $_->{real_package})->run;
        };
    }
}
1;


__END__
=pod

=head1 NAME

Test::CompanionClasses::Engine - Run tests defined in companion classes

=head1 VERSION

version 1.101370

=head1 SYNOPSIS

    use Test::CompanionClasses;
    Test::CompanionClasses->new->run_tests('...');

=head1 DESCRIPTION

This is the core of C<Test::CompanionClasses>.

=head1 METHODS

=head2 run_tests

Actually runs the companion class tests.

Takes named arguments (as a hash). Recognized keys are:

=over 4

=item C<filter>

A reference to a list of strings that are interpreted as package filters. A
companion test class is only run if the corresponding real class' package name
matches this filter list.

=item C<exact>

Works with C<filter>. If this boolean flag is set, the real class name must
match exactly, otherwise a substring match is sufficient.

Examples:

    Test::CompanionClasses->mk_new->run_tests(
        filter => [ qw/Foo::Bar Baz/ ]
    );

will run the companion tests of C<Foo::Bar>, C<Baz> but also
C<Foo::Bar::Flurble>, C<Bazzzz> etc.

    Test::CompanionClasses->mk_new->run_tests(
        filter => [ qw/Foo::Bar Baz/ ]
        exact  => 1,
    );

will only run the companion tests of C<Foo::Bar> and C<Baz>.

=item C<lib>

Sets the directory in and under which C<run_tests()> is looking for test
companion classes. Defaults to C<$Bin/../lib>, where C<$Bin> is the location
of the program as determined by L<FindBin>. This default is used because
normally companion class tests will be run from a perl distribution's C<t/>
directory.

=item C<inherited>

You can also specify that other classes not found in C<lib> should be tested.
Use a reference to an array of class names as the value for C<inherited> and
those classes' companion tests will be run as well. The class names still have
to match the C<filter>, if one was specified.

This is useful if your distribution depends on another one which also has
defined test companion classes. If your distribution changes the way these
other test companion classes are working, you can inherit those tests to see
whether they still work with your distribution.

=back

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

