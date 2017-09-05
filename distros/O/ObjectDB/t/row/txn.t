use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestEnv;

use Book;

subtest 'should rollback on exception' => sub {
    _setup();

    my $e = exception {
        Book->txn(
            sub {
                my $self = shift;

                Book->new(title => 'foo')->create;
                die 'here';
            }
        );
    };

    like $e, qr/here/;
    is(Book->table->count, 0);
};

subtest 'should not rollback if commited' => sub {
    _setup();

    my $e = exception {
        Book->txn(
            sub {
                my $self = shift;

                Book->new(title => 'foo')->create;
                $self->commit;
                die 'here';
            }
        );
    };

    like $e, qr/here/;
    is(Book->table->count, 1);
};

subtest 'should rollback manually' => sub {
    _setup();

    Book->txn(
        sub {
            my $self = shift;

            Book->new(title => 'foo')->create;
            $self->rollback;
        }
    );

    is(Book->table->count, 0);
};

subtest 'should return block value' => sub {
    _setup();

    my $result = Book->txn(
        sub {
            my $self = shift;

            'hi there';
        }
    );

    is($result, 'hi there');
};

done_testing;

sub _setup {
    TestEnv->prepare_table('book');
}
