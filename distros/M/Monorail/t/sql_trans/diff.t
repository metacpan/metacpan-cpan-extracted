#!perl

use Test::Spec;
use Test::Deep;
use Monorail::SQLTrans::Diff;
use SQL::Translator::Schema;

describe 'A monorail sqltrans diff object' => sub {
    it 'extends SQL::Translator::Diff' => sub {
        my $sut = Monorail::SQLTrans::Diff->new;
        cmp_deeply($sut, isa('SQL::Translator::Diff'));
    };
    it 'shows no differences when the schemas are the same' => sub {
        my $sut = Monorail::SQLTrans::Diff->new({
            output_db              => 'Monorail',
            source_schema          => SQL::Translator::Schema->new(),
            target_schema          => SQL::Translator::Schema->new(),
        });

        $sut->compute_differences;
        my @out = grep { !m/^--/ && m/\S/ }$sut->produce_diff_sql;

        ok(!@out);
    };
};

runtests;
