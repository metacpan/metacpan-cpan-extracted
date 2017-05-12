use Mojo::Base -strict;

package Mock::UA;

use Test::More;

my $posts = [];

sub new { bless {}, __PACKAGE__ }
sub _posts_expected { $posts = $_[1]; } 
sub post { 
  my $exp_json = shift @$posts || fail "too many posts?";
  my $hash = $_[3];
  ok (defined $hash->{time}, 'has time');
  delete $hash->{time};
  is_deeply ($hash, $exp_json);
}

package main;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

my $coderef = sub { };
my $ekh = sub { &$coderef(@_); };

plugin 'Log::Elasticsearch', { elasticsearch_url => 'http://localhost:9200', index => 'foo', type => 'bar', log_stash_keys => [qw/foo/], extra_keys_hook => $ekh  };

get '/' => sub {
  my $c = shift;
  $c->stash('foo' => 'bar');
  $c->render(text => 'Hello Mojo!');
};

my $t = Test::Mojo->new;
my $ua = Mock::UA->new;
$t->app->ua($ua);

$ua->_posts_expected([ { code => '200', method=>'GET', ip => '127.0.0.1', path => '/', foo => 'bar' } ]);
$t->get_ok('/')->status_is(200)->content_is('Hello Mojo!');

$ua->_posts_expected([ { code => '404', method=>'GET', ip => '127.0.0.1', path => '/floogle' } ]);
$t->get_ok('/floogle')->status_is(404);

# override a key with the hook
$coderef = sub { return ( path => '/custom' ) };
$ua->_posts_expected([ { code => '200', method=>'GET', ip => '127.0.0.1', path => '/custom', foo => 'bar' } ]);
$t->get_ok('/')->status_is(200)->content_is('Hello Mojo!');

# check that we can poke at the Mojolicious::Controller object in the hook
$coderef = sub { return tx => shift->tx ? 'yes' : 'no'; };
$ua->_posts_expected([ { code => '200', method=>'GET', ip => '127.0.0.1', path => '/', foo => 'bar', tx => 'yes' } ]);
$t->get_ok('/')->status_is(200)->content_is('Hello Mojo!');

done_testing();
