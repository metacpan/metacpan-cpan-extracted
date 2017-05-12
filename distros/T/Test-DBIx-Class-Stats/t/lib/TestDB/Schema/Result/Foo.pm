package TestDB::Schema::Result::Foo;
use parent 'DBIx::Class::Core';

__PACKAGE__->table('foo');

__PACKAGE__->add_column('foo' => {
    data_type => 'int',
    is_nullable => 0,
    default => 0,
});

1;
