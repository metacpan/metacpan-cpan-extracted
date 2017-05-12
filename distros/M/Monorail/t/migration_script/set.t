#!perl

use Test::Spec;
use FindBin;
use Monorail::MigrationScript::Set;
use DBIx::Class::Schema;
use Path::Class;
use Test::Deep;

describe 'A monorail migrationscript set' => sub {
    my ($sut);
    before each => sub {
        $sut    = Monorail::MigrationScript::Set->new(
            basedir => dir($FindBin::Bin, '..', 'test-data', 'valid-migrations')->stringify,
            dbix    => DBIx::Class::Schema->connect(sub { DBI->connect('dbi:SQLite:dbname=:memory:') })
        )
    };

    it 'has two migrations' => sub {
        cmp_deeply($sut->migrations, {
            '0001_auto' => all(isa('Monorail::MigrationScript'), methods(name => '0001_auto')),
            '0002_auto' => all(isa('Monorail::MigrationScript'), methods(name => '0002_auto')),
        });
    };

    describe 'graph' => sub {
        it 'exists' => sub {
            cmp_deeply($sut->graph, isa('Graph'));
        };

        it 'contains all the migrations' => sub {
            cmp_deeply([$sut->graph->vertices], bag(qw/0001_auto 0002_auto/));
        };

        it 'represents dependencies' => sub {
            cmp_deeply([$sut->graph->edges], [
                [qw/0001_auto 0002_auto/],
            ]);
        }
    };

    describe 'the in_topological_order method' => sub {
        it 'returns the MigrationScript objects in the right order' => sub {
            cmp_deeply([$sut->in_topological_order], [
                all(isa('Monorail::MigrationScript'), methods(name => '0001_auto')),
                all(isa('Monorail::MigrationScript'), methods(name => '0002_auto')),
            ]);
        };
    };

    describe 'the current_dependencies method' => sub {
        it 'returns just the later migration' => sub {
            cmp_deeply([$sut->current_dependencies], [
                all(isa('Monorail::MigrationScript'), methods(name => '0002_auto')),
            ]);
        };
    };

    describe 'the next_auto_name method' => sub {
        it 'returns a logical name for the next migration' => sub {
            is($sut->next_auto_name, '0003_auto');
        };
    };

    describe 'the get method' => sub {
        it 'returns the migration script object that matches the given name' => sub {
            cmp_deeply($sut->get('0001_auto'), all(
                isa('Monorail::MigrationScript'),
                methods(name => '0001_auto'),
            ));
        };

        it 'returns undef if the name does not exist in the set' => sub {
            cmp_deeply($sut->get('no-such-thing'), undef);
        };
    };
};

runtests;
