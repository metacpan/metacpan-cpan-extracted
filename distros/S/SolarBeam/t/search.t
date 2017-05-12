use strict;
use warnings;

use Mojo::UserAgent;
use Mojolicious;
use Test::More 'no_plan';
use_ok 'SolarBeam';

my $sb = SolarBeam->new;
my $res;

$sb->ua->server->app(app());
$sb->url($sb->ua->server->nb_url);

#$mock->expect("/select", wt => 'json', q => 'hello');
$sb->search("hello", sub { $res = pop; Mojo::IOLoop->stop; });
Mojo::IOLoop->start;

#$mock->expect(
#  "/terms",
#  wt                 => 'json',
#  terms              => 'true',
#  'terms.fl'         => 'artifact.name',
#  'terms.regex'      => 'ost\w+',
#  'terms.regex.flag' => 'case_insensitive'
#);

$sb->autocomplete('ost', fl => 'artifact.name', sub { Mojo::IOLoop->stop; });
Mojo::IOLoop->start;

#$mock->expect(
#  "/terms",
#  wt                 => 'json',
#  terms              => 'true',
#  'terms.fl'         => 'artifact.name',
#  'terms.regex'      => 'ost.*',
#  'terms.regex.flag' => 'case_insensitive'
#);

$sb->autocomplete('ost', -postfix => '.*', fl => 'artifact.name', sub { Mojo::IOLoop->stop; });
Mojo::IOLoop->start;

ok(!$sb->ua->{expect});

#package UserAgentMock;
#use Test::More;
#
#sub new {
#  bless {}, 'UserAgentMock';
#}
#
#sub expect {
#  my $self = shift;
#  $self->{expect} = \@_;
#}
#
#sub get {
#  my ($self, $url, $cb) = @_;
#  my $expect = delete $self->{expect};
#  ok($expect);
#  my ($path, %query) = @{$expect};
#  is($url->path, $path);
#  is_deeply($url->query->to_hash, \%query);
#}
#
#sub post {
#  my $self = shift;
#
#  # Re-implement post from Mojo::UserAgent without callback support though
#  my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
#  my $tx = Mojo::UserAgent->new->build_tx('POST', @_);
#  my $expect = delete $self->{expect};
#
#  ok($expect);
#  my ($path, %query) = @{$expect};
#
#  is($tx->req->url->path, $path);
#  is_deeply($tx->req->params->to_hash, \%query);
#}

sub app {
  my $app = Mojolicious->new;

  $app->routes->get(
    '/query' => sub {
      my $c = shift;
      warn "............";
      $c->render(json => {});
    }
  );

  $app->routes->post(
    '/select' => sub {
      my $c = shift;
      $c->render(json => {});
    }
  );

  return $app;
}
