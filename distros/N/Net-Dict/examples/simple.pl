#!/usr/bin/perl -w
#
# simple.pl - a simple example illustrating use of Net::Dict
#
# This is a simple Net::Dict which illustrates basic use
# to get word definitions. Usage:
#
#       simple.pl myhost.org
#       simple.pl
#
# if no hostname is given, then default to dict.org
#
# The user is then prompted for words. We look up definitions
# and display all that we get back.
#
# This is based on an example from Jose Joao Dias de Almeida <jj@di.uminho.pt>
#
# $Id: simple.pl,v 1.1.1.1 2003/04/26 22:59:11 neilb Exp $
#

use strict;
use Net::Dict;

my $dict;
my $host;
my $prompt = "define> ";
my $eref;
my $entry;
my $db;
my $definition;

#-----------------------------------------------------------------------
# Turn off buffering on STDOUT
#-----------------------------------------------------------------------
$| = 1;

#-----------------------------------------------------------------------
# Create instance of Net::Dict, connecting either to a user-specified
# dict server, or defaulting to dict.org
#-----------------------------------------------------------------------
$host = @ARGV > 0 ? shift @ARGV : 'dict.org';
print "Connecting to $host ...";
$dict = Net::Dict->new($host);
print "\n";

#-----------------------------------------------------------------------
# Let the user repeatedly enter words, which we then look up.
#-----------------------------------------------------------------------
print $prompt;
while (<>)
{
    chomp;
    next unless $_;

    #-------------------------------------------------------------------
    # The define() method returns an array reference.
    # The array has one entry for each definition found.
    # If the referenced array has no entries, then there were no
    # definitions in any of the dictionaries on the server.
    #-------------------------------------------------------------------
    $eref = $dict->define($_);

    if (@$eref == 0)
    {
        print "  no definition for \"$_\"\n";
    }
    else
    {
        #---------------------------------------------------------------
        # Each entry is another array reference. The referenced array
        # for each entry has two elements:
        #     $db         - the name of the database (ie dictionary)
        #     $definition - the text of the definition
        #---------------------------------------------------------------
        foreach $entry (@$eref)
        {
            ($db, $definition) = @$entry;
            print  "\n-----(from: $db)---------------------------\n",
                $definition;
        }
    }
    print $prompt;
}
