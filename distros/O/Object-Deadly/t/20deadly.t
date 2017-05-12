use Test::Exception tests => 9 * 15;
use Object::Deadly;
use Symbol 'gensym';

for my $obj (
    Object::Deadly->new,
    Object::Deadly->new('a message'),
    Object::Deadly->new_with(
        do { my $v; \$v }
    ),
    Object::Deadly->new_with( [] ),
    Object::Deadly->new_with( {} ),
    Object::Deadly->new_with(qr//),
    Object::Deadly->new_with( sub { } ),
    Object::Deadly->new_with( \*STDIN ),
    Object::Deadly->new_with(gensym)
    )
{
    lives_ok { Object::Deadly->new } '->DESTROY lives';

    my $obj = Object::Deadly->new('XXX');

    dies_ok { $obj->import('...') } '->import dies';
    dies_ok { $obj->isa('...') } '->isa dies';
    dies_ok { $obj->can('...') } '->can dies';
    dies_ok { $obj->DOES('...') } '->DOES dies';
    dies_ok { $obj->VERSION } '->VERSION dies';
    dies_ok { $obj->require } '->require dies';

    dies_ok {"$obj"} '"$obj" dies';
    dies_ok { 0 + $obj } '0+$obj dies';
    dies_ok { !$obj } 'not($obj) dies';

    for my $sigil (qw( $ @ % & * )) {
        eval "dies_ok { $sigil\$obj } '$sigil\$obj dies'";
        die $@ if $@;
    }
}

