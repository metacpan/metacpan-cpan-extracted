package MojoX::Authentication::Model::Db;
{ our $VERSION = '0.004' }

use v5.24;
use Moo;
use experimental qw< signatures >;
use English;
use Ouch qw< :trytiny_var >;

use constant DEFAULT_FOR => {
   name => 'dby',
   table => 'account',
   username_column => 'name',
};

use namespace::clean;

with 'MojoX::Authentication::Model::Role::Creator';
with 'MojoX::Authentication::Model::Role::Local';
with 'MojoX::Authentication::Model::Role::MojoDbWrap';
with 'MojoX::Authentication::Model::Role::Remap';

has name => (is => 'ro', default => DEFAULT_FOR->{name});
has username_column
   => (is => 'ro', default => DEFAULT_FOR->{username_column});
has remaps => (is => 'ro', default => sub { return [] });
has table => (is => 'ro', default => DEFAULT_FOR->{table});

sub create ($class, $config, %args) {
   %args = $class->_create_args(DEFAULT_FOR->{name}, $config, %args);
   ouch 404, 'missing argument for wmdb' unless defined($args{wmdb});
   my $self = $class->new(%args);
   # FIXME possibly address stuff like creating the table, ecc.
   return $self;
}

sub load_user ($self, $ignored, $uid) {
   return $self->_select($self->username_column, $uid);
}

# this method is required for compositing
# MojoX::Authentication::Model::Role::Local
BEGIN {
   *{load_user_by_name} = \&load_user;
}

sub save_user ($self, $user, $is_secret_cleartext = 0) {
   my $wmdb = $self->wmdb;
   ouch 500, 'your MojoX::MojoDbWrap does not support upsert!!!'
      unless $wmdb->can('upsert');
   $user = { $user->%* }; # shallow copy for fiddling
   $user->{secret} = $self->hash_secret($user->{secret})
      if $is_secret_cleartext;

   $wmdb->upsert($self->table_name =>
      $self->remap($user, $self->remaps, 'backwards'));

   return $self;
}

sub _select ($self, %condition) {
   my $record = $self->wmdb->select($self->table, '*', \%condition)->hash;
   return unless defined($record);
   return $self->remap($record, $self->remaps);
}

1;
