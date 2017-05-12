package MooseX::SlurpyConstructor::Trait::ApplicationToClass;

our $VERSION = '1.30';

use Moose::Role;

around apply => sub {
    my $orig  = shift;
    my $self  = shift;
    my ($role, $class) = @_;

    Moose::Util::MetaRole::apply_base_class_roles(
        for => $class,
        roles => ['MooseX::SlurpyConstructor::Role::Object'],
    );

    $class = Moose::Util::MetaRole::apply_metaroles(
        for             => $class,
        class_metaroles => {
            class => [ 'MooseX::SlurpyConstructor::Trait::Class' ],
        }
    );

    $self->$orig( $role, $class );
};

no Moose::Role;

1;
