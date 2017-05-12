use 5.008;
use strict;
use warnings;

package Test::CompanionClasses::Base;
BEGIN {
  $Test::CompanionClasses::Base::VERSION = '1.101370';
}
# ABSTRACT: Base class for test companion classes
use Test::More;
use UNIVERSAL::require;
use parent qw(
  Class::Accessor::Complex
  Data::Inherited
);
__PACKAGE__
    ->mk_new
    ->mk_scalar_accessors(qw(package));
use constant PLAN => 0;    # default

sub make_real_object {
    my ($self, @args) = @_;
    $self->package->require;
    die $@ if $@;
    $self->package->new(@args);
}
sub run { }

# this can be called as a class method as well
sub planned_test_count {
    my $self = shift;
    my $plan = 0;
    $plan += $_ for $self->every_list('PLAN');
    $plan;
}
1;


__END__
=pod

=for test_synopsis my ($foo, $bar);

=head1 NAME

Test::CompanionClasses::Base - Base class for test companion classes

=head1 VERSION

version 1.101370

=head1 SYNOPSIS

    package My::Foo_TEST;

    use warnings;
    use strict;

    use base 'Test::CompanionClasses::Base';

    use constant PLAN => 5;

    sub run {
        my $self = shift;
        $self->SUPER::run(@_);
        is_deeply($foo, $bar, 'some test');
        # ...
    }

=head1 DESCRIPTION

Base class for test companion classes. Each test companion class should
inherit from this class.

The package() property is automatically set; it holds the package name of the
class you are testing. If your test companion class is called C<My::Foo_TEST>,
then C<package()> will return C<My::Foo>.

=head1 METHODS

=head2 PLAN

A constant that says how many tests this particular class defines. Real test
companion classes (i.e., subclasses of this class) will want to redefine it
like this:

    use constant PLAN => 5;

Note that you should only specify how many tests the current class runs; test
counts of superclasses are automatically taken care of.

=head2 planned_test_count

Uses C<PLAN()>, calculated over the test companion class' whole class
hierarchy, to determine how many tests will be run in total.

=head2 make_real_object

Loads the actual class being tested (see C<package()>) and returns an object
of this class (constructed by calling C<new()> on it).

In your test companion class you will want to test certain assumptions about
your real class, so this method will be useful.

=head2 run

Test companion classes should override this method and run their tests. Be
sure to call C<SUPER::run(@_)> so that all tests over the class hierarchy are
run.

The C<run()> method in this base class just prints a line informing the test
user that tests for this particular companion class have begun. If you have
several companion classes - and you probably will or you won't have been using
C<Test::CompanionClasses> - this serves as a visual distinction of where on
companion class' tests end the next ones' begin.

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

