use warnings;
use strict;
use Test::More;
use Test::Moose 2.1405;
use Moose 2.1405;

require_ok('Net::SSH::Putty');

my $instance = Net::SSH::Putty->new({ user => 'foo', password => 'bar', host => 'localhost' });
ok($instance, 'instance can be created');

my @attribs = (qw(user password host putty_path output));

foreach my $attrib (@attribs) {
    has_attribute_ok( $instance, $attrib, "instance has attribute $attrib" );
}

my @methods = (qw(get_user get_password get_host get_putty_path get_output exec _read_out download read_log));

foreach my $method (@methods) {
    can_ok( $instance, $method );
}

is($instance->get_user,'foo');
is($instance->get_password, 'bar');
is($instance->get_host,'localhost');
is(ref($instance->get_output),'ARRAY');

done_testing;