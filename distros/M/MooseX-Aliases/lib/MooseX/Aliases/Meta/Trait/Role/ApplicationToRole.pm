package MooseX::Aliases::Meta::Trait::Role::ApplicationToRole;
BEGIN {
  $MooseX::Aliases::Meta::Trait::Role::ApplicationToRole::AUTHORITY = 'cpan:DOY';
}
{
  $MooseX::Aliases::Meta::Trait::Role::ApplicationToRole::VERSION = '0.11';
}
use Moose::Role;

around apply => sub {
    my $orig  = shift;
    my $self  = shift;
    my ($role1, $role2) = @_;

    $role2 = Moose::Util::MetaRole::apply_metaroles(
        for             => $role2,
        role_metaroles => {
            application_to_class => [
                'MooseX::Aliases::Meta::Trait::Role::ApplicationToClass',
            ],
            application_to_role => [
                'MooseX::Aliases::Meta::Trait::Role::ApplicationToRole',
            ],
        }
    );

    $self->$orig( $role1, $role2 );
};

no Moose::Role;

=for Pod::Coverage

=cut

1;
