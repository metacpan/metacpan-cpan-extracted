package MooseX::SlurpyConstructor::Trait::ApplicationToRole;

our $VERSION = '1.30';

use Moose::Role;

around apply => sub {
    my $orig  = shift;
    my $self  = shift;
    my ($role1, $role2) = @_;

    $role2 = Moose::Util::MetaRole::apply_metaroles(
        for             => $role2,
        role_metaroles => {
            application_to_class => [
                'MooseX::SlurpyConstructor::Trait::ApplicationToClass',
            ],
            application_to_role => [
                'MooseX::SlurpyConstructor::Trait::ApplicationToRole',
            ],
        }
    );

    $self->$orig( $role1, $role2 );
};

no Moose::Role;

1;
