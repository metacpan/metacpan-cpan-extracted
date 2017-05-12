#                              -*- Mode: Perl -*- 
# base.t -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Sat Sep 28 13:54:46 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sat Oct  5 16:15:39 1996
# Language        : CPerl
# Update Count    : 25
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1996, Universität Dortmund, all rights reserved.
# 
# $Locker:  $
# $Log: base.t,v $
# Revision 1.1  1997/02/10 19:48:41  pfeifer
# Switched to CVS
#
# 

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use NNML::Server;
use NNML::Config qw($Config);
use NNML::Active qw($ACTIVE);

$loaded = 1;

print "ok 1\n";
my $test = 2;

print ((defined $Config)? "ok $test\n" : "not ok $test\n"); $test++;


#map print (join(' ', @{$_})."\n"), $ACTIVE->list_match('tools*,!*wais.*');
