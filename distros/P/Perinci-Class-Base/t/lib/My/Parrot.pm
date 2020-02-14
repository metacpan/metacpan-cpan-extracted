package My::Parrot;
use parent 'My::Animal';

our %SPEC;

# we are modifying 'speak' metadata as we add an argument.
$SPEC{speak} = {
    v => 1.,
    is_meth => 1,
    args => {
        word => {schema=>'str*'},
    },
};
sub speak {
    my ($self, $word) = @_;
    print "squawk! $word!\n";
    [200];
}

1;
