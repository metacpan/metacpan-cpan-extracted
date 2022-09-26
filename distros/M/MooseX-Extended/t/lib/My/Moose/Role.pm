package My::Moose::Role {
    use MooseX::Extended::Role::Custom;

    sub import {
        my ( $class, %args ) = @_;
        MooseX::Extended::Role::Custom->create(
            excludes => 'WarnOnConflict',
            %args    # you need this to allow customization of your customization
        );
    }
}
