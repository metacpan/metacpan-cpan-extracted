use strict;
use warnings;
use Test::More;

use SQL::Format;

my $f = SQL::Format->new;
subtest 'no args' => sub {
    eval { $f->delete() };
    like $@, qr/Usage: \$sqlf->delete\(/;
};

done_testing;
