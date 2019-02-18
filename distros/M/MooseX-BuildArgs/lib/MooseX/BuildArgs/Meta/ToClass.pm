package MooseX::BuildArgs::Meta::ToClass;

$MooseX::BuildArgs::Meta::ToClass::VERSION = '0.07';

use Moose::Role;

around apply => sub {
    my $orig      = shift;
    my $self      = shift;
    my $from_role = shift;
    my $to_class  = shift;

    Moose::Util::MetaRole::apply_base_class_roles(
        for   => $to_class,
        roles => ['MooseX::BuildArgs::Meta::Object'],
    );

    return $self->$orig( $from_role, $to_class );
};

1;
