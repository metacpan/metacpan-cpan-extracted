package PITA::Test::Dummy::Perl5::MI;

use 5.005;
use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.77';
}

sub dummy { 'Milton' }

1;

__END__

=pod

=head1 NAME

PITA::Test::Dummy::Perl5::MI - CPAN Test Dummy for testing Module::Install::With

=head1 SYNOPSIS

    use PITA::Test::Dummy::Perl5::MI;
    
    my $name = PITA::Test::Dummy::Perl5::MI->dummy;

=head1 DESCRIPTION

This module is part of the Perl Image Testing Architecture (PITA) and
acts as a test module for seeing if the environment-sensing functionaliy
in L<Module::Install> work as expected.

As such, his F<Makefile.PL> contains some non-standard instrumentation
which outputs harmless human-readable testing data to STDOUT for later
analysis outside of the installation.

In addition, it shares the normal functionality of all CPAN Test Dummies.

1. Contains no functionality, and will never do so.

2. Has no non-core depencies, and will never have any.

3. Exists on CPAN.

Unlike the other Test Dummies, the versioning of Milton loosely matches
that of the L<Module::Install> version he was built with ("loosely" because
sometimes he gets built with non-production versions of Module::Install).

=head1 METHODS

=head2 dummy

Returns the dummy's name, in this case 'Milton'

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SUPPORT

No support is available for Milton.

His head is meant to come off ONLY when called as F<Makefile.PL> :)

=head1 SEE ALSO

L<Module::Install>, L<PITA>

=head1 COPYRIGHT & LICENSE

Copyright 2006 - 2008 Adam Kennedy.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
