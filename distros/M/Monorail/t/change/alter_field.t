#!perl

use Test::Spec;
use Test::Deep;
use Monorail::Change::AlterField;
use Monorail::Change::CreateTable;

describe 'An alter field change' => sub {
    my $sut;
    my %sut_args;
    before each => sub {
        %sut_args = (
            table => 'epcot',
            from  => {
                name           => 'description',
                type           => 'TEXT',
                is_nullable    => 1,
                is_primary_key => 0,
                is_unique      => 0,
                default_value  => undef,
                size           => 10,
            },
            to  => {
                name           => 'description',
                type           => 'TEXT',
                is_nullable    => 0,
                is_primary_key => 0,
                is_unique      => 0,
                default_value  => undef,
                size           => 10,
            },
        );
        $sut = Monorail::Change::AlterField->new(%sut_args);
        $sut->db_type('PostgreSQL');
    };

    it 'produces valid sql' => sub {
        like($sut->as_sql, qr/ALTER TABLE epcot ALTER COLUMN description SET NOT NULL/i);
    };

    it 'produces valid perl' => sub {
        my $perl = $sut->as_perl;

        my $new = eval $perl;
        cmp_deeply($new, all(
            isa('Monorail::Change::AlterField'),
            methods(%sut_args),
        ));
    };


    it 'transforms a schema' => sub {
        my $schema = SQL::Translator::Schema->new;

        my $table = SQL::Translator::Schema::Table->new(name => 'epcot');
        $table->add_field(%{$sut_args{from}});
        $schema->add_table($table);

        $sut->transform_schema($schema);

        cmp_deeply(
            $schema->get_table('epcot')->get_field('description'),
            methods(
                is_nullable => 0
            )
        );
    };

    describe 'has_changes method' => sub {
        before each => sub {
            %sut_args = (
                table => 'epcot',
                from  => {
                    name           => 'description',
                    type           => 'TEXT',
                    is_nullable    => 1,
                    is_primary_key => 0,
                    is_unique      => 0,
                    default_value  => undef,
                    size           => [10],
                },
                to  => {
                    name           => 'description',
                    type           => 'TEXT',
                    is_nullable    => 1,
                    is_primary_key => 0,
                    is_unique      => 0,
                    default_value  => undef,
                    size           => [10],
                },
            );
            $sut = Monorail::Change::AlterField->new(%sut_args);
            $sut->db_type('PostgreSQL');
        };
        it 'is false when from and to are the same' => sub {
            ok(!$sut->has_changes);
        };
        it 'is true when from and to have different names' => sub {
            $sut->to->{name} = 'desc';
            ok($sut->has_changes);
        };
        it 'is true when from and to have different types' => sub {
            $sut->from->{type} = 'text varying';
            ok($sut->has_changes);
        };
        it 'is true when the is_nullable attribute changes' => sub {
            $sut->to->{is_nullable} = 0;
            ok($sut->has_changes);
        };
        it 'is true when the is_primary_key attribute changes' => sub {
            $sut->to->{is_primary_key} = 1;
            ok($sut->has_changes);
        };
        it 'is true when the is_unique attribute changes' => sub {
            $sut->to->{is_unique} = 1;
            ok($sut->has_changes);
        };
        it 'is true when the size attribute changes' => sub {
            $sut->to->{size} = [20];
            ok($sut->has_changes);
        };
    };
};

runtests;
