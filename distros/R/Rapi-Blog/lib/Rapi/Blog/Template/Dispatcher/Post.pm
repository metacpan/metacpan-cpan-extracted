package Rapi::Blog::Template::Dispatcher::Post;
use strict;
use warnings;

use RapidApp::Util qw(:all);
use Rapi::Blog::Util;
use List::Util;

use Date::Parse;

use Moo;
extends 'Rapi::Blog::Template::Dispatcher';

use Types::Standard ':all';

has '+claimed',  default => sub { 1 };
has '+restrict', default => sub { 1 };

has 'name',  is => 'ro', required => 1, isa => Str;
has 'direct', is => 'ro', isa => Bool, default => sub { 0 };

sub rank { (shift)->direct ? 60 : 50 }


sub resolved {
  my $self = shift;
  $self->exists ? $self : $self->_factory_for('NotFound')
}

has 'PostRs', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  $self->AccessStore->Model->resultset('Post')->permission_filtered
};



has '_post_loaded', is => 'rw', isa => Bool, default => sub { 0 };
has 'Post', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  if(my $Row = $self->PostRs->search_rs({ 'me.name' => $self->name })->first) {
    $self->_post_loaded(1);
    return $Row
  }
  undef
};


has '+exists', default => sub { 
  my $self = shift;
  return $self->Post ? 1 : 0 if ($self->_post_loaded);
  $self->PostRs->search_rs({ 'me.name' => $self->name })->count ? 1 : 0
};

has '+mtime', default => sub {
  my $self = shift;

  my $Row = $self->_post_loaded ? $self->Post : $self->PostRs
    ->search_rs(undef,{
      columns => ['update_ts']
    })
    ->search_rs({ 'me.name' => $self->name })
    ->first;

  $Row ? Date::Parse::str2time( $Row->get_column('update_ts') ) : undef
};


has '+content', default => sub { 
  my $self = shift;

  my $Row = $self->_post_loaded ? $self->Post : $self->PostRs
    ->search_rs(undef,{
      columns => ['body']
    })
    ->search_rs({ 'me.name' => $self->name })
    ->first;
  
  $Row ? $Row->get_column('body') : undef
};


has '+template_vars', default => sub {
  my $self = shift;
  
  my $data = {};
  $data->{Row} = $data->{Post} = $self->Post if ($self->Post);

  $data
};





1;