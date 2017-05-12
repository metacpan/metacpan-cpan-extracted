use Test::Spec;
use Test::Fatal;

use lib 't/lib';

use TestEnv;
use Book;

describe 'transaction' => sub {

    before each => sub {
        TestEnv->prepare_table('book');
    };

    it 'should rollback on exception' => sub {
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

    it 'should not rollback if commited' => sub {
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

    it 'should rollback manually' => sub {
        Book->txn(
            sub {
                my $self = shift;

                Book->new(title => 'foo')->create;
                $self->rollback;
            }
        );

        is(Book->table->count, 0);
    };

    it 'should return block value' => sub {
        my $result = Book->txn(
            sub {
                my $self = shift;

                'hi there';
            }
        );

        is($result, 'hi there');
    };

};

runtests unless caller;
