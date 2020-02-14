package My::Dog;
use parent 'My::Animal';

our %SPEC;

# speak's metadata will "inherit" (use metadata from the base class), since we
# don't have additionl/modified/removed arguments, etc.

sub speak {
    print "woof\n";
    [200];
}

$SPEC{play_dead} = {
    v => 1.1,
    is_meth => 1,
    args => {
        seconds => {schema=>'uint*', default=>5},
    },
};
sub play_dead {
    my ($self, %args) = @_;
    sleep $;
    [200];
}

1;
