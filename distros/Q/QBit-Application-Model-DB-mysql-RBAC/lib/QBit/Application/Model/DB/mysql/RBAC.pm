package QBit::Application::Model::DB::mysql::RBAC;
$QBit::Application::Model::DB::mysql::RBAC::VERSION = '0.002';
use qbit;

use base qw(QBit::Application::Model::DB::mysql QBit::Application::Model::DB::RBAC);

__PACKAGE__->meta(
    tables => {
        roles => {
            fields => [
                {name => 'id',          type => 'INT',     unsigned => 1,   not_null => 1, autoincrement => 1},
                {name => 'name',        type => 'VARCHAR', length   => 63,  not_null => 1},
                {name => 'description', type => 'VARCHAR', length   => 255, not_null => 1}
            ],
            primary_key => [qw(id)],
            indexes     => [{fields => [qw(name)], unique => 1}]
        },

        role_rights => {
            fields => [{name => 'role_id'}, {name => 'right', type => 'VARCHAR', length => 63, not_null => 1}],
            primary_key  => [qw(role_id right)],
            foreign_keys => [[[qw(role_id)] => 'roles' => [qw(id)]]]
        },

        user_role => {
            fields      => [{name => 'user_id'}, {name => 'role_id'}],
            primary_key => [qw(user_id role_id)],
            foreign_keys => [[[qw(role_id)] => 'roles' => [qw(id)]], [[qw(user_id)] => 'users' => [qw(id)]]]
        },
    },
);

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::Application::Model::DB::mysql::RBAC - MySQL tables for QBit::Application::Model::RBAC::DB.

=head1 GitHub

https://github.com/QBitFramework/QBit-Application-Model-DB-mysql-RBAC

=head1 Install

=over

=item *

cpanm QBit::Application::Model::DB::mysql::RBAC

=item *

apt-get install libqbit-application-model-db-mysql-rbac-perl (http://perlhub.ru/)

=back

For more information. please, see code.

=cut
