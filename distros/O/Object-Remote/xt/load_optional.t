use strictures 1;
use Test::More;
use Test::Fatal;
use Sys::Hostname qw(hostname);

$ENV{OBJECT_REMOTE_TEST_LOGGER} = 1;

use Object::Remote::FromData;

my $connection = Object::Remote->connect('-');


is exception {
    my $remote = My::Data::TestClassLoad->new::on($connection);
    is($remote->counter, 0, 'Counter at 0');
    is($remote->increment, 1, 'Increment to 1');
    is($remote->has_missing_module, 0, 'Shouldn\'t have loaded module');
}, undef, 'Checking Class::Load load_optional_class works correctly.';

is exception {
    my $remote = My::Data::TestModuleRuntime->new::on($connection);
    is($remote->counter, 0, 'Counter at 0');
    is($remote->increment, 1, 'Increment to 1');
    like exception {
        my $o = $remote->create_object;
    }, qr/Can't locate Not\/Found.pm in \@INC/, 'Should fail to load Not::Found';

}, undef, 'Checking Module::Runtime use_package_optimistically works correctly.';

done_testing;

__DATA__
package My::Data::TestClassLoad;

use Moo;
use Class::Load 'load_optional_class';

use constant HAS_MISSING_MODULE => load_optional_class('Not::Found');

has counter => (is => 'rwp', default => sub { 0 });

sub increment { $_[0]->_set_counter($_[0]->counter + 1); }

sub has_missing_module { HAS_MISSING_MODULE };

package My::Data::TestModuleRuntime;

use Moo;
use Module::Runtime 'use_package_optimistically';

use constant HAS_MISSING_MODULE => use_package_optimistically('Not::Found');

has counter => (is => 'rwp', default => sub { 0 });

sub increment { $_[0]->_set_counter($_[0]->counter + 1); }

sub create_object { use_package_optimistically('Not::Found')->new() };
