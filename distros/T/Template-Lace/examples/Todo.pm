package Todo;

use Web::Simple;
use Page;

my @list = ('Walk Dog');
my $factory = Page->create_factory(\@list);

sub show_page {
  return [
    200,
    ['Content-type'=>'text/html'],
    [ $factory->render ]
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
