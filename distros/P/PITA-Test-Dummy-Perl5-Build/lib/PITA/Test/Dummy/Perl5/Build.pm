package PITA::Test::Dummy::Perl5::Build;

use 5.004;
use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.04';
}

sub dummy { 'Brian' }

1;

__END__

=pod

=head1 NAME

PITA::Test::Dummy::Perl5::Build - Brian, the CPAN Test Dummy for PITA Build.PL installs

=head1 SYNOPSIS

    use PITA::Test::Dummy::Perl5::Build;
    
    my $name = PITA::Test::Dummy::Perl5::Build->dummy;

=head1 DESCRIPTION

This module is part of the Perl Image Testing Architecture (PITA) and
acts as a test module for the L<PITA::Scheme::Perl5::Build> testing
scheme.

1. Contains no functionality, and will never do so.

2. Has no non-core depencies, and will never have any.

3. Exists on CPAN.

=head1 METHODS

=head2 dummy

Returns the dummy's name, in this case 'Brian'

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SUPPORT

No support is available for Brian.

Sigh... no his head was NOT meant to come off like that.

=head1 SEE ALSO

L<PITA>, L<PITA::Scheme::Perl5::Build>

=head1 COPYRIGHT

Copyright 2006 - 2008 Adam Kennedy.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
