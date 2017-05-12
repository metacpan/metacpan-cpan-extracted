use strict;
use warnings;
use Test::More;

use SQL::Format;

my $f = SQL::Format->new;
subtest 'no args' => sub {
    eval { $f->update() };
    like $@, qr/Usage: \$sqlf->update\(/;
};

subtest 'no ref $args' => sub {
    eval { $f->update(foo => 'args') };
    like $@, qr/Usage: \$sqlf->update\(/;
};

done_testing;
