#!perl

use Test::Spec;
use Test::Deep;
use Test::Exception;

use Monorail;
use Path::Class;
use FindBin;
use lib "$FindBin::Bin/test-data/dbix-schema";
use My::Schema;

describe 'A monorail object' => sub {
    my ($sut);

    before each => sub {
        my $dbix = My::Schema->connect(sub {
            DBI->connect('dbi:SQLite:dbname=:memory:', undef, undef, { RaiseError => 1 })
        });

        $sut = Monorail->new(
            dbix    => $dbix,
            basedir => dir($FindBin::Bin, qw/test-data valid-migrations/)->stringify,
            quiet   => 1,
        );
    };

    describe 'all_migrations method' => sub {
        it 'returns a migration script set with the correct basedir' => sub {
            is($sut->all_migrations->basedir, $sut->basedir);
        };

        it 'returns a migration script set with the correct dbix' => sub {
            cmp_ok($sut->all_migrations->dbix, '==', $sut->dbix);
        }
    };

    describe 'recorder method' => sub {
        it 'returns a recorder object with the correct dbix' => sub {
            cmp_ok($sut->recorder->dbix, '==', $sut->dbix);
        };
    };

    describe 'the make_migration method' => sub {
        it 'makes a writer with the right name, basedir and depends' => sub {
            Monorail::MigrationScript::Writer->expects('new')->returns(sub {
                my ($class, %args) = @_;

                cmp_deeply(\%args, {
                    name          => '0003_auto',
                    basedir       => $sut->basedir,
                    diff          => ignore(),
                    dependencies  => [qw/0002_auto/]
                });

                return stub(write_file => 1);
            });

            $sut->make_migration();
        };

        it 'passes a given name along to the writer' => sub {
            Monorail::MigrationScript::Writer->expects('new')->returns(sub {
                my ($class, %args) = @_;

                cmp_deeply(\%args, superhashof{
                    name => 'epcot',
                });

                return stub(write_file => 1);
            });

            $sut->make_migration('epcot');
        };

        it 'calls write_file on the script writer' => sub {
            my $write_file_call = Monorail::MigrationScript::Writer->expects('write_file')->returns(1);
            $sut->make_migration;
            ok($write_file_call->verify);
        };

        it 'builds a writer with the needed upwards change' => sub {
            Monorail::MigrationScript::Writer->expects('write_file')->returns(sub {
                my ($self)  = @_;
                my @changes = map { eval $_ } @{$self->diff->upgrade_changes};

                cmp_deeply(\@changes, [
                    all(
                        isa('Monorail::Change::AddField'),
                        methods(
                            table => 'album',
                            name  => 'engineer',
                        ),
                    )
                ]);

                return 1;
            });

            $sut->make_migration;
        };
    };

    # we're going to do a little bit of integration testing here.
    describe 'the migrate method' => sub {
        it 'sets up the schema in the database' => sub {
            $sut->migrate;

            my $dbh = $sut->dbix->storage->dbh;
            my @sql = grep { defined } @{$dbh->selectcol_arrayref('select sql from sqlite_master')};

            cmp_deeply(\@sql, superbagof(
                re(qr/create table monorail_deployed_migrations/i),
                re(qr/create table album/i),
            ));
        };

        it 'marks the migraions as applied' => sub {
            $sut->migrate;

            my $dbh = $sut->dbix->storage->dbh;

            my $applied = $dbh->selectcol_arrayref('select name from monorail_deployed_migrations');

            cmp_deeply($applied, bag(qw/0001_auto 0002_auto/))
        };

        it 'does nothing the second time it is called in the same state' => sub {
            $sut->migrate;

            my $not_applied = Monorail::Recorder->expects('mark_as_applied')->never;

            $sut->migrate;

            ok($not_applied->verify);
        };
    };

    describe 'the showmigrations method' => sub {
        my $out;

        before each => sub {
            $out = '';
            $sut->expects('_out')->at_least_once->returns(sub {
                my ($self, $fmt, @args) = @_;

                $out .= sprintf($fmt, @args);
            });
        };

        it 'displays none applied when none are' => sub {
            $sut->showmigrations;
            like($out, qr/^0001_auto$/sm);
            like($out, qr/^0002_auto$/sm);
        };

        it 'displays all applied when all are' => sub {
            $sut->migrate;
            $out = '';
            $sut->showmigrations;
            like($out, qr/^0001_auto \[X\]$/sm);
            like($out, qr/^0002_auto \[X\]$/sm);
        };
    };

    describe 'the showmigrationplan method' => sub {
        my $out;

        before each => sub {
            $out = '';
            $sut->expects('_out')->at_least_once->returns(sub {
                my ($self, $fmt, @args) = @_;

                $out .= sprintf($fmt, @args);
            });
        };

        it 'displays all when none are applied' => sub {
            $sut->showmigrationplan;
            like($out, qr/^0001_auto$/sm);
            like($out, qr/^0002_auto$/sm);
        };

        it 'displays none applied when all are' => sub {
            $sut->migrate;
            $out = '';
            $sut->showmigrationplan;

            is($out, '');
        };
    };

    describe 'the sqlmigrate method' => sub {
        my $out;

        before each => sub {
            $out = '';
            $sut->expects('_out')->at_least_once->returns(sub {
                my ($self, $fmt, @args) = @_;

                $out .= sprintf($fmt, @args);
            });
        };

        it 'show the sql for the given migration' => sub {
            $sut->sqlmigrate('0002_auto');
            like($out, qr/ALTER TABLE album ADD COLUMN producer text/);
        };
    };


    describe 'The detect db type role db_type method' => sub {
        my ($dbix, $type);
        before each => sub {
            $sut->dbix->stubs(storage => stub(
                dbh => sub {
                    return {Driver => {Name => $type}}
                }
            ));
        };

        it 'translates postgresql correctly' => sub {
            $type = 'Pg';

            is($sut->db_type, 'PostgreSQL');
        };

        it 'translates mysql correctly' => sub {
            $type = 'mysql';

            is($sut->db_type, 'MySQL');
        };

        it 'translates Oracle correctly' => sub {
            $type = 'Oracle';

            is($sut->db_type, 'Oracle');
        };

        it 'translates SQLite correctly' => sub {
            $type = 'SQLite';

            is($sut->db_type, 'SQLite');
        };

        it 'dies on unknown database types' => sub {
            $type = 'epcot';

            dies_ok {
                $sut->db_type;
            };
        }
    };
};


runtests;
