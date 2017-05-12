package Foo::Test::One;

Foo::Test::One->table("foobar");
Foo::Test::One->columns(All => qw[id name value]);

sub insert_data_order { 10 }
sub insert_data {
    Foo::Test::One->create({name => "Hello", value => "World"});
}

sub baz :Exported {
    my ($self, $r) = @_;
    $r->{output} = "Maypole okay";
}

1;

__DATA__
CREATE TABLE IF NOT EXISTS foobar (
    id integer primary key,
    name varchar(255),
    value varchar(10)
);
