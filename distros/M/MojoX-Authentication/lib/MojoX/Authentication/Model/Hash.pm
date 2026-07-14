package MojoX::Authentication::Model::Hash;
{ our $VERSION = '0.003' }

use v5.24;
use Moo;
use experimental qw< signatures >;
use English;
use JSON::PP qw< decode_json >;
use Ouch qw< :trytiny_var >;

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
has name => (is => 'ro', default => DEFAULT_NAME);
has _secrets_are_cleartext => (is => 'ro', default => 0,
   init_arg => 'secrets_are_cleartext');

sub create ($class, $config, %args) {
   %args = $class->_create_args(DEFAULT_NAME, $config, %args);
   return unless defined($args{db}); # no db, no party
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

   # normalize to hash reference name => record
   $db = { map { $_->{name} => $_ } $db->@* } if ref($db) eq 'ARRAY';

   # work on shallow copies of the provided records
   $db->{$_} = { $db->{$_}->%*, username => $_ } for keys($db->%*);

   if ($self->_secrets_are_cleartext) {  # need hashing?
      my $cp = $self->crypt_passphrase;
      $_->{secret} = $cp->hash_password($_->{secret}) for values($db->%*);
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
   *{load_user_by_name} = \&load_user;
}

sub save_user ($self, $user, $is_secret_cleartext = 0) {
   my %u = $user->%*;
   $u{secret} = $self->hash_secret($u{secret}) if $is_secret_cleartext;
   $self->db->{$u{name}} = \%u;
   return $self;
}

1;
