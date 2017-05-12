#!/usr/local/bin/perl -w
#
# A demo of Term::InKey functions
#
# Copyright (c) 2001, 2002, 2003, 2004 RAZ Information Systems Ltd.
# http://www.raz.co.il/

# This program is distributed under the same terms as Perl itself, see the
# Artistic License on Perl's home page.
#
 use strict;
 use lib qw(.);
 use Term::InKey;

 my ($x,$bullet);

 $|=1;

 &Clear;

 print "\nThis is a demo program for Term::InKey Ver $Term::InKey::VERSION\n";
 print "Press any key to clear the screen: ";
 $x = &ReadKey;
 &Clear;

 print "You pressed [$x]\n\n";
 print "Enter bullet for passowrd input [*]:";
 $bullet = &ReadKey;
 $bullet .= &ReadKey if $bullet eq '-';
 $bullet = '*' if $bullet =~/\s/;
 print "\n";
 print "This is a demo of ReadPassword, type few letters then type [enter]: ";
 $x = &ReadPassword($bullet);
 print "\nPassword you typed is [$x]\n";
 print "\nThis ends a demo program for Term::InKey Ver $Term::InKey::VERSION\n";

 1;
