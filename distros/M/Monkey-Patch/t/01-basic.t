{
    package Foo;
    sub bar {
        return pop;
    }
}

{
    package Bar;
    use base 'Foo';

    sub new { bless {}, shift }
}


use Test::More;
use Monkey::Patch qw(:all);

my $patcher = sub {
    my $o = shift;
   'patched ' . $o->(@_) 
};

{
    my $h = patch_package Foo => bar => $patcher;
    is Foo::bar('one'), 'patched one';
}
is Foo::bar('one'), 'one';

{
    my $h = patch_class Bar => bar => $patcher;
    is(Bar->bar('one'), 'patched one');
}
is(Bar->bar('one'), 'one');

my $one = Bar->new;
my $two = Bar->new;

{
    my $h = patch_object $one => bar => $patcher;
    is $one->bar('one'), 'patched one';
    is $two->bar('one'), 'one';
}

is $one->bar('one'), 'one';
is $two->bar('one'), 'one';

done_testing;
