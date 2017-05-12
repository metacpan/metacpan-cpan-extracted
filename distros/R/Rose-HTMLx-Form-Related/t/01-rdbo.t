#!/usr/bin/env perl
use strict;
use Test::More tests => 12;
use Data::Dump qw( dump );

SKIP: {

    eval "use Rose::DB::Object";
    if ($@) {
        skip "RDBO required to test RDBO driver", 12;
    }
    eval "use Rose::DBx::Object::MoreHelpers";
    if ($@) {
        skip "Rose::DBx::Object::MoreHelpers required to run RDBO tests", 12;
    }
    eval "use Rose::DBx::TestDB";
    if ($@) {
        skip "Rose::DBx::TestDB required to run RDBO tests", 12;
    }

    use_ok('Rose::HTMLx::Form::Related::RDBO');

    our $db = Rose::DBx::TestDB->new;

    # create a schema that tests out all our column types
    ok( $db->dbh->do(
            qq{
CREATE TABLE foo (
    id       integer primary key autoincrement,
    name     varchar(16),
    static   char(8),
    my_int   integer not null default 0,
    my_dec   float
    );
}
        ),
        "table foo created"
    );

    ok( $db->dbh->do(
            qq{
CREATE TABLE bar (
    id       integer primary key autoincrement,
    foo_id   integer not null
    );
}
        ),
        "table bar created"
    );

    {

        package My::Foo;
        @My::Foo::ISA
            = ( 'Rose::DBx::Object::MoreHelpers', 'Rose::DB::Object' );

        My::Foo->meta->setup(
            table   => 'foo',
            columns => [
                id     => { type => 'serial',    primary_key => 1 },
                name   => { type => 'varchar',   length      => 16 },
                static => { type => 'character', length      => 8, },
                my_int => { type => 'integer', not_null => 1, default => 0, },
                my_dec => { type => 'float' },
            ],
            unique_key    => 'name',
            relationships => [
                bars => {
                    type       => 'one to many',
                    class      => 'My::Bar',
                    column_map => { id => 'foo_id' },
                }
            ],
        );

        sub init_db {
            return $main::db;
        }
    }

    {

        package My::Bar;
        @My::Bar::ISA
            = ( 'Rose::DBx::Object::MoreHelpers', 'Rose::DB::Object' );

        My::Bar->meta->setup(
            table   => 'bar',
            columns => [
                id     => { type => 'serial',  primary_key => 1 },
                foo_id => { type => 'integer', not_null    => 1, },
            ],
            foreign_keys => [
                foo => {
                    class       => 'My::Foo',
                    key_columns => { foo_id => 'id' },
                }
            ],
        );

        sub init_db {
            return $main::db;
        }

    }

    {

        package My::Foo::Form;
        @My::Foo::Form::ISA = ('Rose::HTMLx::Form::Related::RDBO');

        sub init_metadata {
            my $self = shift;
            return $self->metadata_class->new(
                form         => $self,
                object_class => $self->object_class,
            );
        }

        sub object_class {'My::Foo'}

        sub init_with_foo {
            my $self = shift;
            $self->init_with_object(@_);
        }

        sub foo_from_form {
            my $self = shift;
            $self->object_from_form(@_);
        }

        sub build_form {
            my $self = shift;

            $self->add_fields(

                id => {
                    id          => 'id',
                    type        => 'serial',
                    class       => 'serial',
                    label       => 'Id',
                    rank        => 1,
                    description => q{},
                },

                name => {
                    id          => 'name',
                    type        => 'text',
                    class       => 'varchar',
                    label       => 'Name',
                    tabindex    => 2,
                    rank        => 2,
                    size        => 16,
                    maxlength   => 16,
                    description => q{},
                },

                static => {
                    id          => 'static',
                    type        => 'text',
                    class       => 'character',
                    label       => 'Static',
                    tabindex    => 3,
                    rank        => 3,
                    size        => 8,
                    maxlength   => 8,
                    description => q{},
                },

                my_int => {
                    id          => 'my_int',
                    type        => 'integer',
                    class       => 'integer',
                    label       => 'My Int',
                    tabindex    => 4,
                    rank        => 4,
                    size        => 24,
                    maxlength   => 64,
                    description => q{},
                },

                my_dec => {
                    id          => 'my_dec',
                    type        => 'numeric',
                    class       => 'float',
                    label       => 'My Dec',
                    tabindex    => 5,
                    rank        => 5,
                    size        => 16,
                    maxlength   => 32,
                    description => q{},
                },
            );

            return $self->SUPER::build_form(@_);
        }

    }

    {

        package My::Bar::Form;
        @My::Bar::Form::ISA = ('Rose::HTMLx::Form::Related::RDBO');

        sub init_metadata {
            my $self = shift;
            return $self->metadata_class->new(
                form         => $self,
                object_class => $self->object_class,
            );
        }

        sub object_class {'My::Bar'}

        sub init_with_bar {
            my $self = shift;
            $self->init_with_object(@_);
        }

        sub bar_from_form {
            my $self = shift;
            $self->object_from_form(@_);
        }

        sub build_form {
            my $self = shift;

            $self->add_fields(

                id => {
                    id          => 'id',
                    type        => 'serial',
                    class       => 'serial',
                    label       => 'Id',
                    rank        => 1,
                    description => q{},
                },

                foo_id => {
                    id          => 'foo_id',
                    type        => 'integer',
                    class       => 'integer',
                    label       => 'Foo',
                    tabindex    => 2,
                    description => q{},
                },
            );

            return $self->SUPER::build_form(@_);
        }
    }

    ok( my $foo_form = My::Foo::Form->new(), "new Foo::Form object" );
    ok( my $foo_html = $foo_form->html,      "get html" );
    like(
        $foo_html,
        qr!<label for="my_dec">My Dec</label><div class="field"><input class="float"!,
        "match form html"
    );

    ok( my $bar_form = My::Bar::Form->new(), "new Bar::Form object" );
    ok( my $bar_relationships = $bar_form->metadata->relationships,
        "get bar relationships" );
    is( scalar(@$bar_relationships), 1, "bar as 1 relationship" );

    #diag( dump $bar_relationships );
    is( $bar_relationships->[0]->name,
        "foo", "bar's one relationship is named foo" );
    is( $bar_relationships->[0]->type,
        "foreign key", "bar's one relationship is type FK" );
    is( $bar_form->field('foo_id')->type,
        "menu", "FK field converted to menu" );

}
