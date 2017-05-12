#!perl

use Test::Spec;
use Test::Deep;
use Monorail::Change::CreateConstraint;
use Monorail::Change::CreateTable;

describe 'An create constraint change' => sub {
    my $sut;
    my %sut_args;
    describe 'for a unique constraint' => sub {
        before each => sub {
            %sut_args = (
                table       => 'epcot',
                name        => 'uniq_epcot_name_idx',
                type        => 'unique',
                field_names => [qw/name/],
            );
            $sut = Monorail::Change::CreateConstraint->new(%sut_args);
            $sut->db_type('PostgreSQL');
        };

        it 'produces valid sql' => sub {
            like($sut->as_sql, qr/ALTER TABLE epcot ADD CONSTRAINT uniq_epcot_name_idx UNIQUE \(name\)/i);
        };

        it 'produces valid perl' => sub {
            my $perl = $sut->as_perl;
            my $new = eval $perl;

            cmp_deeply($new, all(
                isa('Monorail::Change::CreateConstraint'),
                methods(%sut_args),
            ));
        };

        it 'transforms a schema' => sub {
            my $schema = SQL::Translator::Schema->new;
            $schema->add_table(name => 'epcot')->add_field(
                name           => 'name',
                data_type      => 'text',
                is_nullable    => 1,
                is_primary_key => 1,
                is_unique      => 0,
                default_value  => undef,
            );

            $sut->transform_schema($schema);

            my ($const) = $schema->get_table('epcot')->get_constraints;
            cmp_deeply(
                $const,
                methods(
                    name        => 'uniq_epcot_name_idx',
                    type        => 'UNIQUE',
                    field_names => [qw/name/],
                )
            );
        };
    };

    describe 'for a foreign key constraint' => sub {
        before each => sub {
            %sut_args = (
                field_names      => ['album_id'],
                on_delete        => 'CASCADE',
                deferrable       => 1,
                type             => 'foreign key',
                table            => 'track',
                name             => 'track_fk_album_id',
                match_type       => '',
                on_update        => 'CASCADE',
                reference_table  => 'album',
                reference_fields => ['id'],
            );
            $sut = Monorail::Change::CreateConstraint->new(%sut_args);
            $sut->db_type('PostgreSQL');
        };

        it 'produces valid sql' => sub {
            like($sut->as_sql, qr/ALTER TABLE track ADD CONSTRAINT track_fk_album_id FOREIGN KEY \(album_id\)\s+REFERENCES album \(id\) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE/i);
        };

        it 'produces valid perl' => sub {
            my $perl = $sut->as_perl;
            my $new  = eval $perl;

            cmp_deeply($new, all(
                isa('Monorail::Change::CreateConstraint'),
                methods(%sut_args),
            ));
        };

        it 'transforms a schema' => sub {
            my $schema = SQL::Translator::Schema->new;
            $schema->add_table(name => 'track')->add_field(
                name           => 'album_id',
                data_type      => 'interger',
                is_nullable    => 1,
                is_primary_key => 1,
                is_unique      => 0,
                default_value  => undef,
            );
            $schema->add_table(name => 'album')->add_field(
                name           => 'id',
                type           => 'interger',
                is_nullable    => 1,
                is_primary_key => 1,
                is_unique      => 0,
                default_value  => undef,
            );

            $sut->transform_schema($schema);

            my ($const) = $schema->get_table('track')->get_constraints;
            cmp_deeply(
                $const,
                methods(
                    field_names      => ['album_id'],
                    on_delete        => 'CASCADE',
                    deferrable       => 1,
                    type             => 'FOREIGN KEY',
                    name             => 'track_fk_album_id',
                    match_type       => '',
                    on_update        => 'CASCADE',
                    reference_table  => 'album',
                    reference_fields => ['id'],
                )
            )
        };
    };
};

runtests;
