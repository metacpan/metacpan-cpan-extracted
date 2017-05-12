use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;

plugin 'MoreUtilHelpers';

sub text { join shift, qw|a b c| }

get '/paragraphs_lf' => sub {
  my $self = shift;
  $self->render(text => $self->paragraphs(text("\012")));
};

get '/paragraphs_lf_lf' => sub {
  my $self = shift;
  $self->render(text => $self->paragraphs(text("\012\012")));
};

get '/paragraphs_trailing_lf_lf' => sub {
  my $self = shift;
  $self->render(text => $self->paragraphs(text("\012\012") . "\012\012"));
};

get '/paragraphs_crlf' => sub {
  my $self = shift;
  $self->render(text => $self->paragraphs(text("\015\012")));
};

get '/paragraphs_crlf_crlf' => sub {
  my $self = shift;
  $self->render(text => $self->paragraphs(text("\015\012\015\012")));
};

my $t = Test::Mojo->new;
$t->get_ok('/paragraphs_lf')->content_is("<p>a\012b\012c</p>");
$t->get_ok('/paragraphs_lf_lf')->content_is("<p>a\012</p><p>b\012</p><p>c</p>");
$t->get_ok('/paragraphs_trailing_lf_lf')->content_is("<p>a\012</p><p>b\012</p><p>c\012</p>");
$t->get_ok('/paragraphs_crlf')->content_is("<p>a\015\012b\015\012c</p>");
$t->get_ok('/paragraphs_crlf_crlf')->content_is("<p>a\015\012</p><p>b\015\012</p><p>c</p>");

done_testing();
