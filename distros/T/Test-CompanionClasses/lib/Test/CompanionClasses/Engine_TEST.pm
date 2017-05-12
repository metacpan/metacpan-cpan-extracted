use 5.008;
use strict;
use warnings;

package Test::CompanionClasses::Engine_TEST;
BEGIN {
  $Test::CompanionClasses::Engine_TEST::VERSION = '1.101370';
}
# ABSTRACT: Test companion class for the test companion class engine
use Test::More;
use parent 'Test::CompanionClasses::Base';
use constant PLAN => 1;

sub run {
    my $self = shift;
    $self->SUPER::run(@_);
    my $o = $self->make_real_object;
    can_ok($o, qw(new run_tests));
}
1;


__END__
=pod

=head1 NAME

Test::CompanionClasses::Engine_TEST - Test companion class for the test companion class engine

=head1 VERSION

version 1.101370

=head1 DESCRIPTION

Test companion class that is used to perform very basic tests on
L<Test::CompanionClasses> itself.

=head1 METHODS

=head2 run

Creates an object of its associated implementation class and checks that that
object C<can()> run C<new()> and C<run_tests()> methods.

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

