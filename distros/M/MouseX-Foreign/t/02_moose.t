#!perl -w
use strict;
use Test::Requires qw(Moose);
use Test::More;
use Test::Exception;

use Test::Mouse;

my $person_build      = 0;
my $person_demolish   = 0;
my $myperson_build    = 0;
my $myperson_demolish = 0;
BEGIN{
    package Person;
    use Moose;

    has name => (is => 'rw');
    has age  => (is => 'rw');

    sub BUILD    { $person_build++ }
    sub DEMOLISH { $person_demolish++ }

    __PACKAGE__->meta->make_immutable();
}

{
    package MyPerson;
    use Mouse;
    use MouseX::Foreign qw(Person);

    has handle_name => (
        is => 'rw',
        isa => 'Str',
    );

    sub BUILD { $myperson_build++ }
    sub DEMOLISH { $myperson_demolish++ }
}

with_immutable {
    my $p = MyPerson->new(name => 'Goro Fuji', age => 27, handle_name => 'gfx');

    isa_ok $p, 'MyPerson';
    isa_ok $p, 'Person';

    is $p->name,        'Goro Fuji', 'from the base class';
    is $p->age,          27,         'from the base class';
    is $p->handle_name, 'gfx',       'from the derived class';

} qw(MyPerson);

is $person_build,      2, "the base class's BUILD is colled";
is $person_demolish,   2, "the base class's DEMOLISH is called";
is $myperson_build,    2, 'my BUILD is called';
is $myperson_demolish, 2, 'my DEMOLISH is called';
done_testing;
