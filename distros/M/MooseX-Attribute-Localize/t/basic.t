use Test::More tests => 7;

{
package Foo; 
    use Moose;
    use MooseX::Attribute::Localize;

    has 'bar' => (
        traits => [ 'Localize' ],
        is => 'rw',
        predicate => 'has_bar',
        handles => {
            set_local_bar => 'localize'
        },
    );
}


my $foo = Foo->new( bar => 1 );

is $foo->bar => 1;

{
    my $s = $foo->set_local_bar('2');
    is $foo->bar => 2;
        {
            my $s = $foo->set_local_bar('3');
            is $foo->bar => 3;

            $foo->bar(4);
            is $foo->bar => 4;
        }
    is $foo->bar => 2;
}

is $foo->bar => 1;

subtest "attribute is cleared" => sub {
    my $s = $foo->set_local_bar;
    ok ! $foo->has_bar, "bar is cleared";
    is $foo->bar => undef, "bar is undef";
};
