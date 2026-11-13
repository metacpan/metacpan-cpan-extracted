package MojoX::Authentication::Model::SAML2::Db;
{ our $VERSION = '0.100' }

use v5.24;
use Moo;
use experimental qw< signatures >;
use JSON::PP qw< encode_json decode_json >;
use constant DEFAULT_TABLE => 'logged_in';
use namespace::clean;

with 'MojoX::Authentication::Model::Role::MojoDbWrap';

has table => (is => 'ro', default => DEFAULT_TABLE);

sub get ($self, $key) {
   my $res = $self->wmdb->db->select($self->table, '*', { k => $key });
   my $record = $res->hash // return;
   return decode_json($record->{data}) if $record->{expire} > time();
   $self->wipe($key);
   return;
}

sub set ($self, $data, $key, $expire) {
   $self->wipe($key);
   my $db = $self->wmdb->db;
   my $table = $self->table;
   my $now = time();
   $db->delete($table, { expire => { '<=', $now } });
   $db->insert($table,
      {
         k => $key,
         expire => $expire,
         data => encode_json($data)
      }
   );
   return $self;
}

sub wipe ($self, $key) {
   $self->wmdb->db->delete($self->table, { k => $key });
   return $self;
}

1;
