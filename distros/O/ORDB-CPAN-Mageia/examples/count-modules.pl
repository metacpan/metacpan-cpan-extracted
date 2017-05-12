#!/usr/bin/perl
#
# This file is part of ORDB-CPAN-Mageia
#
# This software is copyright (c) 2012 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use 5.010;
use strict;
use warnings;

use ORDB::CPAN::Mageia;

my $nbmodules = ORDB::CPAN::Mageia::Module->count;
say "$nbmodules modules found";

exit;
__END__

=head1 DESCRIPTION

This small script prints the number of Perl modules available in
Mageia.
