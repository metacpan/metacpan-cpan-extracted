package MooseX::BuildArgs::Meta::ToRole;
use 5.008001;
our $VERSION = '0.08';

use Moose::Role;

around apply => sub{
    my $orig      = shift;
    my $self      = shift;
    my $from_role = shift;
    my $to_role   = shift;

    $to_role = Moose::Util::MetaRole::apply_metaroles(
        for            => $to_role,
        role_metaroles => {
            application_to_class => ['MooseX::BuildArgs::Meta::ToClass'],
            application_to_role  => ['MooseX::BuildArgs::Meta::ToRole'],
        },
    );

    return $self->$orig( $from_role, $to_role );
};

1;
