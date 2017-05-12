#!perl

use Test::Spec;
use Test::Deep;
use Monorail::Change::CreateIndex;
use Monorail::Change::CreateTable;

describe 'An add field change' => sub {
    my $sut;
    my %sut_args;
    before each => sub {
        %sut_args = (
            table   => 'epcot',
            name    => 'ride_idx',
            fields  => ['ride'],
            type    => 'normal',
            options => [],
        );
        $sut = Monorail::Change::CreateIndex->new(%sut_args);
        $sut->db_type('PostgreSQL');
    };

    it 'produces valid sql' => sub {
        like($sut->as_sql, qr/CREATE INDEX ride_idx on epcot \(ride\)/i);
    };

    it 'produces valid perl' => sub {
        my $perl = $sut->as_perl;

        my $new = eval $perl;
        cmp_deeply($new, all(
            isa('Monorail::Change::CreateIndex'),
            methods(%sut_args),
        ));
    };

    it 'transforms a schema' => sub {
        my $schema = SQL::Translator::Schema->new;
        $schema->add_table(name => 'epcot')->add_field(
            name           => 'ride',
            data_type      => 'text',
            is_nullable    => 1,
            is_primary_key => 0,
            is_unique      => 0,
            default_value  => undef,
        );

        $sut->transform_schema($schema);

        my ($index) = $schema->get_table('epcot')->get_indices;
        cmp_deeply(
            $index,
            methods(
                type => 'NORMAL',
                name => 'ride_idx',
                fields => [qw/ride/],
            )
        );
    };
};

runtests;
