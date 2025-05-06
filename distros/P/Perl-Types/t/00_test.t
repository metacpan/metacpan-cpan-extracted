#
# This file is part of Perl-Types
#
# This software is copyright (c) 2025 by Auto-Parallel Technologies, Inc.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use Test2::V0;
use Data::Dumper;
use Perl::Types;

our $VERSION = 0.001_000;

plan tests => 4;

#diag '<<< DEBUG >>> have $foo = ', $foo, "\n";


ok ( (my integer $foo = 1), 'my integer $foo = 1');
ok ( (my string $bar = 'howdy'), 'my string $bar = ...');
ok ( (my string::arrayref $bat = ['howdy', 'doody', 'y\'all']), 'my string::arrayref $bat = ...');
ok ( (my string::hashref $bax = {h => 'howdy', d => 'doody', y => 'y\'all'}), 'my string::hashref $bax = ...');

done_testing();

