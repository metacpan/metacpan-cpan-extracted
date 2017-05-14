#!/usr/bin/perl -wT

$ENV{PATH} = '/bin:/usr/bin:/usr/local/bin';
delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};

use strict;

# NOTE: Don't use this next line in your apps, just hard code your library
# paths in a use lib "" statement somewhere.  This here is just to try and
# provide code that will work out of the box on everyone's OS, distro, path,
# etc.  It's slower than you want.

$SoulFoodCafe::Path = get_app_path();
push @INC, $SoulFoodCafe::Path . "/lib";            # Don't use this, it's slow
# use lib "/var/www/OpenThought/SoulFoodCafe/lib";  # use this instead


# If for some reason, it can't find your SoulFoodCafe templates, try setting
# this.  Generally, this isn't necessary.
#$SoulFoodCafe::Path = "/var/www/OpenThought/SoulFoodCafe/templates";

require SoulFoodCafe;
my $demo = SoulFoodCafe->new();
$demo->run();





#############################################################################
# Repeating the warning at the top of this file, I really recommend against
# using this function in your production code.  I certainly don't :-)  It's
# slow, and only here so it works on *everyone's* system (and it probably
# doesn't even do that well).  A simple use lib "" line will work fine for you.
use File::Basename;
{
    $^W = 0;
    sub get_app_path {

        my $app_path = $ENV{SCRIPT_FILENAME};
        $app_path = File::Basename::dirname( $app_path );
        ( $app_path ) = $app_path =~ m/^(.*)$/ if -d $app_path;

        return "$app_path";
    }
    $^W = 1;
}
