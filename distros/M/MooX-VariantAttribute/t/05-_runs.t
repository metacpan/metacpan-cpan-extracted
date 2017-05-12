use Test::More;

{
    package One::Two::Three;

    use Moo;
    use MooX::VariantAttribute;
    use Types::Standard qw/Str HashRef ArrayRef/;

    variant switch => (
        given => Str,
        when => [
            one => { run => sub { return 'easy' } },
            two => { run => sub { return [qw/thinking to/] } },
            three => { run => sub { return { need => 'to' } } },
            four => { run => sub { return sub { 'sometimes' } } },
        ],
    );

    variant hash => (
        given => HashRef,
        when => [
            { one => 'two' } => { run => sub { return 'easy' } },
        ],
    );

    variant array => (
        given => ArrayRef,
        when => [
            [ qw/one two/ ] => { run => sub { return 'easy' } },
        ],
    );

}

my $obj = One::Two::Three->new;

is $obj->switch('one'), 'easy', "Switch one is easy";
is $obj->switch, 'easy', "Switch one is easy";
is_deeply $obj->switch('two'), [qw/thinking to/], "Switch two [thinking to]";
is_deeply $obj->switch, [qw/thinking to/], "Switch two [thinking to]";
is_deeply $obj->switch('three'), { need => 'to' }, "switch three { need => to }"; 
is_deeply $obj->switch, { need => 'to' }, "switch three { need => to }"; 
is $obj->switch('four')->(), 'sometimes', 'sometimes';
is $obj->switch->(), 'sometimes', 'sometimes';

is $obj->hash({ one => 'two' }), 'easy', "easy";
is $obj->hash, 'easy', "easy";

is $obj->array([ qw/one two/ ]), 'easy', 'easy';
is $obj->array, 'easy', 'easy';

done_testing();
