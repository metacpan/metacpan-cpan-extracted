use strict;
use Test::More;

{
    package My::Class;
    use Poz qw/z/;
    z->object({
        name => z->string,
        age => z->number,
    })->constructor;
}

my $instance = My::Class->new(
    name => 'Alice',
    age => 20,
);

isa_ok($instance, 'My::Class');
is($instance->{name}, 'Alice');
is($instance->{age}, 20);

done_testing();