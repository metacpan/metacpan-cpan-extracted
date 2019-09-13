package Rapi::Blog::DB::ResultSet::PreauthActionEvent;

use strict;
use warnings;

use Moo;
extends 'DBIx::Class::ResultSet';

use RapidApp::Util ':all';
use Rapi::Blog::Util;

sub schema { (shift)->result_source->schema }

sub create_with_request {
  my ($self, $request, $cr) = @_;
  $cr ||= {};
  
  die "->create_with_hit(): hit/id already set!" if ($cr->{hit_id} || $cr->{hit});
  
  my $Hit = $self->schema->resultset('Hit')->create_from_request({},$request);
  $self->create_with_hit($Hit,$cr)
}


sub create_with_hit {
  my ($self, $Hit, $cr) = @_;
  $cr ||= {};
  
  die "->create_with_hit(): hit/id already set!" if ($cr->{hit_id} || $cr->{hit});
  
  $cr->{hit} = $Hit;
  $cr->{ts} ||= $Hit->get_column('ts');
    
  $self->create( $cr )
}


1;
