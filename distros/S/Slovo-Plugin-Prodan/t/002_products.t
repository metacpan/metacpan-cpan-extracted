# t/002_products.t - create some products read on the site, update them and again rad them
use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Mojo::File qw(path tempdir);
use Mojo::Util qw(decode encode);
use YAML::XS;

BEGIN {
  $ENV{MOJO_CONFIG} = path(__FILE__)->dirname->to_abs->child('slovo.conf');
};
note $ENV{MOJO_CONFIG};
my $install_root = tempdir('slovoXXXX', TMPDIR => 1, CLEANUP => 1);
my $t            = Test::Mojo->with_roles('+Slovo')->install(

# from => to
  undef() => $install_root,

# 0777
)->new('Slovo');
my $app = $t->app;

# note explain $app->config->{load_plugins}[1]{MojoDBx};
my $c        = $app->build_controller;
my $stranici = $c->stranici;
my $celini   = $c->celini;
isa_ok($app,      'Slovo');
isa_ok($stranici, 'Slovo::Model::Stranici');
note $app->home;

my @books      = qw(лечителката матере-нашѧ-параскеви);
my $book_pages = sub {

# Create a "Books" page in which the products' celini will be added. Add them
# then read them to see if they are displayed well. Then add some products
# to the respective celini, on the command line.
  my $page_id = $stranici->add({
    title       => 'Книги',
    language    => 'bg',
    body        => '<p>Книгите под този ред</p>',
    data_format => 'html',
    user_id     => 5,
    group_id    => 5,
    changed_by  => 5,
    alias       => 'книги',
    permissions => '-rwxrwxr-x',
    published   => 2
  });
  my $page = $stranici->find_for_edit($page_id, 'bg');
  ok($page => 'we have a page');

  #note explain $page;

# Create celini in which the products will be displayed via a template
  for (@books) {
    $celini->add({
      pid         => $page->{title_id},
      page_id     => $page->{id},
      data_type   => 'book',
      title       => $_,
      language    => 'bg',
      body        => "<p>книга $_</p>",
      data_format => 'html',
      user_id     => 5,
      group_id    => 5,
      changed_by  => 5,
      alias       => $_,
      permissions => '-rwxrwxr-x',
      published   => 2
    });
    $t->get_ok("/книги/$_.bg.html")->status_is(200)->element_exists('h1')
      ->text_is('h1' => $_);
  }
};

# insert products into the database
my $product_command = sub {
  my $COMMAND = 'Slovo::Command::prodan::products';
  require_ok($COMMAND);
  my $command = $COMMAND->new(app => $app);
  isa_ok($command => 'Slovo::Command');

# Default run
  my $buffer = '';
  {
    open my $handle, '>', \$buffer;
    local *STDOUT = $handle;
    local *STDERR = $handle;
    $command->run;
  }

# note $buffer;
  like $buffer => qr/Not\simplemented/x => 'list action is not implemented yet';
  like $buffer => qr/prodan/x           => 'prodan in $buffer';
  like $buffer => qr/products/x         => 'products in $buffer';

# Add products
  $buffer = '';
  {
    open my $handle, '>', \$buffer;
    local *STDOUT = $handle;
    local *STDERR = $handle;
    $COMMAND->new(app => $app)->run('create');
  }

  like $buffer => qr/Please profide a YAML file/ => 'right error message';
  like $buffer => qr/products\screate/x          => 'shown usage';

  $buffer = '';
  {
    open my $handle, '>', \$buffer;
    local *STDOUT = $handle;
    local *STDERR = $handle;
    $COMMAND->new(app => $app)->run('create', '-f' => 't/products.yaml');
  }

  like decode(utf8 => $buffer) => qr/Inserting лечителката/ =>
    'right message for create action';
  my @titles = (
    'Лечителката и рунтавата ѝ котка',
    'Житие на света Петка Българска от свети патриарх Евтимий'
  );
  my @paper_prices = ('14.00', '7.00');

  # see the products on the pages
  for (0 .. @books - 1) {

    my $body
      = $t->get_ok("/книги/$books[$_].bg.html")->status_is(200)->element_exists('h1')
      ->text_like('table#meta tr:first-child th' => qr/^Заглавие/)
      ->text_like('table#meta tr:first-child td' => qr/$titles[$_]/i => 'right title')

      # get the price
      ->text_like(
      'table#meta tr.price td' => qr/$paper_prices[$_]/ => 'right paper price')
      ->tx->res->body;

    #note $body;
  }


  # Update products
  note 'Update products';
  $buffer = '';
  {
    open my $handle, '>', \$buffer;
    local *STDOUT = $handle;
    local *STDERR = $handle;
    $COMMAND->new(app => $app)->run('update');
  }

  like $buffer => qr/Please profide a YAML file/ => 'right error message';
  like $buffer => qr/products\supdate/x          => 'shown usage';

  my $update_yaml = path(__FILE__)->dirname->to_abs->child('update_products.yaml');
  $buffer = '';
  {
    open my $handle, '>', \$buffer;
    local *STDOUT = $handle;
    local *STDERR = $handle;
    $COMMAND->new(app => $app)->run('update', '-f' => $update_yaml);
  }

  # note $buffer;
  like decode(utf8 => $buffer) => qr/Updating лечителката/ =>
    'right message for update action';
  my $updated = YAML::XS::LoadFile($update_yaml);
  for (@$updated) {

    # note explain $_;
    my $body
      = $t->get_ok("/книги/$_->{alias}.bg.html")->status_is(200)->element_exists('h1')
      ->text_like('table#meta tr:first-child th' => qr/^Заглавие/)
      ->text_is('table#meta tr:first-child td' => $_->{title} => 'right title')

      # get the price
      ->text_like('table#meta tr.price td' => qr/$_->{properties}{price} лв. за/ =>
        'right paper price')->tx->res->body;
  }
};


subtest 'celini on stranica for books' => $book_pages;
subtest 'products command'             => $product_command;


done_testing();

