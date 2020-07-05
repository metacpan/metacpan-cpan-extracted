use Net::NTPTime;

my $ntpTimestamp = get_ntp_time;
my $unixTimestamp = get_unix_time;

print "The current NTP timestamp is: $ntpTimestamp\n";
print "The current UNIX timestamp is: $unixTimestamp\n";
print "The current local time is: " . localtime($unixTimestamp) . "\n";
$_ = <STDIN>;
exit;
