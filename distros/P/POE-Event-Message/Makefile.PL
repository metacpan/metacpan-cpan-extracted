# -*- Perl -*-
#
# File:  Makefile.PL
# Desc:  Make the makefile for POE::Event::Message and friends
# Date:  Mon Feb 22 14:29:31 2010
#
use inc::Module::Install;

name		'POE-Event-Message';
author		'Chris Cobb [no dot spam at ccobb dot net]';
license 	'perl';
all_from	'lib/POE/Event/Message.pm';
tests		't/*/*/*.t t/*/*/*/*.t';

# When building this distribution
## no_index	directory 	=> 'eg';   #  no eg's just yet...
build_requires	Test::More	=> 0;

# Standard modules needed
requires	POSIX		=> 0;
requires	strict		=> 0;
requires	warnings	=> 0;

# Additional modules needed
# Note that POE.pm is not required by this class and
# Time::HiRes is optional, but *highly* recommended!
## requires 	POE			=> n/a;

requires	POE::Driver::SysRW	=> 0;
requires	POE::Filter::Reference	=> 0;
requires 	Time::HiRes		=> 0;

WriteAll();
