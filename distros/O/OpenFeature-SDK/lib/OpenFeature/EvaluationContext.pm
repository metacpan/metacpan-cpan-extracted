use v5.36;

package OpenFeature::EvaluationContext;

sub new($class, $attributes, $targeting_key = undef) {
    my $self = {
        targeting_key => $targeting_key,
        attributes => $attributes,
    };
}

sub merge($self, $new_context) {
    die 'not implemented'
}

1;
