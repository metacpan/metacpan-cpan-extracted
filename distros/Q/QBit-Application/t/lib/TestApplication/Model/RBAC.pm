package TestApplication::Model::RBAC;

use qbit;

our @RIGHTS;

use base qw(QBit::Application::Model::RBAC);

sub get_cur_user_roles {
    return {3 => {id => 3, name => 'ROLE 3', description => 'ROLE 3'}};
}

sub get_roles_rights {
    return [map {{right => $_}} @RIGHTS];
}

TRUE;
