#!perl

use Test::Spec;
use Monorail::Diff;
use SQL::Translator::Schema;

describe 'A sql translator differ' => sub {
    my $sut;

    before each => sub {
        my $s1 = SQL::Translator::Schema->new();
        my $s2 = SQL::Translator::Schema->new();

        $s2->add_table(name => 'epcot');

        $sut = Monorail::Diff->new(
            source_schema  => $s1,
            target_schema  => $s2,
        );
    };


    describe 'reverse diff method' => sub {
        it 'drops a table instead of adding a table' => sub {
            my $rdiff    = $sut->reversed_diff;
            my ($change) = grep { m/^Monorail/ } $rdiff->produce_diff_sql;

            ok(
                $change =~ m/Monorail::Change::DropTable/s
                    &&
                $change =~ m/name => ['"]epcot['"]/s
            );
        };
    };

    describe 'upgrade_changes method' => sub {
        it 'returns a list of perl strings representing the changes' => sub {
            cmp_deeply($sut->upgrade_changes, [
                all(
                    re(qr/Monorail::Change::CreateTable/),
                    re(qr/name => ['"]epcot['"]/s)
                )
            ]);
        };
    };

    describe 'downgrade_changes method' => sub {
        it 'returns a list of perl strings representing the changes' => sub {
            cmp_deeply($sut->downgrade_changes, [
                all(
                    re(qr/Monorail::Change::DropTable/),
                    re(qr/name => ['"]epcot['"]/s)
                )
            ]);
        };
    };

    describe 'has_changes method' => sub {
        it 'returns true when the diff object contains changes' => sub {
            ok($sut->has_changes);
        };

        it 'returns false when the diff object contains no changes' => sub {
            $sut = Monorail::Diff->new(
                source_schema => SQL::Translator::Schema->new(),
                target_schema => SQL::Translator::Schema->new(),
            );

            ok(!$sut->has_changes);
        };
    };
};

runtests;
