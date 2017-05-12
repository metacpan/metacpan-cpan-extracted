package MooseX::Aliases::Meta::Trait::Role::Composite;
BEGIN {
  $MooseX::Aliases::Meta::Trait::Role::Composite::AUTHORITY = 'cpan:DOY';
}
{
  $MooseX::Aliases::Meta::Trait::Role::Composite::VERSION = '0.11';
}
use Moose::Role;

around apply_params => sub {
    my $orig = shift;
    my $self = shift;

    $self->$orig(@_);

    $self = Moose::Util::MetaRole::apply_metaroles(
        for            => $self,
        role_metaroles => {
            application_to_class =>
                ['MooseX::Aliases::Meta::Trait::Role::ApplicationToClass'],
            application_to_role =>
                ['MooseX::Aliases::Meta::Trait::Role::ApplicationToRole'],
        },
    );

    return $self;
};

no Moose::Role;

=for Pod::Coverage

=cut

1;
