package Rapi::Blog::DB::ResultSet::Hit;

use strict;
use warnings;

use Moo;
extends 'DBIx::Class::ResultSet';

use RapidApp::Util ':all';
use Rapi::Blog::Util;

use YAML::XS;

sub create_from_request {
  my ($self, $create, $request) = @_;
  $create ||= {};

  $create = { %$create,
    client_ip          => scalar $request->address,
    uri                => scalar $request->uri,
    method             => scalar $request->method,
    user_agent         => scalar $request->header('User-Agent'),
    referer            => scalar $request->header('Referer'),
    
    # Not sure if this is worth it or not:
    #serialized_request => do { try{
    #  my $x = bless { %$request }, ref($request);
    #  delete $x->{_context};
    #  YAML::XS::Dump($x)
    #}}
    
  } if ($request);
  
  $create->{ts} ||= Rapi::Blog::Util->now_ts;
  
  $self->create( $create )
}



1;
