#!/usr/bin/perl -wT

$ENV\{PATH\} = '/bin:/usr/bin:/usr/local/bin';
delete @ENV\{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'\};

use strict;
use lib "{$OpenThoughtApps}/lib";
$Demo::OpenThoughtAppsPath = "{$OpenThoughtApps}";
require Demo;


######################################
# CGI INSTALL
#
# Uncomment the following lines for a CGI installation

#my $demo = Demo->new( PARAMS => \{
#    config  => \{ src => "{$OpenThoughtPrefix}/etc/OpenThought.conf" \},  \});
#$demo->run();

######################################
# MOD_PERL 1.x INSTALL
#
# Uncomment the following lines for a mod_perl 1.x installation

my $r = shift;
my $demo = Demo->new( PARAMS => \{ request => \{ apache => $r \}\});
$demo->run();

######################################
# MOD_PERL 2.x INSTALL
#
# Uncomment the following lines for a mod_perl 2.x installation
#

#my $r = shift;
#my $demo = Demo->new( PARAMS => \{ request => \{ apache2 => $r \}\});
#$demo->run();

