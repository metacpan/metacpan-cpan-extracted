package Page;

use Moo;
use Template::Lace::Factory;

has 'list' => (is=>'ro', required=>1);

sub create_factory {
  my ($class, $list) = @_;
  return Template::Lace::Factory->new(
    model_class => $class,
    init_args => +{list=>$list} );
}

sub process_dom {
  my ($self, $dom) = @_;
  $dom->ol('#items', $self->list);
}

sub template {q[
  <html>
    <head>
      <title>Todo List</title>
    </head>
    <body>
      <h1>Todos</h1>
      <form method="POST">
        <input name="item">
      </form>
      <ol id="items">
        <li>item...</li>
      </ol>
    </body>
  </html>
]}

1;
