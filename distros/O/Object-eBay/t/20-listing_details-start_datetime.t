use strict;
use warnings;

use Test::More;
use Object::eBay::ListingDetails;

eval "use DateTime";
plan skip_all => "DateTime required for testing ListingDetails->start_datetime"
  if $@;

plan tests => 4;

# fake the selling_status method
my $iso;
{
    no strict 'refs';
    no warnings 'redefine';
    *Object::eBay::ListingDetails::start_time = sub { $iso };
}

my $details = 'Object::eBay::ListingDetails';
eval { $details->start_datetime };
like $@, qr/StartTime was unavailable/, 'no EndTime';

$iso = '2008-06-07T12:34:56.000Z';
my $dt = $details->start_datetime;
isa_ok $dt, 'DateTime', 'start_datetime';
is $dt->strftime('%F %T'), '2008-06-07 12:34:56', 'correct datetime';
ok $dt->time_zone->is_utc, 'in the correct time zone';
