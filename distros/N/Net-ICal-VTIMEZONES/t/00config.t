# $Header: /cvsroot/reefknot/Net-ICal-VTIMEZONES/t/00config.t,v 1.2 2001/11/25 16:25:16 srl Exp $

use Test::More qw(no_plan);

# Check to see if the config loads

BEGIN{ 
    use lib "blib/lib";
    use_ok( 'Net::ICal::Config' ); 
}

ok(defined $Net::ICal::Config->{'zoneinfo_location'}, 
    "zoneinfo_location is defined in config file");

my $location = $Net::ICal::Config->{'zoneinfo_location'};
ok(-d $location, 
    "zoneinfo_location is an existing directory, $location");
    
