# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-Int-Stats.t'

#########################

use Test::More tests => 5;

# test if linux platform
ok($^O =~ /linux/, 'OS check') || BAIL_OUT("OS unsupported");

# does /sbin/ifconfig exist?
ok(-e '/sbin/ifconfig', '/sbin/ifconfig test') || BAIL_OUT('Does /sbin/ifconfig exist?'); 

# load module
BEGIN { use_ok('Net::Int::Stats') };

# check object class
my $obj = Net::Int::Stats->new();
isa_ok($obj, 'Net::Int::Stats');

# check method interface
my @methods = qw(value);
can_ok($obj, @methods);

