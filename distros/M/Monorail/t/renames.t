#!perl

use Test::Spec;
use Test::Deep;
use FindBin;
use lib "$FindBin::Bin/test-data/renames/lib";
use Monorail;
use My::Schema;
use Path::Class;

# this is a bit of an integration test.  We could have built up SQL::Trans
# schema objects if we wanted something that was a true unit test, but this is
# nice to have.

describe 'A logical rename change' => sub {
    my $sut;

    before each => sub {
        my $dbix = My::Schema->connect(sub {
            DBI->connect('dbi:SQLite:dbname=:memory:', undef, undef, { RaiseError => 1 })
        });

        $sut = Monorail->new(
            dbix    => $dbix,
            basedir => dir($FindBin::Bin, qw/test-data renames migrations/)->stringify,
            quiet   => 1,
        );
    };

    it 'builds a diff with the correct upgrade changes' => sub {
        my $diff = $sut->current_diff;
        my @changes = map { eval $_ } @{$diff->upgrade_changes};

        cmp_deeply(
            \@changes,
            [
                all(
                    isa('Monorail::Change::RenameTable'),
                    methods(
                        from => 'cd',
                        to   => 'album'
                    ),
                ),
                all(
                    isa('Monorail::Change::AlterField'),
                    methods(
                        from => superhashof({name => 'released'}),
                        to   => superhashof({name => 'release_year'})
                    ),
                ),
            ]
        );
    };

    it 'builds a diff with the correct downgrade changes' => sub {
        my $diff = $sut->current_diff;
        my @changes = map { eval $_ } @{$diff->downgrade_changes};
        cmp_deeply(
            \@changes,
            [
                all(
                    isa('Monorail::Change::RenameTable'),
                    methods(
                        to   => 'cd',
                        from => 'album'
                    ),
                ),
                all(
                    isa('Monorail::Change::AlterField'),
                    methods(
                        to   => superhashof({name => 'released'}),
                        from => superhashof({name => 'release_year'})
                    ),
                )
            ]
        );
    };
};

runtests;
