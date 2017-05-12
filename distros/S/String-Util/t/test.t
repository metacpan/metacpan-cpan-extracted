#!/usr/bin/perl -w
use strict;
BEGIN { if($ENV{'IDOCSDEV'}){system '/usr/bin/clear'} }
use String::Util ':all';
use Test::Toolbox;

# debug tools
# use Debug::ShowStuff ':all';
# use Debug::ShowStuff::ShowVar;
# use Test::Toolbox::Idocs;

# plan tests
rtplan 37, autodie=>$ENV{'IDOCSDEV'}, xverbose=>$ENV{'IDOCSDEV'};
my $n0 = 'String::Util';


#------------------------------------------------------------------------------
##= hascontent
#
if (1) { ##i
	my ($n1, $val);
	$n1 = "$n0 - hascontent";
	
	# undef is false
	rtbool "$n1 - undef is false", hascontent(undef), 0;
	
	# empty string is false
	rtbool "$n1 - empty string is false", hascontent(''), 0;
	
	# space only is false
	$val = "   \t   \n\n  \r   \n\n\r     ";
	rtbool "$n1 - space only is false", hascontent($val), 0;
	
	# 0 string is true
	$val = '0';
	rtbool "$n1 - 0 string is true", hascontent($val), 1;
	
	# non-space is true
	$val = ' x ';
	rtbool "$n1 - non-space is true", hascontent($val), 1;
}
#
# hascontent
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##= collapse
#
if (1) { ##i
	my ($n1, $val);
	$n1 = "$n0 - collapse";
	
	# basic
	$val = "  Starflower \n\n\t  Miko     ";
	$val = collapse($val);
	rtcomp "$n1 - basic", $val, 'Starflower Miko';
	
	# undef returns undef
	rtcomp "$n1 - undef returns undef", collapse(undef), undef;
}
#
# collapse
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
##= trim
#
if (1) { ##i
	my ($n1, $val);
	$n1 = "$n0 - trim";
	
	# basic
	$val = '  steve   fred     ';
	$val = trim($val);
	rtcomp "$n1 - basic", $val, 'steve   fred';
	
	# undef returns undef
	rtcomp "$n1 - undef returns undef", trim(undef), undef;
}
#
# trim
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##= no_space
#
if (1) { ##i
	my ($n1, $val);
	$n1 = "$n0 - nospace";
	
	# basic
	$val = '  steve   fred     ';
	$val = nospace($val);
	rtcomp "$n1 - basic", $val, 'stevefred';
	
	# undef returns undef
	rtcomp "$n1 - undef returns undef", nospace(undef), undef;
}
#
# no_space
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##= htmlesc
#
if (1) {
	my ($n1, $val);
	$n1 = "$n0 - htmlesc";
	
	# basic
	$val = '<>"&';
	$val = htmlesc($val);
	rtcomp "$n1 - basic", $val, '&lt;&gt;&quot;&amp;';
	
	# undef returns empty string
	rtcomp "$n1 - undef returns empty string", htmlesc(undef), '';
}
#
# htmlesc
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
##= cellfill
#
if (1) {
	my ($n1, $val);
	$n1 = "$n0 - cellfill";
	
	# space-only string
	$val = '  ';
	$val = cellfill($val);
	rtcomp "$n1 space-only string", $val, '&nbsp;';
	
	# undef
	$val = undef;
	$val = cellfill($val);
	rtcomp "$n1 space-only string", $val, '&nbsp;';
	
	# string with content
	$val = 'x';
	$val = cellfill($val);
	rtcomp "$n1 space-only string", $val, 'x';
}
#
# cellfill
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##= eqq
#
if (1) {
	my $n1 = "$n0- eqq";
	
	# defined, same
	rtbool "$n1 defined, same", eqq('a', 'a'), 1;
	
	# undef, same
	rtbool "$n1 undef, same", eqq(undef, undef), 1;
	
	# defined, different
	rtbool "$n1 defined, different", eqq('a', 'b'), 0;
	
	# one defined, other undef
	rtbool "$n1 one defined, other undef", eqq('a', undef), 0;
}
#
# eqq
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##= neqq
#
if (1) {
	my $n1 = "$n0- neqq";
	
	# defined, same
	rtbool "$n1 defined, same", neqq('a', 'a'), 0;
	
	# undef, same
	rtbool "$n1 undef, same", neqq(undef, undef), 0;
	
	# defined, different
	rtbool "$n1 defined, different", neqq('a', 'b'), 1;
	
	# one defined, other undef
	rtbool "$n1 one defined, other undef", neqq('a', undef), 1;
}
#
# eqq
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
##= define
#
if (1) {
	my $n1 = "$n0 - define";
	
	# undef
	rtcomp "$n1 - undef", define(undef), '';
	
	# defined value
	rtcomp "$n1 - defined value", define('whatever'), 'whatever';
}
#
# define
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##= unquote
#
if (1) {
	my $n1 = "$n0 - unquote";
	
	# single quotes
	rtcomp "$n1 - single quotes", unquote("'fred'"), 'fred';
	
	# double quotes
	rtcomp "$n1 - double quotes", unquote('"fred"'), 'fred';
	
	# no quotes
	rtcomp "$n1 - no quotes", unquote('fred'), 'fred';
	
	# mixed quotes
	rtcomp "$n1 - mixed quotes", unquote(q|"fred'|), q|"fred'|;
	
	# undef
	rtcomp "$n1 - undef", unquote(undef), undef;
}
#
# unquote
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##= jsquote
#
if (1) {
	my ($n1, $val, $got, $should);
	$n1 = "$n0 - jsquote";
	
	# basic
	$val = qq|'yeah\n</script>'|;
	$got = jsquote($val);
	$should = q|'\'yeah\n<' + '/script>\''|;
	rtcomp "$n1 - basic", $got, $should;
}
#
# jsquote
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##= fullchomp
#
if (1) {
	my ($n1, $val, $got, $should);
	$n1 = 'fullchomp';
	
	# void context
	$val = qq|Starflower\n\r\r\r\n|;
	fullchomp($val);
	$should = 'Starflower';
	rtcomp "$n1 - void context", $val, $should;
	
	# scalar context
	$val = qq|Starflower\n\r\r\r\n|;
	$got = fullchomp($val);
	$should = 'Starflower';
	rtcomp "$n1 - scalar context", $got, $should;
	
	# undef
	$val = undef;
	$got = fullchomp($val);
	$should = undef;
	rtcomp "$n1 - undef", $got, $should;
}
#
# fullchomp
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##= randword
#
if (1) {
	my ($n1, $val);
	$n1 = "$n0 - randword";
	
	# get random word
	$val = randword(20);
	
	# check word
	rtdef "$n1 - defined", $val, 1;
	rtcomp "$n1 - length", length($val), 20;
}
#
# randword
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# done
# The following code is purely for a home grown testing system. It has no
# purpose outside of my own system. -Miko
#
if ($ENV{'IDOCSDEV'}) {
	require FileHandle;
	FileHandle->new('> /tmp/test-done.txt') or
		die "unable to open check file: $!";
	print "[done]\n";
}
#
# done
#------------------------------------------------------------------------------

