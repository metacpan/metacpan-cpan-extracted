package Perldoc::Server::Controller::Ajax::PerlSyntax;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use File::Spec;
use HTML::Entities;
use OpenThought;
use Perl::Tidy;

=head1 NAME

Perldoc::Server::Controller::Ajax::PerlSyntax - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
  my ( $self, $c ) = @_;

  my $id   = $c->req->param('id');
  my $code = $c->req->param($id);
  
  $code = decode_entities($code);

  my ($result,$error);
  perltidy(
    source      => \$code,
    destination => \$result,
    argv        => ['-html','-pre'],
    errorfile   => \$error,
    stderr      => File::Spec->devnull(),
  );
  
  $result =~ s!\$!&#36;!g;
  $result =~ s!\n*</?pre.*?>\n*!!g;
  $result =~ s!<span class="k">(.*?)</span>!($c->model('PerlFunc')->exists($1))?q(<a class="l_k" href=").qq(/functions/$1">$1</a>):$1!sge;
  $result =~ s!<span class="w">(.*?)</span>!($c->model('Pod')->find($1))?'<a class="l_w" href="/view/'.linkpath($1).qq(">$1</a>):$1!sge;

  my $output = '<ol>';
  my @lines = split(/\r\n|\n/,$result);
  foreach (@lines) {$output .= "<li>$_</li>"}
  $output .= '</ol>';

  push @{$c->stash->{openthought}}, {$id => $output};
  $c->detach('View::OpenThoughtTT');
}


sub linkpath {
  my $path = shift;
  $path =~ s!::!/!g;
  return $path;
}

=head1 AUTHOR

Jon Allen

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
