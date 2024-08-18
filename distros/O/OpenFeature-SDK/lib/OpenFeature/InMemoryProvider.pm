use v5.36;
package OpenFeature::InMemoryProvider;

sub new($class, %args) {
    my $self = { %args };
    bless $self, $class
}

sub resolve_boolean_details(
    $self,
    $flag_key,
    $default_value,
    $evaluation_context
) {
    { value => 0 }
}

1;
