use strict;
use warnings;
use Test::More;

use SQL::Format;

my $f = SQL::Format->new;
subtest 'no args' => sub {
    eval { $f->select };
    like $@, qr/Usage: \$sqlf->select\(/;
};

done_testing;
