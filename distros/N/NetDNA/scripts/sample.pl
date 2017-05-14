#!/usr/bin/perl -w

#NetDNA API Sample Code - Perl
#Version 1.1a

use NetDNA;

$api = new NetDNA( 'jdorfman', 'fbe242bcaf4c95ed39a', 'e1429ab0873d0f');

$api->get("/account.json");

$api->get("/account.json", 1);

# Get first name which is set using constructor.
#$alias = $api->getAlias();

#print "Before Setting Alias is : $alias\n";

# Now Set alias using function.
#$api->setAlias( "bastosventures" );

# Now get alias set by function.
#$alias = $api->getAlias();
#print "After Setting Alias is : $alias\n";


