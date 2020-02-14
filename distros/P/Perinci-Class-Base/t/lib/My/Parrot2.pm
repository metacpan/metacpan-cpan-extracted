package My::Parrot2;
use parent 'My::Animal';

our %SPEC;

# we are modifying 'speak' metadata as we add an argument.
__PACKAGE__->modify_rinci_meta_for(speak => {
    args => {
        word => {schema=>'str*'},
    },
});
sub speak {
    my ($self, $word) = @_;
    print "squawk! $word!\n";
    [200];
}

1;
