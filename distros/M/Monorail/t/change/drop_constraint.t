#!perl

use Test::Spec;
use Test::Deep;
use Monorail::Change::DropConstraint;
use Monorail::Change::CreateConstraint;
use Monorail::Change::CreateTable;

describe 'An add field change' => sub {
    my $sut;
    my %sut_args;
    before each => sub {
        %sut_args = (
            table       => 'epcot',
            name        => 'uniq_epcot_name_idx',
            type        => 'unique',
            field_names => [qw/name/],
        );
        $sut = Monorail::Change::DropConstraint->new(%sut_args);
        $sut->db_type('PostgreSQL');
    };

    it 'produces valid sql' => sub {
        like($sut->as_sql, qr/ALTER TABLE epcot DROP CONSTRAINT uniq_epcot_name_idx/i);
    };

    it 'produces valid perl' => sub {
        my $perl = $sut->as_perl;

        my $new = eval $perl;
        cmp_deeply($new, all(
            isa('Monorail::Change::DropConstraint'),
            methods(%sut_args),
        ));
    };

    it 'transforms a schema' => sub {
        my $schema = SQL::Translator::Schema->new;
        my $table = $schema->add_table(name => 'epcot');

        $table->add_field(
            name           => 'name',
            data_type      => 'text',
            is_nullable    => 0,
            is_primary_key => 1,
            is_unique      => 0,
            default_value  => undef,
        );
        $table->add_constraint(
            name        => 'uniq_epcot_name_idx',
            type        => 'unique',
            field_names => [qw/name/],
        );

        $sut->transform_schema($schema);

        my ($uniq) = $schema->get_table('epcot')->get_constraints;

        cmp_deeply($uniq, undef);

    };
};

runtests;
