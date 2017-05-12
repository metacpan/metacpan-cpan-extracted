package PITA::Test::Dummy::Perl5::Deps;

use 5.004;
use strict;
use PITA::Test::Dummy::Perl5::Make;
use PITA::Test::Dummy::Perl5::Build;
use PITA::Test::Dummy::Perl5::MI;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.03';
}

sub dummy { 'Darren' }

1;

__END__

=pod

=head1 NAME

PITA::Test::Dummy::Perl5::Deps - CPAN Test Dummy for PITA Makefile.PL installs

=head1 SYNOPSIS

    use PITA::Test::Dummy::Perl5::Deps;
    
    my $name = PITA::Test::Dummy::Perl5::Deps->dummy;

=head1 DESCRIPTION

This module is part of the Perl Image Testing Architecture (PITA) and
acts as a test module for the L<PITA::Scheme::Perl5::Deps> testing
scheme.

1. Contains no functionality, and will never do so.

2. Has no non-core depencies other than the three other PITA test dummies, and will never have any.

3. Exists on CPAN.

=head1 METHODS

=head2 dummy

Returns the dummy's name, in this case 'Darren'

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SUPPORT

No support is available for Darren.

His head B<is> supposed to come off, but only last, after the other three

=head1 SEE ALSO

L<PITA>, L<PITA::Scheme::Perl5::Make>, L<http://ali.as/pita/>

=head1 COPYRIGHT

Copyright 2006 - 2008 Adam Kennedy.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
