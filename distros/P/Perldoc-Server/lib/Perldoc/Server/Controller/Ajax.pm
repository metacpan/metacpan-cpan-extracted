package Perldoc::Server::Controller::Ajax;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

Perldoc::Server::Controller::Ajax - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub clear_most_viewed :Local :Args(0) {
  my ($self, $c) = @_;
  
  $c->session->{counter} = {};
  push @{$c->stash->{openthought}}, {most_viewed => ''};
  $c->detach('View::OpenThoughtTT');
}


=head1 AUTHOR

Jon Allen

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
