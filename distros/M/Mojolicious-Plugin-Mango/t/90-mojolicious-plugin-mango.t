use Modern::Perl;
use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Try::Tiny;
try {
  use Mango;
  my $mango = Mango->new('mongodb://localhost:27017');
  $mango->db("test")->stats;
}
catch {
  plan skip_all => 'Cannot test because connection failed';
}
finally {
  no Mango;
};

my $default_db = 'mojolicious-plugin-mango';
plugin 'Mango', {
  mango => 'mongodb://localhost:27017/test?w=2',
  helper => 'foo',
  default_db => $default_db,
  no_query => 1,
};

for my $helper (qw/_mango mango/) {
  get "/$helper" => sub {
    my $self = shift;
    $self->render(text => ref $self->app->$helper);
  };
}

get '/getdb' => sub {
  my $self = shift;
  $self->render(text => $self->foo->name);
};

my $otherdb = 'xhofadFA';
get '/otherdb' => sub {
  my $self = shift;
  $self->render(text => $self->foo($otherdb)->name);
};
my $coll = 'mojolicious-plugin-mango-coll';
get '/foo_collection' => sub {
  my $self = shift;
  my $db = $self->foo;
  my $collection = $db->collection($coll);
  $self->render(text => $collection->name);
};
get '/coll' => sub {
  my $self = shift;
  $self->coll($coll)->ensure_index({foo => 1});
  $self->render(text => $self->coll($coll)->name);
};

get '/coll/:name' => sub {
  my $self = shift;
  $self->render(text => $self->coll($self->param('name'))->name);
};

get '/collection' => sub {
  my $self = shift;
  $self->render(text => $self->collection($coll)->name);
};
get '/collection_names' => sub {
  my $self = shift;
  $self->render(text => join ',', @{$self->collection_names});
};

get '/stats' => sub {
  my $self = shift;
  $self->stats(
    sub {
      my ($db, $err, $stats) = @_;
      $self->render(json => $stats);
    }
  );
};
my $t = Test::Mojo->new;
$t->get_ok('/mango')->status_is(200)->content_is('Mango');
$t->get_ok('/_mango')->status_is(200)->content_is('Mango');
$t->get_ok('/getdb')->status_is(200)->content_is($default_db);
$t->get_ok('/otherdb')->status_is(200)->content_is($otherdb);
$t->get_ok('/foo_collection')->status_is(200)->content_is($coll);
$t->get_ok('/coll')->status_is(200)->content_is($coll);
$t->get_ok('/coll/dafadgadga')->status_is(200)->content_is('dafadgadga');
$t->get_ok('/collection')->status_is(200)->content_is($coll);
$t->get_ok('/collection_names')->status_is(200)->content_like(qr/$coll.\$_id_/)->content_like(qr/$coll.\$foo/);
$t->get_ok('/stats')->status_is(200)->json_has('collections');

done_testing;

