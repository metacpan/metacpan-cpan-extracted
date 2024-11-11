use strict;
use warnings;


#############################################
# use Log::ger;                             #
# use Log::ger::Output "Screen";            #
#                                           #
 use Log::OK {sys=>"Log::ger"};             #
# use Log::ger::Util;                       #
# Log::ger::Util::set_level Log::OK::LEVEL; #
#############################################
use Test::More tests=>1;

use Template::Plex;
my %vars;
my $template=Template::Plex->load("child.plex", \%vars, root=>"t", use_comments=>0);
#$template->setup;
my $result=$template->render;
print $result. "\n";
my $expected='###START OF GRANDPARENT
###START OF PARENT
===HEADER===
###START OF CHILD 
###END OF CHILD
===FOOTER===
Sub template 1
use this in stead
###END OF PARENT
###END OF GRANDPARENT'
;
ok $result eq $expected, "Inheritance ok";
