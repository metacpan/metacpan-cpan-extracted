{
    package Foo; 
}

use Test::More;
use Monkey::Patch qw(patch_object);

my $o = bless {}, 'Foo';
my $h = patch_object $o => 'bar', sub {
    'here';
};

is $o->bar, 'here';
undef $h;
eval { $o->bar };
like $@, qr/object method/;

done_testing;
