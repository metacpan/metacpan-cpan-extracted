package # Hide from the indexer for now until docs are added later.
    MooseX::SingleArg::Meta::ToRole;
use Moose::Role;

around apply => sub{
    my $orig      = shift;
    my $self      = shift;
    my $from_role = shift;
    my $to_role   = shift;

    $to_role = Moose::Util::MetaRole::apply_metaroles(
        for            => $to_role,
        role_metaroles => {
            role                 => ['MooseX::SingleArg::Meta::Role'],
            application_to_class => ['MooseX::SingleArg::Meta::ToClass'],
            application_to_role  => ['MooseX::SingleArg::Meta::ToRole'],
        },
    );

    $to_role->single_arg( $from_role->single_arg() ) if $from_role->has_single_arg();
    $to_role->force_single_arg( $from_role->force_single_arg() );

    return $self->$orig( $from_role, $to_role );
};

1;
