package QBit::Application::Model::DB::mysql::Users;
$QBit::Application::Model::DB::mysql::Users::VERSION = '0.002';
use qbit;

use base qw(QBit::Application::Model::DB::mysql QBit::Application::Model::DB::Users);

__PACKAGE__->meta(
    tables => {
        users => {
            fields => [
                {name => 'id',        type => 'INT',      unsigned => 1, not_null => 1, autoincrement => 1,},
                {name => 'create_dt', type => 'DATETIME', not_null => 1,},
                {name => 'login',   type => 'VARCHAR', length => 255, not_null => 1,},
                {name => 'mail',    type => 'VARCHAR', length => 255,},
                {name => 'name',    type => 'VARCHAR', length => 255,},
                {name => 'midname', type => 'VARCHAR', length => 255,},
                {name => 'surname', type => 'VARCHAR', length => 255,},
            ],
            primary_key => [qw(id)],
            indexes     => [{fields => [qw(login)], unique => 1}, {fields => [qw(mail)], unique => 1}]
        },

        users_extra_fields => {
            fields => [
                {name => 'user_id'},
                {name => 'key', type => 'VARCHAR', length => 255, not_null => 1,},
                {name => 'value',   type => 'TEXT',    not_null => 1,},
                {name => 'is_json', type => 'BOOLEAN', default  => '0',},
            ],
            foreign_keys => [[[qw(user_id)] => 'users' => [qw(id)]]]
        },
    },
);

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::Application::Model::DB::mysql::Users - MySQL tables for QBit::Application::Model::DBManager::Users.

=head1 GitHub

https://github.com/QBitFramework/QBit-Application-Model-DB-mysql-Users

=head1 Install

=over

=item *

cpanm QBit::Application::Model::DB::mysql::Users

=item *

apt-get install libqbit-application-model-db-mysql-users-perl (http://perlhub.ru/)

=back

For more information. please, see code.

=cut
