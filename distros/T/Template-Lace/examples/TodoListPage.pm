package TodoListPage;

use Moo;
use Template::Lace::Factory;

sub create_factory {
  my ($class, $list_todo_factory, $master_factory) = @_;
  return Template::Lace::Factory->new(
    model_class => $class,
    init_args => +{
      list_todo_factory=>$list_todo_factory,
    },
    component_handlers => +{
      layout => +{
        master => $master_factory,
      },
      todo => +{
        list => $list_todo_factory,
      },
    },
  );
}

sub process_dom {
  my ($self, $dom) = @_;
}

sub template {q[
  <layout-master>
    <h1>Todos</h1>
    <form method="POST">
      <input name="item">
    </form>
    <todo-list />
  </master>
]}

1;
