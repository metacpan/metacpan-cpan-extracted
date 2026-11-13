package MojoX::Authentication::Model::Hash;
{ our $VERSION = '0.100' }

use v5.24;
use Moo;
use experimental qw< signatures >;
use English;
use JSON::PP qw< decode_json >;
use Ouch qw< :trytiny_var >;
use Storable qw< dclone >;

sub slurp ($path) {
   open my $fh, '<:raw', $path
      or ouch 404, 'configuration file not found', $path;
   local $/;
   my $contents = readline($fh)
      // ouch 500, 'failed reading configuration file', $OS_ERROR;
   return $contents;
}

use constant DEFAULT_NAME => 'hashy';

use namespace::clean;

with 'MojoX::Authentication::Model::Role::Local';
with 'MojoX::Authentication::Model::Role::Creator';

has db => (is => 'rwp', required => 1);
has name => (is => 'rw', default => DEFAULT_NAME);
has _secrets_are_cleartext => (is => 'ro', default => 0,
   init_arg => 'secrets_are_cleartext');

sub create ($class, $config, %args) {
   %args = $class->_create_args(DEFAULT_NAME, $config, %args);
   ouch 404, 'missing argument for db' unless defined($args{db});
   my $self = $class->new(%args);
   $self->_adjust_db;
   return $self;
}

sub _adjust_db ($self) {
   my $db = $self->db;

   if (! ref($db)) { # passed in as a JSON string or a file path?
      $db = slurp($db) if $db !~ m{\A \s* \[ }mxs;
      $db = decode_json($db);
   }

   $db = dclone($db);
   my $ref = ref($db);
   if ($ref eq 'ARRAY') {
      my %new_db;
      for my $item ($db->@*) {
         ouch 400, 'missing/undefined "username" in Hash db input record'
            unless defined($item->{username});
         $new_db{$item->{username}} = $item;
      }
      $db = \%new_db;
   }
   elsif ($ref eq 'HASH') {
      $db->{$_}{username} = $_ for keys($db->%*);
   }
   else {
      ouch 400, 'invalid input for Hash db';
   }

   if ($self->_secrets_are_cleartext) {  # need hashing?
      my $key = $self->key_for_secret;
      my $cp = $self->crypt_passphrase;
      for my $item (values($db->%*)) {
         next unless length($item->{$key} // '');
         $item->{$key} = $cp->hash_password($item->{$key});
      }
   }

   $self->_set_db($db);
   return;
}


# in this implementation, username and userid are the same
sub load_user ($self, $ignored, $uid) {
   my $item = $self->db->{$uid} // return;
   return { $item->%* }; # shallow copy out
}

# this method is required for compositing
# MojoX::Authentication::Model::Role::Local
BEGIN {
   *{load_user_by_username} = \&load_user;
}

sub save_user ($self, $user, $is_secret_cleartext = 0) {
   $self->db->{$user->{username}}
      = $self->user_for_save($user, $is_secret_cleartext);
   return $self;
}

1;
