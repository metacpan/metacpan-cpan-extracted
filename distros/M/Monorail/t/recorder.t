#!perl

use Test::Spec;
use Test::Exception;
use Test::Deep;

use DBIx::Class;
use Monorail::Recorder;

{
    package Fake::Table;

    use strict;
    use warnings;
    use parent 'DBIx::Class';

    __PACKAGE__->load_components("Core");
    __PACKAGE__->table('fake_table');

    __PACKAGE__->add_columns (
        id => {
            data_type         => 'int',
            is_auto_increment => 1,
        },
    );

    __PACKAGE__->set_primary_key('id');
}

describe 'A monorail recorder' => sub {
    my ($dbix, $dbh, $sut);

    before each => sub {
        $dbh    = DBI->connect('dbi:SQLite:dbname=:memory:', undef, undef, { RaiseError => 1, PrintError => 0 });
        $dbix   = DBIx::Class::Schema->connect(sub { $dbh });
        $dbix->register_class(fake_table => 'Fake::Table');

        $sut    = Monorail::Recorder->new(dbix => $dbix);
    };

    it 'makes the migration table if needed' => sub {
        dies_ok {
            $dbh->do("SELECT * FROM $Monorail::Recorder::TableName");
        };

        $sut->is_applied('epcot');

        lives_ok {
            $dbh->do("SELECT * FROM $Monorail::Recorder::TableName");
        };
    };

    it 'gives the state of a given migration' => sub {
        ok(!$sut->is_applied('epcot'));

        $dbh->do("INSERT INTO $Monorail::Recorder::TableName (name) VALUES ('epcot')");
        ok($sut->is_applied('epcot'));
    };

    it 'marks a migration as applied' => sub {
        $sut->mark_as_applied('epcot');

        my $row = $dbh->selectrow_hashref("SELECT * FROM $Monorail::Recorder::TableName where name=?", undef, 'epcot');

        cmp_deeply($row, {id => ignore, name => 'epcot'});
    };

    describe 'the protodbix method' => sub {
        it 'starts with a dbix that has a model' => sub {
            cmp_deeply($sut->dbix->source('fake_table'), isa('DBIx::Class::ResultSource'));
        };

        it 'returns a dbix with just the recorder models' => sub {
            cmp_deeply(
                [$sut->protodbix->sources],
                ['__monorail_migrations'],
            );
        };

        it 'returns a dbix with the database handle' => sub {
            cmp_ok($sut->protodbix->storage->dbh, '==', $sut->dbix->storage->dbh);
        };
    };
};

runtests;
