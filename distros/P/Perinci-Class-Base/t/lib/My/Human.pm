package My::Human;
use parent 'My::Animal';

our %SPEC;

# we are modifying 'speak' metadata as we remove an argument ('word') and add
# another ('words').
__PACKAGE__->modify_rinci_meta_for(speak => {
    args => {
        '!word' => undef,
        words => {schema=>'str*'},
    },
});
sub speak {
    my ($self, $words) = @_;
    print "$words!\n";
    [200];
}

1;
