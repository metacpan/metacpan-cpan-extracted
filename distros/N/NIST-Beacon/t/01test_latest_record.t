use Test::More;
use Test::RequiresInternet;
BEGIN { plan tests => 8 }

use NIST::Beacon;

my $beacon = NIST::Beacon->new;
my $record = $beacon->latest_record;

ok($record->version eq "Version 1.0");
ok($record->frequency == 60);
ok($record->timestamp =~ /[0-9]+/);
ok($record->seed =~ /[0-9A-F]+/);
ok($record->previous =~ /[0-9A-F]+/);
ok($record->signature =~ /[0-9A-F]+/);
ok($record->current =~ /[0-9A-F]+/);
ok($record->status == 0);
