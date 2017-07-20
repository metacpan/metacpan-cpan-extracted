package TodoListApp;

use Page;
use Components::TodoList;
use Components::Master;
use Web::Simple;

my @list = ('Walk Dog');
my $todo_list_factory = Components::TodoList->create_factory(\@list);
my $master_factory = Components::Master->create_factory();
my $page_factory = Page->create_factory($todo_list_factory, $master_factory);

sub show_page {
  return [
    200,
    ['Content-type'=>'text/html'],
    [ $page_factory->render ]
  ];
}

sub dispatch_request {
  sub (/) {
    sub (GET) { shift->show_page },
    sub (POST + %:item=) {
      push @list, $_{item};
      shift->show_page;
    },
  }
}

__PACKAGE__->run_if_script;
