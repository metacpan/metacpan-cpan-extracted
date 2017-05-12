#!/usr/bin/perl -w
#
# portugueses.pl - example showing access to a translation dictionary
#
# DICT can also be used to provide translation dictionaries.
#
# Here we connect to a server which has an English->Portuguese
# dictionary: natura.di.uminho.pt
#
# We select the specific dictionary, and then prompt the user
# for words, displaying the translation back.
#
# This is based on an example from Jose Joao Dias de Almeida <jj@di.uminho.pt>
#
# $Id: portuguese.pl,v 1.1.1.1 2003/04/26 22:59:11 neilb Exp $
#

use Net::Dict;
use utf8;

my $dict;
my $host     = 'natura.di.uminho.pt';
my $prompt   = "english> ";
my $database = 'eng-por';
my $entry;
my $db;
my $translation;

#-----------------------------------------------------------------------
# Turn off buffering on STDOUT
#-----------------------------------------------------------------------
$| = 1;

#-----------------------------------------------------------------------
# Create instance of Net::Dict, connecting to the server
#-----------------------------------------------------------------------
print "Connecting to $host ...";
$dict = Net::Dict->new($host);   
$dict->setDicts($database);

#-----------------------------------------------------------------------
# Let the user repeatedly enter words, which we then look up.
#-----------------------------------------------------------------------
print $prompt;
while(<>)
{
    chomp;
    next unless $_;

    $eref = $dict->define($_);

    if (@$eref == 0)
    {
	print "  no translation for \"$_\"\n";
    }
    else
    {
	foreach $entry (@$eref)
	{
	    ($db, $translation) = @$entry;
	    $translation =~ y/[\200-\377]/[\200-\377]/UC;

	    print "$db--------\n",$translation;
	}
    }

    print $prompt;
}

