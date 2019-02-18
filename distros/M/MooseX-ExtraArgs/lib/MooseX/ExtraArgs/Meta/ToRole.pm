package MooseX::ExtraArgs::Meta::ToRole;

$MooseX::ExtraArgs::Meta::ToRole::VERSION = '0.02';

use Moose::Role;

around apply => sub{
    my $orig      = shift;
    my $self      = shift;
    my $from_role = shift;
    my $to_role   = shift;

    $to_role = Moose::Util::MetaRole::apply_metaroles(
        for            => $to_role,
        role_metaroles => {
            application_to_class => ['MooseX::ExtraArgs::Meta::ToClass'],
            application_to_role  => ['MooseX::ExtraArgs::Meta::ToRole'],
        },
    );

    return $self->$orig( $from_role, $to_role );
};

1;
