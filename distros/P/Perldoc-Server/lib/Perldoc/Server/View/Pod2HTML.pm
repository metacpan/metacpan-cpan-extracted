package Perldoc::Server::View::Pod2HTML;

use strict;
use warnings;
use 5.010;
use parent 'Catalyst::View::TT';

use Perldoc::Server::Convert::html;

sub process {
  my ($self,$c) = @_;
  
  $c->stash->{pod2html}        = Perldoc::Server::Convert::html::convert($c, $c->stash->{title}, $c->stash->{pod});
  $c->stash->{page_index}      = Perldoc::Server::Convert::html::index($c, $c->stash->{title}, $c->stash->{pod});
  $c->stash->{page_template} //= 'pod2html.tt';
  
  $c->forward('View::TT');
}


=head1 NAME

Perldoc::Server::View::Pod2HTML - Catalyst View

=head1 DESCRIPTION

Catalyst View.

=head1 AUTHOR

Jon Allen

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
