use strictures 1;
use Test::More;
use Test::Fatal;
use Sys::Hostname qw(hostname);

$ENV{OBJECT_REMOTE_TEST_LOGGER} = 1;

use Object::Remote::FromData;

my $connection = Object::Remote->connect('-');


like exception {
    my $remote = My::Data::TestClass->new::on($connection);
}, qr/Can't locate Not\/Found.pm in \@INC/, 'Should fail to load Not::Found';

done_testing;

__DATA__
package My::Data::TestClass;

use Moo;
use Not::Found;

