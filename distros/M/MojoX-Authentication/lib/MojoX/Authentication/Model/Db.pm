package MojoX::Authentication::Model::Db;
{ our $VERSION = '0.100' }

use v5.24;
use Moo;
use experimental qw< signatures >;
use Ouch qw< :trytiny_var >;

use constant DEFAULT_FOR => {
   name => 'dby',
   table => 'account',
   username_column => 'username',
};

use namespace::clean;

with 'MojoX::Authentication::Model::Role::Creator';
with 'MojoX::Authentication::Model::Role::Local';
with 'MojoX::Authentication::Model::Role::MojoDbWrap';
with 'MojoX::Authentication::Model::Role::Remap';

has name => (is => 'rw', default => DEFAULT_FOR->{name});
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
   *{load_user_by_username} = \&load_user;
}

sub save_user ($self, $user, $is_secret_cleartext = 0) {
   my $u = $self->user_for_save($user, $is_secret_cleartext);
   my $data  = $self->remap($u, $self->remaps, 'backwards');

   my $table = $self->table;
   my $id_column = $self->username_column;

   $self->wmdb->upsert($table, $data, { conflicting => $id_column });

   return $self;
}

sub _select ($self, %condition) {
   my $r = $self->wmdb->db->select($self->table, '*', \%condition)->hash;
   return unless defined($r);
   return $self->remap($r, $self->remaps);
}

1;
