package Perldoc::Server::Controller::Index::Modules;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

Perldoc::Server::Controller::Index::Modules - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(1) {
  my ($self, $c, $search) = @_;
  
  my @modules = sort {uc $a cmp uc $b} $c->model('Index')->find_modules($search);
  
  $c->stash->{modules}       = \@modules;
  $c->stash->{title}         = "Modules ($search)";
  $c->stash->{page_template} = 'index_modules.tt';
  $c->stash->{breadcrumbs}   = [ {url=>$c->uri_for('/index/modules'), name=>'Modules'} ];
  $c->stash->{page_name}     = $search;
}


=head1 AUTHOR

Jon Allen

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
