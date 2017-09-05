use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;

use Author;

use_ok 'ObjectDB::Exception';

subtest 'croaks' => sub {
    ok exception { ObjectDB::Exception->throw('error') };
};

subtest 'stringifies' => sub {
    like exception { ObjectDB::Exception->throw('error') }, qr/error/;
};

subtest 'save context' => sub {
    like exception {
        ObjectDB::Exception->throw('error', context => Author->new);
    }, qr/: class='Author', table='author'/;
};

subtest 'save context sql' => sub {
    like exception {
        ObjectDB::Exception->throw(
            'error',
            sql => SQL::Composer->build(
                'select',
                columns => ['a'],
                from    => 'table',
                where   => [ a => 'b' ]
            )
        );
    }, qr/SELECT/;
};

done_testing;
