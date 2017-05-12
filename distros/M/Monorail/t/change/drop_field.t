#!perl

use Test::Spec;
use Test::Deep;
use Monorail::Change::DropField;
use Monorail::Change::CreateTable;

describe 'An add field change' => sub {
    my $sut;
    my %sut_args;
    before each => sub {
        %sut_args = (
            table          => 'epcot',
            name           => 'description',
        );
        $sut = Monorail::Change::DropField->new(%sut_args);
        $sut->db_type('PostgreSQL');
    };

    it 'produces valid sql' => sub {
        like($sut->as_sql, qr/ALTER TABLE epcot DROP COLUMN description/i);
    };

    it 'produces valid perl' => sub {
        my $perl = $sut->as_perl;

        my $new = eval $perl;
        cmp_deeply($new, all(
            isa('Monorail::Change::DropField'),
            methods(%sut_args),
        ));
    };

    it 'transforms a schema' => sub {
        my $schema = SQL::Translator::Schema->new;
        $schema->add_table(name => 'epcot')->add_field(
            name           => 'description',
            type           => 'text',
            is_nullable    => 0,
            is_primary_key => 1,
            is_unique      => 0,
            default_value  => undef,
        );

        $sut->transform_schema($schema);

        cmp_deeply($schema->get_table('epcot')->get_field('description'), undef);
    };
};

runtests;
