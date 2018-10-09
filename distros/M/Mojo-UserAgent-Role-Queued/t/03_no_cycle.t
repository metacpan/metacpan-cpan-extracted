use Mojo::Base -strict;
use Test::More;

use constant CAN_TEST_LEAKS => (eval { require Test::Memory::Cycle; })
  ? 1
  : undef;
if (CAN_TEST_LEAKS) {
  Test::Memory::Cycle->import();
  $SIG{'__WARN__'}
    = sub { warn $_[0] unless ($_[0] =~ /Unhandled type: (GLOB|REGEXP)/); };
}
else {
  plan skip_all => 'test requires Test::Memory::Cycle';
}

use Mojo::UserAgent;

use Mojolicious::Lite;

get '/:foo' => sub {
  my $c   = shift;
  my $foo = $c->stash('foo');
  $c->render(text => "Hello $foo");
};

my $ua = Mojo::UserAgent->new->with_roles('+Queued');
$ua->max_active(2);

# relative urls will be fetched from the Mojolicious::Lite app defined above
$ua->server->app(app);
$ua->server->app->log->level('fatal');

my @tests_p;
for my $name (qw(fred barney wilma peebles bambam dino)) {
  @tests_p
    = $ua->get_p("/$name")->then(sub { shift->res->content eq "Hello $name" });
}
memory_cycle_ok($ua, 'no cycles in UserAgent object');

Mojo::Promise->all(@tests_p)->wait;

done_testing();
