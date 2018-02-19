#003_open_api.t
use Mojo::Base -strict;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::Mojo::resources;    # load it from "$FindBin::Bin/lib"

our $tempdir = Test::Mojo::resources::tempdir;

Test::Mojo::resources::install_app();

require Blog;

# load Open_API into the generated application
my $test = Test::Mojo->new('Blog');
my $blog = $test->app;
{
  my $buffer = '';
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $blog->start('generate', 'resources', '-t' => 'users,groups');

  like($buffer, qr{\[write\].+?api[\\/]api.json}, "written api/api.json");
}

# If the loaded schema is valid, it is by itself a success!!!
ok($blog->plugin("OpenAPI" => {url => $blog->home->rel_file("api/api.json")}),
   'loaded Mojolicious::Plugin::OpenAPI');

for my $t (qw(groups users)) {
  my $class = "Blog::Model::" . Mojo::Util::camelize $t;
  Mojo::Loader::load_class $class;
  $blog->helper(
    $t => sub {
      state $table = $class->new(sqlite => shift->sqlite);
    }
  );
  ok($blog->renderer->get_helper($t), "\$blog has helper $t");

  # Make requests to the created routes
  #index
  $test->get_ok("/api/$t")->status_is(200)->json_is([]);

  # show
  my $id          = 1;
  my $get_ok_path = "/api/$t/$id";
  $test->get_ok($get_ok_path)->status_is(404)
    ->json_is('/errors' => [{path => $get_ok_path, message => 'Not Found'}]);

  # store
  my $form = {};
  if ($t eq 'groups') {
    $form = {name => 'g1', description => 'g1 description'};
    $test->post_ok("/api/$t" => {Accept => '*/*'}, form => $form)
      ->status_is(201)->header_is(Location => $get_ok_path);
    $test->get_ok($get_ok_path)->status_is(200)
      ->json_is('/name' => $form->{name})->json_is('/id' => $id);
  }
  elsif ($t eq 'users') {
    for my $uid (1 .. 5) {
      $form = {
               username => 'u' . $uid,
               group_id => $id,
               name     => 'Краси Беров' . $uid,
               about    => 'about u' . $uid
              };
      $test->post_ok("/api/$t" => {Accept => '*/*'}, form => $form)
        ->status_is(201);
      $test->get_ok("/api/$t/$uid")->status_is(200)
        ->json_is('/group_id' => $form->{group_id})->json_is('/id' => $uid);

      #index
      $test->get_ok("/api/$t")->status_is(200)
        ->json_is('/' . ($uid - 1) => {%$form, id => $uid});
    }
    $test->get_ok("/api/$t?limit=2")->json_is('/1/id' => 2);

    # ignored parameters, which are not in the api spec
    $test->get_ok("/api/$t?liMit=2&ofset=2")->json_is('/1/id' => 2);
    $test->get_ok("/api/$t?limit=2&offset=2")->json_is('/1/id' => 4);
  }

  # remove
  $test->delete_ok($get_ok_path)->status_is(204)->content_is('');
  $test->delete_ok($get_ok_path)->status_is(404)
    ->json_is('/errors' => [{path => $get_ok_path, message => 'Not Found'}]);
}    # end for my $t (qw(groups users))

done_testing;

