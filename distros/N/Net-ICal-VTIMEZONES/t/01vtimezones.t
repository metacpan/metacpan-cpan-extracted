# $Header: /cvsroot/reefknot/Net-ICal-VTIMEZONES/t/01vtimezones.t,v 1.2 2001/11/25 03:26:40 srl Exp $

use Test::More qw(no_plan);

BEGIN{ 
    use lib "lib";
    use_ok( 'Net::ICal::VTIMEZONES' ); 
}

my $timezones = Net::ICal::VTIMEZONES::timezones;

ok(defined $timezones, "timezones() returns a defined value");

is(ref($timezones), 'HASH', 'timezones() returns a hashref');

ok(keys(%{$timezones}), 
    "timezones() comes up with a listing of timezones; it has " .
    scalar(keys %{$timezones}) . " elements");

my $works = 0;
foreach (keys %{$timezones} ) {
    my $file = $timezones->{$_}->{'file'};
    if ( (-e $file) && ($file =~ /\.ics$/) ) {
        $works = 1;
    } else {
        $works = 0;
        fail("File $file isn't a real, readable VTIMEZONE file ending in .ics");
        last;
    }
}
ok($works, "All items in timezones() are real, readable files ending in .ics");

