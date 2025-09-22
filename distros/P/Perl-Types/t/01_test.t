#
# This file is part of Perl-Types
#
# This software is Copyright (c) 2025 by Perl Community 501(c)(3) nonprofit organization.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use Test2::V0;
use Data::Dumper;
use Perl::Types;

our $VERSION = 0.001_000;

plan tests => 4;

#diag '<<< DEBUG >>> have $foo = ', $foo, "\n";


ok ( (my integer $foo = 1), 'my integer $foo = 1');
ok ( (my string $bar = 'howdy'), 'my string $bar = ...');
ok ( (my arrayref::string $bat = ['howdy', 'doody', 'y\'all']), 'my arrayref::string $bat = ...');
ok ( (my hashref::string $bax = {h => 'howdy', d => 'doody', y => 'y\'all'}), 'my hashref::string $bax = ...');

done_testing();

