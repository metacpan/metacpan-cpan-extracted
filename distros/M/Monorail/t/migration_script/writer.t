#!perl

use Test::Spec;

use Monorail::MigrationScript::Writer;
use Monorail::Diff;

use SQL::Translator::Schema;
use Test::Deep;

describe "A monorail migration script writer" => sub {
    my ($diff, $sut, $output);

    before each => sub {
        my $s1 = SQL::Translator::Schema->new();
        my $s2 = SQL::Translator::Schema->new();

        $s2->add_table(name => 'epcot');

        open(my $output_fh, ">", \$output);

        my $diff = Monorail::Diff->new(
            source_schema  => $s1,
            target_schema  => $s2,
        );

        $sut = Monorail::MigrationScript::Writer->new(
            diff           => $diff,
            name           => 'wdw',
            basedir        => '/tmp', # not used in this test
            dependencies   => [qw/dlr mk/],
            out_filehandle => $output_fh,
        );
    };


    describe 'write file method' => sub {
        my $eval_error;
        # before all because we don't want to compile in the same namespace over
        # and over
        before all => sub {
            $sut->write_file;
            eval "package monorail_writer_test; $output";
            $eval_error = $@;
        };

        it 'is valid perl' => sub {
            ok(!$eval_error);
        };

        it 'pulls in the Monorail::Role::Migration role' => sub {
            ok(monorail_writer_test->meta->does_role('Monorail::Role::Migration'));
        };

        it 'records the dependencies given to the writer' => sub {
            cmp_deeply(monorail_writer_test->dependencies, bag(qw/dlr mk/));
        };

        it 'records the upgrade steps from the diff' => sub {
            cmp_deeply(monorail_writer_test->upgrade_steps, [
                all(
                    isa('Monorail::Change::CreateTable'),
                    methods(name => 'epcot')
                )
            ]);
        };

        it 'records the downgrade steps from the diff' => sub {
            cmp_deeply(monorail_writer_test->downgrade_steps, [
                all(
                    isa('Monorail::Change::DropTable'),
                    methods(name => 'epcot')
                )
            ]);
        };
    };
};

runtests;
