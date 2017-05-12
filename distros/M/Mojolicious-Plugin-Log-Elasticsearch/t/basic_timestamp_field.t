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
  ok (defined $hash->{timestamp}, 'has timestamp');
  delete $hash->{time};
  delete $hash->{timestamp};
  is_deeply ($hash, $exp_json);
}

package main;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

my $coderef = sub { };
my $ekh = sub { &$coderef(@_); };

plugin 'Log::Elasticsearch', { elasticsearch_url => 'http://localhost:9200', index => 'foo', type => 'bar', timestamp_field => 'timestamp' };

get '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello Mojo!');
};

my $t = Test::Mojo->new;
my $ua = Mock::UA->new;
$t->app->ua($ua);

$ua->_posts_expected([ { code => '200', method=>'GET', ip => '127.0.0.1', path => '/' } ]);
$t->get_ok('/')->status_is(200)->content_is('Hello Mojo!');

done_testing();
