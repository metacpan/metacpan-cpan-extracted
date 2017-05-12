use strict;
use warnings;
use Test::More;

use SQL::Format;

my $f = SQL::Format->new;
subtest 'no args' => sub {
    eval { $f->insert() };
    like $@, qr/Usage: \$sqlf->insert\(/;
};

subtest 'values is not ref' => sub {
    eval { $f->insert(foo => 'bar') };
    like $@, qr/Usage: \$sqlf->insert\(/;
};

done_testing;
