#!/usr/bin/perl -w
#
# script to fix issues sometimes found in xml
#
# Example:
#   
#   $ cat sslscan.xml | ./fix_xml.pl > fixed_sslscan.xml 
#
use strict;
while(<STDIN>) {
    s/ critical>/>/g;
    s/&/&amp;/g;
    print;
}
