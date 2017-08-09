use strict;
use warnings;
use Test::More;

use SQL::Format;

my $f = SQL::Format->new;
subtest 'no args' => sub {
    eval { $f->select };
    like $@, qr/Usage: \$sqlf->select\(/;
};

subtest 'conflict for_update and suffix' => sub {
    eval {
        $f->select(foo => '*', { hoge => 'fuga' }, {
            for_update => 1,
            suffix     => 'LOCK IN SHARE MODE',
        });
    };
    like $@, qr/Conflict option \`for_update\` and \`suffix\`\. \`for_update\` option is ignored/;
};

done_testing;
