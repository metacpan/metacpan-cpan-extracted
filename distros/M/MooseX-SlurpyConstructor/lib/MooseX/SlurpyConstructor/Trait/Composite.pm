package MooseX::SlurpyConstructor::Trait::Composite;

our $VERSION = '1.30';

use Moose::Role;

around apply_params => sub {
    my $orig = shift;
    my $self = shift;

    $self->$orig(@_);

    $self = Moose::Util::MetaRole::apply_metaroles(
        for            => $self,
        role_metaroles => {
            application_to_class =>
                ['MooseX::SlurpyConstructor::Trait::ApplicationToClass'],
            application_to_role =>
                ['MooseX::SlurpyConstructor::Trait::ApplicationToRole'],
        },
    );

    return $self;
};

no Moose::Role;

1;
