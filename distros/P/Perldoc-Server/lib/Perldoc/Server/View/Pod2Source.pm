package Perldoc::Server::View::Pod2Source;

use strict;
use warnings;
use parent 'Catalyst::View';

use Perl::Tidy;


sub process {
  my ($self,$c) = @_;
  
  my ($result,$error);
  my $code = $c->stash->{pod};
  perltidy(
    source      => \$code,
    destination => \$result,
    argv        => ['-html','-pre'],
    errorfile   => \$error,
  ); 
  
  $result =~ s!\n*</?pre.*?>\n*!!g;
  $result =~ s!<span class="k">(.*?)</span>!($c->model('PerlFunc')->exists($1))?q(<a class="l_k" href=").qq(/functions/$1">$1</a>):$1!sge;
  $result =~ s!<span class="w">(.*?)</span>!($c->model('Pod')->find($1))?'<a class="l_w" href="/view/'.linkpath($1).qq(">$1</a>):$1!sge;

  my $output = '<ol>';
  open my $fh,'<',\$result;
  while (<$fh>) {$output .= "<li>$_</li>"}
  $output .= '</ol>';
  
  $c->stash->{pod}           = $output;
  $c->stash->{page_template} = 'pod2source.tt';  
  $c->forward('View::TT');
}


sub linkpath {
  my $path = shift;
  $path =~ s!::!/!g;
  return $path;
}

=head1 NAME

Perldoc::Server::View::Pod2Source - Catalyst View

=head1 DESCRIPTION

Catalyst View.

=head1 AUTHOR

Jon Allen

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
