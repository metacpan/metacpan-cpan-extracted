#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  through.pl
#
#        USAGE:  ./through.pl 
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:   (), <>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  13/04/08 19:11:15 IST
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use SVN::Dumpfile;

my $in  = new SVN::Dumpfile();
$in->open;
my $out = $in->copy->create();

while (my $node = $in->read_node) {
    $out->write_node($node);
}

$in->close;
$out->close;

