package QBit::Application::Model::DB::mysql::KvStore;
$QBit::Application::Model::DB::mysql::KvStore::VERSION = '0.002';
use qbit;

use base qw(QBit::Application::Model::DB::mysql QBit::Application::Model::DB::KvStore);

__PACKAGE__->meta(
    tables => {
        kv_store => {
            fields => [
                {name => 'key',   type => 'VARCHAR', length => 255, not_null => 1, default => ''},
                {name => 'value', type => 'VARCHAR', length => 255, not_null => 1, default => ''},
                {name => 'last_change',   type => 'TIMESTAMP', not_null => 1},
            ],
            primary_key => [qw(key)],
        },
    },
);

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::Application::Model::DB::mysql::KvStore - Definition mysql table for key value storage.

=head1 GitHub

https://github.com/QBitFramework/QBit-Application-Model-DB-mysql-KvStore

=head1 Install

=over

=item *

cpanm QBit::Application::Model::DB::mysql::KvStore

=item *

apt-get install libqbit-application-model-db-mysql-kvstore-perl (http://perlhub.ru/)

=back

For more information. please, see code.

=cut
