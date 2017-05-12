package Perldoc::Server::Controller::Functions;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

Perldoc::Server::Controller::Functions - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
  my ( $self, $c ) = @_;

  $c->response->redirect( $c->uri_for('/index/functions') );
}


sub view :Path :Args(1) {
  my ($self, $c, $function) = @_;

  # Count the page views in the user's session
  my $uri = "/functions/$function";
  $c->session->{counter}{$uri}{count}++;
  $c->session->{counter}{$uri}{name} = $function;
  
  $c->stash->{title}         = $function;
  $c->stash->{pod}           = $c->model('PerlFunc')->pod($function);
  $c->stash->{breadcrumbs}   = [ {url=>$c->uri_for('/index/functions'), name=>'Functions'} ];
  $c->stash->{page_template} = 'function.tt';
  $c->stash->{contentpage}   = 1;
  
  $c->forward('View::Pod2HTML');
}

=head1 AUTHOR

Jon Allen

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
