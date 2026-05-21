use strict;
use warnings;
use Test::More;

# Define parent BEFORE child (Perl compile-order matters)
BEGIN {
    package My::Parent;
    use Object::HashBase qw/pa/;
    $INC{'My/Parent.pm'} = __FILE__;
}

BEGIN {
    package My::Child;
    use Object::HashBase qw/@My::Parent ch/;
}

isa_ok('My::Child', 'My::Parent', 'child ISA parent');

can_ok('My::Child', qw/PA CH pa ch set_pa set_ch new/);

is(My::Child::PA(), 'pa', 'PA constant inherited');
is(My::Child::CH(), 'ch', 'CH constant');

my $obj = My::Child->new(pa => 'P', ch => 'C');
is($obj->pa, 'P', 'pa accessor');
is($obj->ch, 'C', 'ch accessor');
$obj->set_pa('PP');
is($obj->pa, 'PP', 'set_pa works');

# Multiple parents via repeated @ prefix
BEGIN {
    package My::P1;
    use Object::HashBase qw/p1a/;
    $INC{'My/P1.pm'} = __FILE__;

    package My::P2;
    use Object::HashBase qw/p2a/;
    $INC{'My/P2.pm'} = __FILE__;
}

BEGIN {
    package My::MultiChild;
    use Object::HashBase qw/@My::P1 @My::P2 mc/;
}

isa_ok('My::MultiChild', 'My::P1');
isa_ok('My::MultiChild', 'My::P2');
can_ok('My::MultiChild', qw/P1A P2A MC/);

# Idempotent: re-adding same parent doesn't double-list
{
    no strict 'refs';
    my @isa = @{'My::Child::ISA'};
    my @parent_count = grep { $_ eq 'My::Parent' } @isa;
    is(scalar @parent_count, 1, 'parent listed once in @ISA');
}

# Bogus parent: require failure croaks from caller
{
    my $err;
    eval {
        package My::BadChild;
        Object::HashBase->import('@Bogus::NonExistent::Class');
        1;
    } or $err = $@;
    like($err, qr/Could not load parent class 'Bogus::NonExistent::Class'/, 'bogus parent croaks');
}

done_testing;
