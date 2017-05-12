package QBit::Application::Model::RBAC;
$QBit::Application::Model::RBAC::VERSION = '0.014';
use qbit;

use base qw(QBit::Application::Model);

__PACKAGE__->register_rights(
    [
        {
            name        => 'rbac',
            description => sub {gettext('Rights for RBAC')},
            rights      => {
                rbac_roles_view           => d_gettext('Right to view list of roles'),
                rbac_role_add             => d_gettext('Right to add new role'),
                rbac_user_role_set        => d_gettext('Right to set role to user'),
                rbac_revoke_roles         => d_gettext('Right to revoke roles'),
                rbac_assign_rigth_to_role => d_gettext('Right to assign right to role')
            },
        }
    ]
);

__PACKAGE__->abstract_methods(
    qw(
      get_roles
      role_add
      role_edit
      set_roles_rights
      set_user_role
      get_roles_rights
      get_cur_user_roles
      revoke_roles
      get_roles_by_rights
      )
);

TRUE;
