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

# select all cpan distnames
my $cpandists = ORDB::CPAN::Mageia->selectcol_arrayref(
    'SELECT DISTINCT dist FROM module ORDER BY dist'
);

say $_ for grep { defined } @$cpandists;

exit;
__END__

=head1 DESCRIPTION

This small script prints all CPAN distributions available in Mageia,
one per line.
