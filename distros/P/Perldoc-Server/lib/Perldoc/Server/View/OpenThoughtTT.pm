package Perldoc::Server::View::OpenThoughtTT;

use strict;
use base 'Catalyst::View::TT';
use NEXT;
use OpenThought;

__PACKAGE__->config(TEMPLATE_EXTENSION => '.tt');


sub process {
  my ($self, $c) = @_;
  
#  unless ($c->stash->{openthought}) {
#    $c->forward('View::TT');
#    return;
#  }
  
  my $ot       = OpenThought->new();
  my @elements = @{$c->stash->{openthought}};
  
  foreach my $element (@elements) {
    my ($target,$value) = each %$element;
#    if ($value =~ /\.tt$/) {
#      $c->stash->{template} = $value;
#      $self->NEXT::process($c);
#      $ot->param( {$target => $c->response->body} );
#    } else {
      $ot->param( {$target => $value} );
#    }
  }
  
  $c->response->body($ot->response);
}

=head1 NAME

Perldoc::Server::View::OpenThoughtTT - Catalyst View

=head1 DESCRIPTION

Catalyst View.

=head1 AUTHOR

Jon Allen

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
