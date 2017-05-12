package Perldoc::Server::Controller::Search;

use strict;
use warnings;
use 5.010;
use parent 'Catalyst::Controller';

=head1 NAME

Perldoc::Server::Controller::Search - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
  my ($self, $c) = @_;

  if (my $query = $c->req->param('q')) { 
    my @functions = $c->model('PerlFunc')->list;
    my @pages     = sort {$a cmp $b} $c->model('Index')->find_modules;

    given ($query) {
      when (@functions) {
        return $c->response->redirect( $c->uri_for('/functions',$query) );
      }
      when (@pages) {
        return $c->response->redirect( $c->uri_for('/view',split('::',$query)) );
      }
      when (/^($query)$/i ~~ @pages) {
        my $matched_page = $1;
        return $c->response->redirect( $c->uri_for('/view',split('::',$matched_page)) );
      }
      when (/^($query.*)$/i ~~ @pages) {
        my $matched_page = $1;
        return $c->response->redirect( $c->uri_for('/view',split('::',$matched_page)) );
      }
    }
    
    $c->stash->{query} = $query;
  }
  
  $c->stash->{page_name}     = 'Search results';
  $c->stash->{page_template} = 'search_results.tt';
}


=head1 AUTHOR

Jon Allen

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
