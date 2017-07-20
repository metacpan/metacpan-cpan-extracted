package Components::Master;

use Moo;
use Template::Lace::Factory;
use Template::Lace::Utils 'mk_component';

has 'content' => (is=>'ro', required=>1);

sub create_factory {
  my ($class) = @_;
  return Template::Lace::Factory->new(
    model_class => $class);
}

sub process_dom {
  my ($self, $dom) = @_;
  $dom->at('#content')
   ->content($self->content);
}

sub template {q[
  <html>
    <head>
      <title>Todo List</title>
    </head>
    <body id='content'>
      [Content goes here]
    </body>
  </html>
]}

1;
