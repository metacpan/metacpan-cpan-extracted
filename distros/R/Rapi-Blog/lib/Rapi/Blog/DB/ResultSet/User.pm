package Rapi::Blog::DB::ResultSet::User;

use strict;
use warnings;

use Moo;
extends 'DBIx::Class::ResultSet';

use RapidApp::Util ':all';

sub enabled {
  (shift)
    ->search_rs({ 'me.disabled' => 0 })
}

sub authors {
  (shift)
    ->search_rs({ -or => [{ 'me.author' => 1 },{ 'me.admin' => 1 }]})
}

sub commenters {
  (shift)
    ->search_rs({ -or => [{ 'me.comment' => 1 },{ 'me.admin' => 1 }]})
}

__PACKAGE__->load_components('+Rapi::Blog::DB::Component::ResultSet::ListAPI');

sub _api_default_params {{ limit => 200, only => 'authors' }}
sub _api_param_arg_order { [qw/search only/] } 

# Method exposed to templates:
sub list_users {
  my ($self, @args) = @_;
  
  my $P = $self->_list_api_params(@args);
  
  my $Rs = $self;
  
  if($P->{only}) {
    if($P->{only} eq 'authors') {
      $Rs = $Rs->authors;
    }
    elsif($P->{only} eq 'commenters') {
      $Rs = $Rs->commenters;
    }
  }
  
  $Rs = $Rs->search_rs({ -or => [
    { 'me.username'  => { like => join('','%',$P->{search},'%') } },
    { 'me.full_name' => { like => join('','%',$P->{search},'%') } },
  ]}) if ($P->{search});
  
  return $Rs->_list_api;
}


1;
