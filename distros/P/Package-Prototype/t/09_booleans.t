use strict;
use warnings;
use Test::More;
use Package::Prototype;
BEGIN { plan skip_all => 'builtin booleans require Perl 5.36' if $] < 5.036 }

use builtin qw(true false is_bool);
no warnings 'experimental::builtin';
my $obj = Package::Prototype->bless({ yes => true, no => false });
ok is_bool($obj->yes), 'true retains boolean identity';
ok is_bool($obj->no), 'false retains boolean identity';
ok $obj->yes, 'true remains true';
ok !$obj->no, 'false remains false';
$obj->prototype(yes => false);
ok is_bool($obj->yes), 'dynamic getter retains boolean identity';
ok !$obj->yes, 'replacement is false';
my $explicit = Package::Prototype->create(properties => {
    enabled => { value => true, writer => 'set_enabled' },
});
ok is_bool($explicit->enabled), 'property retains boolean identity';
$explicit->set_enabled(false);
ok is_bool($explicit->enabled), 'writer retains boolean identity';
ok !$explicit->enabled, 'writer changes truth value';
done_testing;
