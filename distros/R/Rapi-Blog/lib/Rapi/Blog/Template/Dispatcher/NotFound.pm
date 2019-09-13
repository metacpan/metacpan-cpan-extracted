package Rapi::Blog::Template::Dispatcher::NotFound;
use strict;
use warnings;

use RapidApp::Util qw(:all);
use Rapi::Blog::Util;
use List::Util;

use Moo;
extends 'Rapi::Blog::Template::Dispatcher';

use Types::Standard ':all';


sub rank { 20 }

has 'exist_in_Provider', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  $self->AccessStore->Controller->get_Provider->template_exists_locally($self->path)
}, isa => Bool;


sub resolved {
  my $self = shift;
  $self->valid_not_found_tpl && ! $self->exist_in_Provider ? $self : $self->_factory_for('Unclaimed')
}


has '+maybe_psgi_response', default => sub {
  my $self = shift;
  
  # Should be redundant since we already checked this when we claimed the path
  my $tpl = $self->valid_not_found_tpl or die "unexpected error, we no longer have a valid_not_found_template";
  
  # Make sure the same Scaffold handles the 404 not found:
  $self->ctx->stash->{rapi_blog_only_scaffold_uuid} = $self->Scaffold->uuid;
  
  # Needed to prevent deep recursion when the not found template is private:
  $self->ctx->stash->{rapi_blog_detach_404_template}++ and return undef;
  
  $self->ctx->res->status(404);
  $self->ctx->detach( '/rapidapp/template/view', [$tpl] )
  
};
  
  
  
  



1;