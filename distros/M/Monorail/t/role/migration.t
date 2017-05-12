#!perl

use Test::Spec;
use DBI;
use DBD::SQLite;
use DBIx::Class::Schema;

{
    package My::Sut;

    use Moose;

    has upgrade_hook => (
        is  => 'ro',
        isa => 'CodeRef'
    );

    has downgrade_hook => (
        is  => 'ro',
        isa => 'CodeRef'
    );

    with 'Monorail::Role::Migration';

    sub dependencies {
        qw/epcot/
    }

    sub upgrade_steps {
        my ($self) = @_;

        return [
            Monorail::Change::RunPerl->new(function => $self->upgrade_hook)
        ];
    }

    sub downgrade_steps {
        my ($self) = @_;

        return [
            Monorail::Change::RunPerl->new(function => $self->downgrade_hook)
        ];
    }
}


describe 'The monorail migration role' => sub {
    my $dbix;
    before each => sub {
        $dbix = DBIx::Class::Schema->connect(sub {
            DBI->connect('dbi:SQLite:dbname=:memory:', undef, undef, { RaiseError => 1 })
        });
    };

    it 'requires the dependencies method' => sub {
        ok(Monorail::Role::Migration->meta->requires_method('dependencies'));
    };

    it 'requires the upgrade_steps method' => sub {
        ok(Monorail::Role::Migration->meta->requires_method('upgrade_steps'));
    };

    it 'requires the downgrade_steps method' => sub {
        ok(Monorail::Role::Migration->meta->requires_method('downgrade_steps'));
    };

    describe 'upgrade method' => sub {
        it 'calls transform_database on each of its change objects' => sub {
            my $called;
            my $sut = My::Sut->new(
                upgrade_hook => sub { $called++ },
                dbix         => $dbix,
            );

            $sut->upgrade('SQLite');

            ok($called);
        };

        it 'sets the db_type for the change objects' => sub {
            my $sut = My::Sut->new(
                upgrade_hook => sub {  },
                dbix         => $dbix,
            );

            my $db_type_called = Monorail::Change::RunPerl->expects('db_type')->once->with('SQLite');

            $sut->upgrade('SQLite');

            ok($db_type_called->verify);
        }
    };

    describe 'downgrade method' => sub {
        it 'calls transform_database on each of its change objects' => sub {
            my $called;
            my $sut = My::Sut->new(
                downgrade_hook => sub { $called++ },
                dbix           => $dbix,
            );

            $sut->downgrade('SQLite');

            ok($called);
        };

        it 'sets the db_type for the change objects' => sub {
            my $sut = My::Sut->new(
                downgrade_hook => sub {  },
                dbix           => $dbix,
            );

            my $db_type_called = Monorail::Change::RunPerl->expects('db_type')->once->with('SQLite');

            $sut->downgrade('SQLite');

            ok($db_type_called->verify);
        }
    };
};


runtests;
