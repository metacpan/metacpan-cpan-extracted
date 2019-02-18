package MooseX::ExtraArgs::Meta::ToClass;

$MooseX::ExtraArgs::Meta::ToClass::VERSION = '0.02';

use Moose::Role;

around apply => sub {
    my $orig      = shift;
    my $self      = shift;
    my $from_role = shift;
    my $to_class  = shift;

    Moose::Util::MetaRole::apply_base_class_roles(
        for   => $to_class,
        roles => ['MooseX::ExtraArgs::Meta::Object'],
    );

    return $self->$orig( $from_role, $to_class );
};

1;
