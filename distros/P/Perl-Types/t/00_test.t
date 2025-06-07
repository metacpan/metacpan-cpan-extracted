#
# This file is part of Perl-Types
#
# This software is copyright (c) 2025 by Auto-Parallel Technologies, Inc.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use Test::More;
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

