package # Hide from the indexer.
    MooseX::SingleArg::Meta::ToClass;
use Moose::Role;

around apply => sub {
    my $orig      = shift;
    my $self      = shift;
    my $from_role = shift;
    my $to_class  = shift;

    $to_class = Moose::Util::MetaRole::apply_metaroles(
        for             => $to_class,
        class_metaroles => {
            class => ['MooseX::SingleArg::Meta::Class'],
        },
    );

    Moose::Util::MetaRole::apply_base_class_roles(
        for   => $to_class,
        roles => ['MooseX::SingleArg::Meta::Object'],
    );

    $to_class->single_arg( $from_role->single_arg() ) if $from_role->has_single_arg();
    $to_class->force_single_arg( $from_role->force_single_arg() );

    return $self->$orig( $from_role, $to_class );
};

1;
