use strict;
use warnings;

use Test::More;
use Mojolicious;
use File::Temp ();
use Test::Mojo;

# The private routines are guarded by Sub::Private (enforce mode) and the
# extension points by Sub::Protected.  Both stand aside while HARNESS_ACTIVE
# is set, so switch that bypass off here to test the guards themselves.

use Mojolicious::Plugin::Buffer;
use Mojolicious::Plugin::Buffer::I18N;
use Mojolicious::Plugin::Buffer::Lock::File;
use Mojolicious::Plugin::Buffer::Lock::Redis;

$Sub::Private::config{harness_bypass} = 0;
$Sub::Protected::config{harness_bypass} = 0;

# A subclass may reach the protected extension points
{
	package My::Buffer;
	use Mojo::Base 'Mojolicious::Plugin::Buffer';

	our $optimised = 0;
	sub _optimise {
		my ($self, @args) = @_;
		$optimised++;
		return $self->SUPER::_optimise(@args);
	}
}

subtest 'private routines cannot be called from outside' => sub {
	for my $call (
		['Mojolicious::Plugin::Buffer', '_squash', '<p> x </p>'],
		['Mojolicious::Plugin::Buffer', '_negotiate_encoding', 'gzip', ['gzip']],
		['Mojolicious::Plugin::Buffer', '_mime_type', 'text/html'],
		['Mojolicious::Plugin::Buffer::I18N', '_interpolate', 'x', {}],
		['Mojolicious::Plugin::Buffer::Lock::File', '_os_error', 'x'],
		['Mojolicious::Plugin::Buffer::Lock::Redis', '_valid_client', sub {}],
	) {
		my ($package, $name, @args) = @$call;
		my $code = $package->can($name);
		ok($code, "${package}::$name exists");
		eval { $code->(@args) };
		like($@, qr/private subroutine/, "${package}::$name is private");
	}
};

subtest 'protected routines are open to subclasses only' => sub {
	my $plugin = Mojolicious::Plugin::Buffer->new;
	eval { $plugin->_optimise('<p>x</p>', undef, {optimise_content => 0}) };
	like($@, qr/protected/i, '_optimise cannot be called from outside');

	my $lock = Mojolicious::Plugin::Buffer::Lock::File->new(dir => File::Temp::tempdir(CLEANUP => 1));
	eval { $lock->_path('key') };
	like($@, qr/protected/i, 'Lock::File::_path cannot be called from outside');

	# Through a subclass the protected method is reachable and overridable
	my $app = Mojolicious->new;
	$app->log->level('fatal');
	$app->plugin('My::Buffer', optimise_content => 1);
	$app->routes->get('/' => sub { shift->render(text => "<p>  hello  </p>\n  <p>world</p>") });

	my $t = Test::Mojo->new($app);
	$t->get_ok('/')->status_is(200);
	is($My::Buffer::optimised, 1, 'the subclass override ran and called the parent');
};

subtest 'the public interface still works with the guards on' => sub {
	my $app = Mojolicious->new;
	$app->log->level('fatal');
	$app->plugin('Buffer', optimise_content => 1, cache => TestCache->new);
	$app->routes->get('/' => sub {
		my $c = shift;
		return if $c->buffer_is_cached;
		$c->render(text => "<p>  cached  </p>\n  <p>page</p>" x 5);
	});

	my $t = Test::Mojo->new($app);
	$t->get_ok('/' => {'Accept-Encoding' => 'gzip'})->status_is(200)->header_is('X-Cache' => 'MISS');
	$t->get_ok('/' => {'Accept-Encoding' => 'gzip'})->status_is(200)->header_is('X-Cache' => 'HIT');
	ok($t->tx->res->headers->etag, 'the hit has an ETag');

	is(Mojolicious::Plugin::Buffer::I18N->i18n('unknown_error'), 'unknown error', 'i18n is public');
};

done_testing();

package TestCache;


sub new { bless {}, shift }
sub get { $_[0]->{$_[1]} }
sub set { $_[0]->{$_[1]} = $_[2]; 1 }
sub remove { delete $_[0]->{$_[1]} }
