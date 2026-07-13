package MojoX::Authentication::Model::SAML2::Db;
{ our $VERSION = '0.001' }

use v5.24;
use Moo;
use experimental qw< signatures >;
use JSON::PP qw< encode_json decode_json >;
use constant DEFAULT_TABLE => 'logged_in';
use namespace::clean;

has table => (is => 'ro', default => DEFAULT_TABLE);
has wmdb => (is => 'ro', required => 1);

sub get ($self, $key) {
   my $res = $self->wmdb->db->select($self->table, '*', { k => $key });
   return unless $res->size;
   my $record = $res->hash;
   return decode_json($record->{data}) if $record->{expire} > time();
   $self->wipe($key);
   return;
}

sub set ($self, $data, $key, $expire) {
   $self->wipe($key);
   $self->wmdb->db->insert($self->table,
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
