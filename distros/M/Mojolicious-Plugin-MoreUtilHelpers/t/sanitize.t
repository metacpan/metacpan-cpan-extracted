use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;

plugin 'MoreUtilHelpers';

my $html=<<HTML;
  <div>
    <h1>Hi!</h1>  
    <p>hello &amp; <span class="x">hello</span></p>
    <div>
      <a href="#">abc</a>
    </div>
  </div>     
HTML

get '/sanitize' => sub {
  my $self = shift;
  $self->render(text => $self->sanitize($html));
};

get '/sanitize_with_tags' => sub {
  my $self = shift;
  $self->render(text => $self->sanitize($html, tags => ['span']));
};

get '/sanitize_with_tags_and_attr' => sub {
  my $self = shift;
  $self->render(text => $self->sanitize($html, tags => ['span', 'a', 'p'], attr => ['href']));  
};

my $t = Test::Mojo->new;
$t->get_ok('/sanitize')->content_is('Hi! hello & hello abc');
$t->get_ok('/sanitize_with_tags')->content_like(qr'Hi!\s+hello &amp; <span class="x">hello</span>\s+abc');
$t->get_ok('/sanitize_with_tags_and_attr')->content_like(qr'Hi!\s+<p>hello &amp; <span>hello</span></p>\s+<a href="#">abc</a>');

done_testing();

