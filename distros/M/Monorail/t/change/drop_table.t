#!perl

use Test::Spec;
use Test::Deep;
use Monorail::Change::DropTable;

describe 'A drop table change' => sub {
    my $sut;
    my %sut_args;
    before each => sub {
        %sut_args = (
            name => 'epcot',
        );
        $sut = Monorail::Change::DropTable->new(%sut_args);
        $sut->db_type('PostgreSQL');
    };

    it 'produces valid sql' => sub {
        like($sut->as_sql, qr/DROP TABLE epcot/i);
    };

    it 'produces valid perl' => sub {
        my $perl = $sut->as_perl;

        my $new = eval $perl;
        cmp_deeply($new, all(
            isa('Monorail::Change::DropTable'),
            methods(%sut_args),
        ));
    };

    it 'transforms a schema' => sub {
        my $schema = SQL::Translator::Schema->new();
        $schema->add_table(name => 'epcot');

        $sut->transform_schema($schema);

        my @tables = $schema->get_tables;
        cmp_deeply(\@tables, []);
    };
};

runtests;
