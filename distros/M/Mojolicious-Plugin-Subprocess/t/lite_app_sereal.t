use Mojolicious::Lite;
use Test::More;
use Test::Mojo;
use Test::Needs 'Mojo::IOLoop::Subprocess::Role::Sereal';

plugin 'Subprocess' => {use_sereal => 1};

get '/' => sub {
  my $c = shift;
  $c->subprocess(sub {
    return $$, qr/$$/;
  }, sub {
    my ($c, $pid, $re) = @_;
    $c->render(json => {child => $pid, parent => $$, ref => ref($re), re => "$re"});
  });
};

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200);
my $j = $t->tx->res->json;
cmp_ok $j->{child}, '!=', $j->{parent}, 'first sub run in subprocess';
cmp_ok $j->{parent}, '==', $$, 'second sub run in parent process';
is $j->{ref}, 'Regexp', 'serialized regex ref';
like $j->{re}, qr/\Q$j->{child}/, 'serialized regex ref contents';

done_testing;
