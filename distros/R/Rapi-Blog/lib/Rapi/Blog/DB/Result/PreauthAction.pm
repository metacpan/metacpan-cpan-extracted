use utf8;
package Rapi::Blog::DB::Result::PreauthAction;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("preauth_action");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "type",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "active",
  { data_type => "boolean", default_value => 1, is_nullable => 0 },
  "sealed",
  { data_type => "boolean", default_value => 0, is_nullable => 0 },
  "create_ts",
  { data_type => "datetime", is_nullable => 0 },
  "expire_ts",
  { data_type => "datetime", is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "auth_key",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "json_data",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("auth_key_unique", ["auth_key"]);
__PACKAGE__->has_many(
  "preauth_action_events",
  "Rapi::Blog::DB::Result::PreauthActionEvent",
  { "foreign.action_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "type",
  "Rapi::Blog::DB::Result::PreauthActionType",
  { name => "type" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
__PACKAGE__->belongs_to(
  "user",
  "Rapi::Blog::DB::Result::User",
  { id => "user_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-01-27 12:50:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:43iysyBK1Y/m5ydH2fLefQ


__PACKAGE__->load_components('+Rapi::Blog::DB::Component::SafeResult');

use RapidApp::Util ':all';
use Rapi::Blog::Util;
use Scalar::Util qw(looks_like_number);

sub _dtf { (shift)->result_source->schema->storage->datetime_parser }


sub active_request_Hit {
  my ($self, $new) = @_;
  $self->{_active_request_Hit} = $new if ($new);
  $self->{_active_request_Hit}
}


sub create_event {
  my ($self, $pkt) = @_;
  
  $pkt->{action_id} = $self->get_column('id');
  
  my $Hit = $self->active_request_Hit;
  
  $Hit 
    ? $self->evRsCmeth( create_with_hit => $Hit, $pkt ) 
    : $self->evRsCmeth( create => $pkt )
}

sub evRsCmeth {
  my ($self, $meth, @args) = @_;
  
  my $evRow = $self->preauth_action_events->$meth(@args);
  
  my $trk = $self->{_track_created_Events}; # <-- This is not currently being set and may be removed
  push @$trk, $evRow if (ref($trk)||'' eq 'ARRAY');

  $evRow
}

sub _handle_insert_update_columns_arg {
  my $self = shift;
  my $columns = shift;
  
  if ($columns) {
    if(exists $columns->{action_data}) {
      $self->action_data( delete $columns->{action_data} );
    }
    if (exists $columns->{ttl}) {
      die "Do not supply both 'expire_ts' and 'ttl' - one of the other" if (exists $columns->{expire_ts});
      die "Do not supply both 'ttl_minutes' and 'ttl' - one of the other" if (exists $columns->{ttl_minutes});
      $self->ttl( delete $columns->{ttl} );
    }
    if (exists $columns->{ttl_minutes}) {
      die "Do not supply both 'expire_ts' and 'ttl_minutes' - one of the other" if (exists $columns->{expire_ts});
      die "Do not supply both 'ttl' and 'ttl_minutes' - one of the other" if (exists $columns->{ttl});
      $self->ttl_minutes( delete $columns->{ttl_minutes} );
    }
    
    $self->set_inflated_columns($columns)
  }
}


sub insert {
  my $self = shift;
  $self->_handle_insert_update_columns_arg(shift);
  
  my $now_dt = Rapi::Blog::Util->now_dt;

  $self->create_ts( Rapi::Blog::Util->dt_to_ts($now_dt) );
  
  $self->expire_ts( Rapi::Blog::Util->dt_to_ts(
    $now_dt->clone->add( hours => 1 )
  )) unless $self->expire_ts;
  
  $self->next::method;
  
  return $self;
}

sub update {
  my $self = shift;
  $self->_handle_insert_update_columns_arg(shift);
  
  $self->next::method;
  
  return $self;
}


our @virtuals = qw/ttl ttl_minutes action_data/;
our %virtuals = map {$_=>1} @virtuals;

sub store_column {
my ($self, $col, $val) = @_;

  $virtuals{$col} ? $self->$col($val) : $self->next::method($col, $val)
}




sub deactivate {
  my ($self, $info) = @_;
  
  $self->active or die "Already inactive!";
  
  $self->create_event({ 
    type_id => 3,     # Deactivate
    info    => $info
  });
  
  $self->active(0);
  $self->update;
  
  $self
}



sub not_expired {
  my ($self, $test_dt) = shift;
  $test_dt ||= Rapi::Blog::Util->now_dt;
  
  return 1 if (
        Rapi::Blog::Util->dt_to_ts($self->expire_ts)
     gt Rapi::Blog::Util->dt_to_ts($test_dt)
  );
  
  $self->deactivate('Expired') if ($self->active);

  return 0
}


sub enforce_valid {
  my $self = shift;
  $self->active && $self->not_expired
}


sub request_validate {
  my ($self, $Hit) = @_;
  
  $self->active_request_Hit($Hit);
  
  if($self->enforce_valid) {
    $self->create_event({ type_id => 1 }); # Valid
    return 1;
  }
  else {
    $self->create_event({ type_id => 2 }); # Invalid
    return 0;
  }
}



sub _new_actor_instance {
  my ($self, $c) = @_;
  $self->type
    ->actor_class
    ->new( ctx => $c, PreauthAction => $self );
}



# This is called automatically by the actor:
sub _record_executed {
  my ($self, $info) = @_;

  $self->create_event({ 
    type_id => 4,     # Executed
    info    => $info
  });
  
  $self->deactivate('Executed')
}





sub seal {
  my ($self, $info) = @_;
  
  $self->sealed and die "Already sealed!";
  
  $self->deactivate('Action was active but is being Sealed') if ($self->active);
  
  $self->create_event({ 
    type_id => 5,     # Sealed
    info    => $info
  });
  
  $self->sealed(1);
  $self->update;
  
  $self
}


sub _serialize_set_new_action_data {
  my $self = shift;
  my $data = shift or die "_serialize_new_action_data(): no data supplied";
  (ref($data)||'') eq 'HASH' 
    or die "_serialize_new_action_data(): invalid data supplied - must be a HashRef";
  
  my $json = encode_json_ascii($data) or die "unknown error serializing to json";
  $self->json_data($json)
}

sub _deserialize_action_data {
  my $self = shift;
  my $json = $self->json_data or return {};
  
  my $data = decode_json_ascii($json) or die "unknown error occured deserializing json_data";
  (ref($data)||'') eq 'HASH' or die "Bad action data - did not deserialize to a HashRef";
  
  $data
}

# emulate simple column-like accessor:
sub action_data {
  my $self = shift;
  if(scalar(@_) > 0) {
    my $new = shift;
    $new = {} unless defined $new;
    $self->_serialize_set_new_action_data($new);
  }
  $self->_deserialize_action_data
}

sub ttl {
  my $self = shift;
  my $now_dt = Rapi::Blog::Util->now_dt;
  if(scalar(@_) > 0) {
    my $new = shift;
    die "ttl must be a whole number of seconds greater than 0" unless (
      $new && ($new =~ /^\d+$/)
    );
    
    $self->expire_ts( Rapi::Blog::Util->dt_to_ts(
      $now_dt->clone->add( seconds => $new )
    ))
  }
  
  # just being cautious here because of past bad expierences fully trusting 
  # the DateTime inflate/deflate across different versions and environments,
  # and I know this is reliable across the widest range of scenarios when we
  # don't want to consider time zones (since whatever it is, its the same in
  # all the places this logic needs to consider:
  my $expire_dt = Rapi::Blog::Util->ts_to_dt( $self->get_column('expire_ts') );
  return $expire_dt->epoch - $now_dt->epoch;
}


sub ttl_minutes {
  my $self = shift;
  require POSIX;
  if(scalar(@_) > 0) {
    my $new = shift;
    die "ttl_minutes must be a number greater than 0" unless (
      $new && looks_like_number($new) && $new > 0
    );
    $self->ttl( POSIX::ceil($new) * 60 );
  }
  my $ttl = $self->ttl or return 0;
  POSIX::ceil($ttl/60)
}


sub action_data_set {
  my $self = shift;
  my @kv_pairs = (ref($_[0]) eq 'HASH') ? %{ $_[0] } : @_; # <-- arg as hash or hashref
  
  my $n = scalar(@kv_pairs);
  ($n == 0) and die "no key/values supplied";
  ($n % 2 == 1) and die "Odd number of args - must be even key/values pairs (either LIST or HashRef)";
  
  my $data = $self->_deserialize_action_data;
  my %new  = ( %$data, @kv_pairs );
  
  $self->_serialize_set_new_action_data(\%new)
}

sub action_data_get {
  my $self = shift;
  my $key = shift or die "No key supplied.";
  $self->_deserialize_action_data->{$key}
}


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
