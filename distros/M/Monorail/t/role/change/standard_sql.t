#!perl

use Test::Spec;
use Test::Deep;

{
    package My::Sut;

    use Moose;

    has name => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
    );

    has table => (
        is       => 'ro',
        isa      => 'Str',
        required => 0,
    );

    has attr => (
        is       => 'ro',
        isa      => 'Str',
        required => 0,
    );

    with 'Monorail::Role::Change::StandardSQL';

    sub as_hashref_keys {
        return qw/name table attr/;
    }

    sub transform_schema {
        return;
    }

    sub as_sql {
        return (
            'SELECT * FROM vacation',
            'SELECT * FROM trips',
        );
    }
}


describe 'The standard sql change role' => sub {
    my ($sut);

    before each => sub {
        $sut = My::Sut->new(name => 'epcot', table => 'mk', attr => 'dhs');
    };

    it 'requires an as_sql method' => sub {
        ok(Monorail::Role::Change::StandardSQL->meta->requires_method('as_sql'));
    };

    it 'consumes the change role' => sub {
        ok(Monorail::Role::Change::StandardSQL->meta->does_role('Monorail::Role::Change'));
    };

    describe 'schema_table_object method' => sub {
        it 'returns a sql trans table object' => sub {
            my $sqlt = $sut->schema_table_object;

            cmp_deeply($sqlt, all(
                isa('SQL::Translator::Schema::Table'),
                methods(name => 'mk'),
            ));
        };
    };

    describe 'producer method' => sub {
        it 'returns a producer proxy object' => sub {
            $sut->db_type('PostgreSQL');
            cmp_deeply($sut->producer, all(
                isa('Monorail::SQLTrans::ProducerProxy'),
                methods(db_type => $sut->db_type),
            ));
        };
    };

    describe 'transform_database method' => sub {
        it 'executes its sql on the given schema object' => sub {
            my $db_do = mock();
            my $dbix  = stub(storage => stub(dbh => $db_do));

            my @executed_sql;
            $db_do->expects('do')->exactly(2)->returns(sub {
                push(@executed_sql, $_[1]);
            });

            $sut->transform_database($dbix);

            cmp_deeply(\@executed_sql, [$sut->as_sql]);
        }
    };
};

runtests;
