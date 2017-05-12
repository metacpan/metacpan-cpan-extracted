#!perl

use Test::Spec;
use Test::Deep;
use SQL::Translator::Producer::Monorail;

describe 'The monorail sql translator producer' => sub {
    describe 'the create_table method' => sub {
        it 'should return a perl string for a CreateTable change' => sub {
            my $sqlt = SQL::Translator::Schema::Table->new(
                name => 'epcot'
            );

            $sqlt->add_field(
                name           => 'ride',
                data_type      => 'text',
                is_nullable    => 0,
                is_primary_key => 1,
                is_unique      => 0,
                default_value  => undef,
                size           => [256],
            );

            my $perl = SQL::Translator::Producer::Monorail::create_table($sqlt);

            my $change = eval $perl;

            cmp_deeply($change, all(
                isa('Monorail::Change::CreateTable'),
                methods(
                    name => 'epcot',
                    fields => [{
                        name           => 'ride',
                        type           => 'text',
                        is_nullable    => 0,
                        is_primary_key => 1,
                        is_unique      => 0,
                        default_value  => undef,
                        size           => [256],
                    }],
                ),
            ));
        };
    };

    describe 'the create_view method' => sub {
        it 'should return a perl string for a CreateView change' => sub {
            my %args = (
                name   => 'epcot',
                fields => [qw/ride year_built/],
                sql    => q/select ride, year_built from rides where park='epcot'/,
            );

            my $sqlt = SQL::Translator::Schema::View->new(%args);

            my $perl = SQL::Translator::Producer::Monorail::create_view($sqlt);

            my $change = eval $perl;

            cmp_deeply($change, all(
                isa('Monorail::Change::CreateView'),
                methods(%args)
            ));
        };
    };

    describe 'the alter_create_constraint method' => sub {
        it 'should return a perl string for a CreateConstraint change' => sub {
            my $table = SQL::Translator::Schema::Table->new(
                name => 'epcot'
            );

            my $create = SQL::Translator::Schema::Constraint->new(
                table            => $table,
                name             => 'epcot_uniq_idx',
                type             => 'UNIQUE',
                field_names      => [qw/ride/],
                on_delete        => '',
                on_update        => '',
                match_type       => '',
                deferrable       => 0,
                reference_table  => '',
                reference_fields => undef,
            );


            my $perl = SQL::Translator::Producer::Monorail::alter_create_constraint($create);

            my $change = eval $perl;

            cmp_deeply($change, all(
                isa('Monorail::Change::CreateConstraint'),
                methods(
                    table       => 'epcot',
                    name        => 'epcot_uniq_idx',
                    type        => 'unique',
                    field_names => [qw/ride/],
                ),
            ));
        };
    };

    describe 'the alter_drop_constraint method' => sub {
        it 'should return a perl string for a DropConstraint change' => sub {
            my $table = SQL::Translator::Schema::Table->new(
                name => 'epcot'
            );

            my $create = SQL::Translator::Schema::Constraint->new(
                table            => $table,
                name             => 'epcot_uniq_idx',
                type             => 'UNIQUE',
                field_names      => [qw/ride/],
                on_delete        => '',
                on_update        => '',
                match_type       => '',
                deferrable       => 0,
                reference_table  => '',
                reference_fields => undef,
            );


            my $perl = SQL::Translator::Producer::Monorail::alter_drop_constraint($create);

            my $change = eval $perl;

            cmp_deeply($change, all(
                isa('Monorail::Change::DropConstraint'),
                methods(
                    table       => 'epcot',
                    name        => 'epcot_uniq_idx',
                    type        => 'unique',
                ),
            ));
        };
    };

    describe 'the alter_create_index method' => sub {
        it 'should return a perl string for a CreateIndex change' => sub {
            my $table = SQL::Translator::Schema::Table->new(
                name => 'epcot'
            );

            my $create = SQL::Translator::Schema::Index->new(
                table  => $table,
                name   => 'ride_idx',
                fields => [qw/ride/],
                type   => 'NORMAL',
            );

            my $perl = SQL::Translator::Producer::Monorail::alter_create_index($create);

            my $change = eval $perl;

            cmp_deeply($change, all(
                isa('Monorail::Change::CreateIndex'),
                methods(
                    table  => 'epcot',
                    name   => 'ride_idx',
                    fields => [qw/ride/],
                ),
            ));
        };
    };


    describe 'the add_field method' => sub {
        it 'should return a perl string for a AddField change' => sub {
            my $table = SQL::Translator::Schema::Table->new(
                name => 'epcot'
            );

            my $field = SQL::Translator::Schema::Field->new(
                table          => $table,
                name           => 'ride',
                data_type      => 'text',
                is_nullable    => 0,
                is_primary_key => 1,
                is_unique      => 0,
                default_value  => undef,
                size           => [256],
            );

            my $perl = SQL::Translator::Producer::Monorail::add_field($field);

            my $change = eval $perl;

            cmp_deeply($change, all(
                isa('Monorail::Change::AddField'),
                methods(
                    table          => 'epcot',
                    name           => 'ride',
                    type           => 'text',
                    is_nullable    => 0,
                    is_primary_key => 1,
                    is_unique      => 0,
                    default_value  => undef,
                    size           => [256],
                ),
            ));
        };
    };

    describe 'the alter_field method' => sub {
        it 'should return a perl string for a AlterField change' => sub {
            my $table = SQL::Translator::Schema::Table->new(
                name => 'epcot'
            );

            my $from = SQL::Translator::Schema::Field->new(
                table          => $table,
                name           => 'ride',
                data_type      => 'text',
                is_nullable    => 0,
                is_primary_key => 1,
                is_unique      => 0,
                default_value  => undef,
                size           => [256],
            );

            my $to = SQL::Translator::Schema::Field->new(
                table          => $table,
                name           => 'ride',
                data_type      => 'text',
                is_nullable    => 0,
                is_primary_key => 1,
                is_unique      => 0,
                default_value  => undef,
                size           => [512],
            );


            my $perl = SQL::Translator::Producer::Monorail::alter_field($from, $to);

            my $change = eval $perl;

            cmp_deeply($change, all(
                isa('Monorail::Change::AlterField'),
                methods(
                    table       => 'epcot',
                    has_changes => 1,
                    from        => superhashof({size => [256]}),
                    to          => superhashof({size => [512]}),
                ),
            ));
        };
    };

    describe 'the rename_field method' => sub {
        it 'should return a perl string for a AlterField change' => sub {
            my $table = SQL::Translator::Schema::Table->new(
                name => 'epcot'
            );

            my $from = SQL::Translator::Schema::Field->new(
                table          => $table,
                name           => 'ride',
                data_type      => 'text',
                is_nullable    => 0,
                is_primary_key => 1,
                is_unique      => 0,
                default_value  => undef,
                size           => [256],
            );

            my $to = SQL::Translator::Schema::Field->new(
                table          => $table,
                name           => 'attraction',
                data_type      => 'text',
                is_nullable    => 0,
                is_primary_key => 1,
                is_unique      => 0,
                default_value  => undef,
                size           => [256],
            );


            my $perl = SQL::Translator::Producer::Monorail::rename_field($from, $to);

            my $change = eval $perl;

            cmp_deeply($change, all(
                isa('Monorail::Change::AlterField'),
                methods(
                    table       => 'epcot',
                    has_changes => 1,
                    from        => superhashof({name => 'ride'}),
                    to          => superhashof({name => 'attraction'}),
                ),
            ));

            # make sure at least with postgres we make the right sql.
            $change->db_type('PostgreSQL');
            my ($alter) = $change->as_sql;

            like($alter, qr/ALTER TABLE epcot RENAME COLUMN ride TO attraction/i);
        };
    };


    describe 'the drop_field method' => sub {
        it 'should return a perl string for a DropField change' => sub {
            my $table = SQL::Translator::Schema::Table->new(
                name => 'epcot'
            );

            my $field = SQL::Translator::Schema::Field->new(
                table          => $table,
                name           => 'ride',
                data_type      => 'text',
                is_nullable    => 0,
                is_primary_key => 1,
                is_unique      => 0,
                default_value  => undef,
                size           => [256],
            );

            my $perl = SQL::Translator::Producer::Monorail::drop_field($field);

            my $change = eval $perl;

            cmp_deeply($change, all(
                isa('Monorail::Change::DropField'),
                methods(
                    table => 'epcot',
                    name  => 'ride',
                ),
            ));
        };
    };

    describe 'the drop_table method' => sub {
        it 'should return a perl string for a DropTable change' => sub {
            my $table = SQL::Translator::Schema::Table->new(
                name => 'epcot'
            );

            my $perl = SQL::Translator::Producer::Monorail::drop_table($table);

            my $change = eval $perl;

            cmp_deeply($change, all(
                isa('Monorail::Change::DropTable'),
                methods(
                    name => 'epcot',
                ),
            ));
        };
    };

    describe 'the drop_view method' => sub {
        it 'should return a perl string for a DropView change' => sub {
            my $view = SQL::Translator::Schema::View->new(
                name => 'epcot'
            );

            my $perl = SQL::Translator::Producer::Monorail::drop_view($view);

            my $change = eval $perl;

            cmp_deeply($change, all(
                isa('Monorail::Change::DropView'),
                methods(
                    name => 'epcot',
                ),
            ));
        };
    };


    describe 'the alter_view method' => sub {
        it 'should return a perl string for a AlterView change' => sub {
            my %args = (
                name   => 'epcot',
                fields => [qw/ride year_built/],
                sql    => q/select ride, year_built from rides where park='epcot'/,
            );

            my $sqlt = SQL::Translator::Schema::View->new(%args);

            my $perl = SQL::Translator::Producer::Monorail::alter_view($sqlt);

            my $change = eval $perl;

            cmp_deeply($change, all(
                isa('Monorail::Change::AlterView'),
                methods(%args)
            ));
        };
    };

    describe 'the produce method' => sub {
        it 'should return a perl string that represents the given schema' => sub {
            my $table = SQL::Translator::Schema::Table->new(
                name => 'epcot'
            );

            $table->add_field(
                name           => 'ride',
                data_type      => 'text',
                is_nullable    => 0,
                is_primary_key => 1,
                is_unique      => 0,
                default_value  => undef,
                size           => [256],
            );

            $table->add_constraint(
                name             => 'epcot_uniq_idx',
                type             => 'UNIQUE',
                field_names      => [qw/ride/],
                on_delete        => '',
                on_update        => '',
                match_type       => '',
                deferrable       => 0,
                reference_table  => '',
                reference_fields => undef,
            );

            $table->add_index(
                name   => 'ride_idx',
                fields => [qw/ride/],
                type   => 'NORMAL',
            );

            my $schema = SQL::Translator::Schema->new();
            $schema->add_table($table);

            my $trans = stub(schema => $schema);

            my @perl_strings = SQL::Translator::Producer::Monorail::produce($trans);
            my @changes = map { eval $_ } @perl_strings;

            cmp_deeply(\@changes,
                [
                    all(
                        isa('Monorail::Change::CreateTable'),
                        methods(
                            name => 'epcot',
                            fields => [
                                superhashof({
                                    name => 'ride',
                                    type => 'text'
                                })
                            ],
                        ),
                    ),
                    all(
                        isa('Monorail::Change::CreateConstraint'),
                        methods(
                            name => 'epcot_uniq_idx',
                        ),
                    ),
                    all(
                        isa('Monorail::Change::CreateIndex'),
                        methods(
                            name => 'ride_idx',
                        ),
                    ),
                ]
            );
        };
    };
};

runtests;
