use Mojo::Base -strict;
use Test::More;
use Mojo::UserAgent;
use Mojo::Promise;

plan skip_all => "Test requires IO::Socket::SSL 2.009+"
  unless (Mojo::IOLoop::TLS->can_tls);

# test that ua isn't acting as a singleton when this role is applied,
# based on examples/tyldum.pl (from github issue #4)
# this test should pass in version 1.11+ but fail in 1.10

package testbase;
use Mojo::Base -base;

has ua => sub { Mojo::UserAgent->new; };

sub poll {
  my ($self) = shift;
  return $self->ua->get_p("https://untrusted-root.badssl.com/")->then(
    sub { Mojo::Promise->new->resolve(shift->res->message); },
    sub {
      my $err = shift;
      plan(skip_all => "Test requires network") unless ($err =~ /SSL/);
      Mojo::Promise->new->resolve($err);
    }
  );
}

package testbase::insecure;
use Mojo::Base 'testbase';

package testbase::secure;
use Mojo::Base 'testbase';


package main;

my $insecure = testbase::insecure->new(ua => Mojo::UserAgent->new->insecure(1));
my $secure = testbase::secure->new(ua => Mojo::UserAgent->new);


my $insecure_q = testbase::insecure->new(
  ua => Mojo::UserAgent->new->with_roles('+Queued')->insecure(1));
my $secure_q
  = testbase::secure->new(ua => Mojo::UserAgent->new->with_roles('+Queued'));

sub status_test {
  my ($first, $second) = @_;
  is(scalar @_,   2,    'got 2 results');
  is($first->[0], 'OK', 'insecure works');
  like($second->[0], qr/SSL connect attempt failed/, 'secure fails');
}

# Works. $insecure works, $secure fails as expected.
Mojo::Promise->all($insecure->poll, $secure->poll)
  ->then(sub { status_test(@_) })->wait();

# Both these succeed, one should fail
Mojo::Promise->all($insecure_q->poll, $secure_q->poll)
  ->then(sub { status_test(@_) })->wait();

done_testing();
