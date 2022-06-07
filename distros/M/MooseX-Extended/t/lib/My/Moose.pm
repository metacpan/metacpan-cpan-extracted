package My::Moose {
    use MooseX::Extended::Custom;

    sub import ( $class, %args ) {
        MooseX::Extended::Custom->create(
            excludes => [qw/ StrictConstructor c3 carp /],
            %args
        );
    }
}
