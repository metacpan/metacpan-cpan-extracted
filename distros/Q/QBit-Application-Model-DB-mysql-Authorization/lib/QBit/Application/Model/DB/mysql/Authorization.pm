package QBit::Application::Model::DB::mysql::Authorization;
$QBit::Application::Model::DB::mysql::Authorization::VERSION = '0.001';
use qbit;

use base qw(QBit::Application::Model::DB::mysql QBit::Application::Model::DB::Authorization);

__PACKAGE__->meta(
    tables => {
        authorization => {
            fields => [
                {name => 'key',           type => 'VARCHAR', length => 255, not_null => TRUE,},
                {name => 'password_hash', type => 'VARCHAR', length => 128, not_null => TRUE,},
            ],
            primary_key => [qw(key)],
        },
    },
);

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::Application::Model::DB::mysql::Authorization - MySQL table for QBit::Application::Model::Authorization.

=head1 GitHub

https://github.com/QBitFramework/QBit-Application-Model-DB-mysql-Authorization

=head1 Install

=over

=item *

cpanm QBit::Application::Model::DB::mysql::Authorization

=item *

apt-get install libqbit-application-model-db-mysql-authorization-perl (http://perlhub.ru/)

=back

For more information. please, see code.

=cut
