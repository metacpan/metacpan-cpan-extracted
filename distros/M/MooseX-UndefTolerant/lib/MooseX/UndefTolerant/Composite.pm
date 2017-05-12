package MooseX::UndefTolerant::Composite;

our $VERSION = '0.21';

use Moose::Role;

around apply_params => sub {
    my $orig = shift;
    my $self = shift;

    $self->$orig(@_);

    $self = Moose::Util::MetaRole::apply_metaroles(
        for            => $self,
        role_metaroles => {
            application_to_class =>
                ['MooseX::UndefTolerant::ApplicationToClass'],
            application_to_role =>
                ['MooseX::UndefTolerant::ApplicationToRole'],
        },
    );

    return $self;
};

no Moose::Role;

1;
