#test that the module is loaded properly
use strict;
use warnings;
use Test::More 0.88;
plan tests => 1;
my $package = 'TBX::Checker';

# require $package;
# new_ok($package);
use_ok($package);

__END__