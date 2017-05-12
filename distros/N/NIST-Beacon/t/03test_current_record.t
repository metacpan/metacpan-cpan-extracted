use Test::More;
use Test::RequiresInternet;
BEGIN { plan tests => 16 }

use NIST::Beacon;

my $beacon = NIST::Beacon->new;
my $record = $beacon->current_record;

ok($record->version eq "Version 1.0");
ok($record->frequency == 60);
ok($record->timestamp =~ /[0-9]+/);
ok($record->seed =~ /[0-9A-F]+/);
ok($record->previous =~ /[0-9A-F]+/);
ok($record->signature =~ /[0-9A-F]+/);
ok($record->current =~ /[0-9A-F]+/);
ok($record->status == 0);

$record = $beacon->current_record(time - 600);

ok($record->version eq "Version 1.0");
ok($record->frequency == 60);
ok($record->timestamp =~ /[0-9]+/);
ok($record->seed =~ /[0-9A-F]+/);
ok($record->previous =~ /[0-9A-F]+/);
ok($record->signature =~ /[0-9A-F]+/);
ok($record->current =~ /[0-9A-F]+/);
ok($record->status == 0);
