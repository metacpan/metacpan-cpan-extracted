#!perl

use Test::Spec;
use Test::Deep;
use Test::Exception;
use Monorail::MigrationScript;
use Path::Class;
use DBIx::Class::Schema;
use FindBin;

describe 'A monorail migrationscript object' => sub {
    my $sut;
    my $dbix;
    before each => sub {
        $dbix = DBIx::Class::Schema->connect(sub { DBI->connect('dbi:SQLite:dbname=:memory:') });
    };

    describe 'representing a valid migration' => sub {
        before each => sub {
            $sut = Monorail::MigrationScript->new(
                filename => file($FindBin::Bin, qw/test-data valid-migrations 0002_auto.pl/)->stringify,
                dbix     => $dbix,
            );
        };

        it 'is creatable' => sub {
            cmp_deeply($sut, isa('Monorail::MigrationScript'));
        };

        it 'has a name' => sub {
            is($sut->name, '0002_auto');
        };

        it 'pulls upgrade steps from the script' => sub {
            # this is a bit of an integraion test, as we're also checking that
            # the inner class is working correctly, but it's a good thing to test...
            cmp_deeply($sut->upgrade_steps, [
                all(
                    isa('Monorail::Change::AddField'),
                    methods(
                        table => 'album',
                        name  => 'producer',
                    ),
                )
            ]);
        };
    };

    describe 'representing a bad migration' => sub {
        it 'dies when the file is not valid perl' => sub {
            $sut = Monorail::MigrationScript->new(
                filename => file($FindBin::Bin, qw/test-data invalid-migrations syntax.pl/)->stringify,
                dbix     => $dbix
            );

            dies_ok {
                $sut->upgrade_steps;
            };
            like($@, qr/syntax/);
        };

        it 'dies when the migration class does not has a new method' => sub {
            $sut = Monorail::MigrationScript->new(
                filename => file($FindBin::Bin, qw/test-data invalid-migrations empty.pl/)->stringify,
                dbix     => $dbix
            );

            dies_ok {
                $sut->upgrade_steps;
            };
            like($@, qr/new/);
        };

        it 'dies when the migration class does not consume the migration role' => sub {
            $sut = Monorail::MigrationScript->new(
                filename => file($FindBin::Bin, qw/test-data invalid-migrations no_role.pl/)->stringify,
                dbix     => $dbix
            );

            dies_ok {
                $sut->upgrade_steps;
            };
            like($@, qr/Monorail::Role::Migration/);
        }
    }
};

runtests;
