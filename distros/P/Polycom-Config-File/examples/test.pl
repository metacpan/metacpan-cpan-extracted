#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use lib '../lib';
use Polycom::Config::File; 

binmode STDOUT, ':utf8';

# Load an existing config file
my $cfg = Polycom::Config::File->new('0004f21ac123-regLine.cfg');

# Read some parameters
my $dialmap = $cfg->params->{'dialplan.digitmap'};
print "The 'dialplan.digitmap' parameter is:\n";
print "\t$dialmap\n";

# Modify some parameters
$cfg->params->{'voIpProt.server.1.address'} = 'polycom.com';

# Read a parameter that contains UTF8
my $secondLabel = $cfg->params->{'reg.2.label'};
print "The 'reg.2.label' parameter is:\n";
print "\t$secondLabel\n";

# Add a parameter that contains UTF8
$cfg->params->{'reg.1.label'} = 'マージャン';

# Save the file
$cfg->save('new-0004f21ac123-regLine.cfg');

