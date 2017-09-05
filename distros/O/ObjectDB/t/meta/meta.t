use strict;
use warnings;

use Test::More;
use Test::Fatal;

use_ok 'ObjectDB::Meta';

subtest 'require_table' => sub {
    like(exception { ObjectDB::Meta->new(class => 'Foo') }, qr/Table is required when building meta/);
};

subtest 'require_class' => sub {
    like(exception { ObjectDB::Meta->new(table => 'foo') }, qr/Class is required when building meta/);
};

subtest 'has_class' => sub {
    my $meta = _build_meta();

    is($meta->get_class, 'Foo');
};

subtest 'has_table_name' => sub {
    my $meta = _build_meta();

    is($meta->get_table, 'foo');
};

subtest 'has_columns' => sub {
    my $meta = _build_meta();

    $meta->set_columns(qw/foo bar baz/);

    is_deeply([ $meta->get_columns ], [qw/foo bar baz/]);
};

subtest 'add_columns' => sub {
    my $meta = _build_meta();

    $meta->set_columns(qw/foo bar baz/);
    $meta->add_column('bbb');

    is_deeply([ $meta->get_columns ], [qw/foo bar baz bbb/]);
};

subtest 'throw_when_adding_existing_column' => sub {
    my $meta = _build_meta();

    $meta->set_columns(qw/foo bar baz/);

    like(exception { $meta->add_column('foo') }, qr/Column 'foo' already exists/);
};

subtest 'has_primary_key' => sub {
    my $meta = _build_meta();

    $meta->set_columns(qw/foo bar baz/);
    $meta->set_primary_key('foo');

    is_deeply([ $meta->get_primary_key ], [qw/foo/]);
};

subtest 'die_when_setting_primary_key_on_unknown_column' => sub {
    my $meta = _build_meta();

    $meta->set_columns(qw/foo bar baz/);

    like(exception { $meta->set_primary_key('unknown') }, qr/Unknown column 'unknown'/);
};

subtest 'has_unique_keys' => sub {
    my $meta = _build_meta();

    $meta->set_columns(qw/foo bar baz/);
    $meta->set_unique_keys('foo');

    is_deeply([ $meta->get_unique_keys ], [ ['foo'] ]);
};

subtest 'has_unique_keys_2' => sub {
    my $meta = _build_meta();

    $meta->set_columns(qw/foo bar baz/);
    $meta->set_unique_keys('foo', ['bar']);

    is_deeply([ $meta->get_unique_keys ], [ ['foo'], ['bar'] ]);
};

subtest 'has_unique_keys_multi' => sub {
    my $meta = _build_meta();

    $meta->set_columns(qw/foo bar baz/);
    $meta->set_unique_keys('foo', [ 'bar', 'baz' ]);

    is_deeply([ $meta->get_unique_keys ], [ ['foo'], [ 'bar', 'baz' ] ]);
};

subtest 'throw when_setting_primary_key_on_unknown_column' => sub {
    my $meta = _build_meta();

    $meta->set_columns(qw/foo bar baz/);

    like(exception { $meta->set_primary_key('unknown') }, qr/Unknown column 'unknown'/);
};

subtest 'has_auto_increment_key' => sub {
    my $meta = _build_meta();

    $meta->set_columns(qw/foo bar baz/);
    $meta->set_auto_increment('foo');

    is_deeply($meta->get_auto_increment, 'foo');
};

subtest 'die_when_setting_auto_increment_on_unknown_column' => sub {
    my $meta = _build_meta();

    $meta->set_columns(qw/foo bar baz/);

    like(exception { $meta->set_auto_increment('unknown') }, qr/Unknown column 'unknown'/);
};

subtest 'return_regular_columns' => sub {
    my $meta = _build_meta();

    $meta->set_columns(qw/foo bar baz/);
    $meta->set_primary_key('foo');

    is_deeply([ $meta->get_regular_columns ], [ 'bar', 'baz' ]);
};

subtest 'check_is_column' => sub {
    my $meta = _build_meta();

    $meta->set_columns(qw/foo bar baz/);

    ok($meta->is_column('foo'));
    ok(!$meta->is_column('unknown'));
};

subtest 'add_relationship' => sub {
    my $meta = _build_meta();

    $meta->set_columns(qw/foo bar baz/);
    $meta->set_primary_key('foo');

    $meta->add_relationship(foo => { type => 'one to one' });

    ok($meta->get_relationship('foo'));
};

subtest 'is_relationship' => sub {
    my $meta = _build_meta();

    $meta->set_columns(qw/foo bar baz/);
    $meta->set_primary_key('foo');

    $meta->add_relationship(foo => { type => 'one to one' });

    ok($meta->is_relationship('foo'));
};

subtest 'add_relationships' => sub {
    my $self = shift;

    my $meta = _build_meta();

    $meta->set_columns(qw/foo bar baz/);

    $meta->add_relationships(bar => { type => 'many to one' });

    ok($meta->is_relationship('bar'));
};

subtest 'check_is_relationship' => sub {
    my $self = shift;

    my $meta = _build_meta();

    $meta->add_relationships(foo => { type => 'many to one' });

    ok($meta->is_relationship('foo'));
    ok(!$meta->is_relationship('unknown'));
};

subtest 'inherit_table' => sub {
    {

        package Parent;
        use base 'ObjectDB';
        __PACKAGE__->meta(table => 'parent');
    }

    {

        package Child;
        use base 'Parent';
        __PACKAGE__->meta;
    }

    my $meta = Child->meta;

    is($meta->get_table, 'parent');
};

subtest 'inherit_columns' => sub {
    {

        package ParentWithColumns;
        use base 'ObjectDB';
        __PACKAGE__->meta(
            table   => 'parent',
            columns => [qw/foo/]
        );
    }

    {

        package ChildInheritingColumns;
        use base 'ParentWithColumns';
        __PACKAGE__->meta->add_column(qw/bar/);
    }

    my $meta = ChildInheritingColumns->meta;

    is_deeply([ $meta->get_columns ], [qw/foo bar/]);
};

subtest 'generates columns methods' => sub {
    {

        package MyClassWithGeneratedColumnsMethods;
        use base 'ObjectDB';
        __PACKAGE__->meta(
            table                    => 'parent',
            columns                  => [qw/foo/],
            generate_columns_methods => 1
        );
    }

    ok(MyClassWithGeneratedColumnsMethods->can('foo'));
};

subtest 'generates related methods' => sub {
    {

        package MyClassWithGeneratedRelatedMethods;
        use base 'ObjectDB';
        __PACKAGE__->meta(
            table         => 'parent',
            columns       => [qw/foo/],
            relationships => {
                children => {
                    type => 'one to many'
                }
            },
            generate_related_methods => 1,
        );
    }

    ok(MyClassWithGeneratedRelatedMethods->can('children'));
};

done_testing;

sub _build_meta {
    ObjectDB::Meta->new(table => 'foo', class => 'Foo', @_);
}
