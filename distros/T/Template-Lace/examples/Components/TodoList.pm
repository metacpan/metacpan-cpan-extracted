package Components::TodoList;

use Moo;
use Template::Lace::Factory;

has 'tasks' => (is=>'ro', required=>1);

sub create_factory {
  my ($class, $tasks) = @_;
  return Template::Lace::Factory->new(
    model_class => $class,
    init_args => +{
      tasks=>$tasks,
    });
}

sub process_dom {
  my ($self, $dom) = @_;
  $dom->ol('#tasks', $self->tasks);
}

sub template {q[
  <ol id="tasks">
    <li>task...</li>
  </ol>
]}

1;
