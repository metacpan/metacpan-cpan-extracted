use strictures 1;
use Test::More;
use Sys::Hostname qw(hostname);

$ENV{OBJECT_REMOTE_TEST_LOGGER} = 1;

use Object::Remote::FromData;

my $connection = Object::Remote->connect('-');

my $remote = My::Data::TestClass->new::on($connection);

is($remote->counter, 0, 'Counter at 0');

is($remote->increment, 1, 'Increment to 1');

is($remote->counter, 1, 'Counter at 1');

is(
  My::Data::TestPackage->can::on($connection, 'hostname')->(),
  hostname(),
  'Remote sub call ok'
);

done_testing;

__DATA__
package My::Data::TestClass;

use Moo;

has counter => (is => 'rwp', default => sub { 0 });

sub increment { $_[0]->_set_counter($_[0]->counter + 1); }

package My::Data::TestPackage;

use Sys::Hostname;
