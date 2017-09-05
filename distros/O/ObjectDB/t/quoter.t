use strict;
use warnings;
use lib 't/lib';

use Test::More;

use Book;

use_ok 'ObjectDB::Quoter';

subtest 'quote' => sub {
    my $quoter = ObjectDB::Quoter->new;

    is $quoter->quote('foo'), '`foo`';
    is_deeply [ $quoter->with ], [];
};

subtest 'collect with' => sub {
    my $quoter = ObjectDB::Quoter->new(meta => Book->meta);

    is $quoter->quote('parent_author.name'), '`parent_author`.`name`';
    is_deeply [ $quoter->with ], ['parent_author'];
};

subtest 'not collect with if exists' => sub {
    my $quoter = ObjectDB::Quoter->new(meta => Book->meta);

    $quoter->quote('parent_author.name');
    $quoter->quote('parent_author.name');

    is_deeply [ $quoter->with ], ['parent_author'];
};

done_testing;
