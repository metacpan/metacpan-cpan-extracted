use Test::Spec;
use Test::Fatal;

use lib 't/lib';

use ObjectDB::Exception;
use Author;

describe 'exception' => sub {

    it 'croaks' => sub {
        ok exception { ObjectDB::Exception->throw('error') };
    };

    it 'stringifies' => sub {
        like exception { ObjectDB::Exception->throw('error') }, qr/error/;
    };

    it 'save context' => sub {
        like exception {
            ObjectDB::Exception->throw('error', context => Author->new);
        }, qr/: class='Author', table='author'/;
    };

    it 'save context sql' => sub {
        like exception {
            ObjectDB::Exception->throw(
                'error',
                sql => SQL::Composer->build(
                    'select',
                    columns => ['a'],
                    from    => 'table',
                    where   => [a => 'b']
                )
            );
        }, qr/SELECT/;
    };

};

runtests unless caller;
