use Mojo::Base -strict;
use Mojo::File 'path';
use Mojolicious::Command::bulkget;
use Mojolicious;
use Mojo::File qw(tempdir tempfile);
use Test::More;

my $app = Mojolicious->new;
$app->routes->get(
  '/pets/:id' => sub {
    my $c   = shift;
    $c->render(text => 'ID: '. $c->stash('id'));
  }
);

my $cmd = Mojolicious::Command::bulkget->new(app => $app);

my $dir = tempdir;
my $sfile = $dir->child('suffixes');
$sfile->spurt("1\n2\n3\n");

like $cmd->description, qr{Perform bulk get requests}, 'description';
like $cmd->usage, qr{APPLICATION bulkget urlbase outdir suffixesfile}, 'usage';
eval { $cmd->run };
like $@, qr{APPLICATION bulkget urlbase outdir suffixesfile}, 'no arguments';

$cmd->run('/pets/', $$dir, $$sfile);
like $dir->child('2')->slurp, qr/ID: 2/, 'content got right';

done_testing;
