#!perl

use Test::Spec;
use Test::Deep;
use Monorail::Change::CreateTable;

describe 'An create table change' => sub {
    my $sut;
    my %sut_args;
    before each => sub {
        %sut_args = (
            name => 'epcot',
            fields => [
                {
                    name           => 'id',
                    type           => 'integer',
                    is_nullable    => 0,
                    is_primary_key => 1,
                    is_unique      => 0,
                    default_value  => undef,
                    size           => [16],
                },
            ],
        );
        $sut = Monorail::Change::CreateTable->new(%sut_args);
        $sut->db_type('PostgreSQL');
    };

    it 'produces valid sql' => sub {
        my @sql = $sut->as_sql;
        like($sql[0], qr/CREATE TABLE epcot\s+\(\s+id/si);
    };

    it 'produces valid perl' => sub {
        my $perl = $sut->as_perl;

        my $new = eval $perl;
        cmp_deeply($new, all(
            isa('Monorail::Change::CreateTable'),
            methods(%sut_args),
        ));
    };

    it 'transforms a schema' => sub {
        my $schema = SQL::Translator::Schema->new;
        $sut->transform_schema($schema);

        cmp_deeply(
            $schema->get_table($sut_args{name}),
            methods(
                name       => 'epcot',
                get_fields => [
                    methods(
                        name           => 'id',
                        data_type      => 'integer',
                        is_nullable    => 0,
                        is_primary_key => 1,
                        is_unique      => 0,
                        default_value  => undef,
                    ),
                ],
            )
        );
    };
};

runtests;
