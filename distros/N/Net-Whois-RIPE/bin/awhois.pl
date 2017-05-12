#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Net::Whois::Generic;
use Data::Dumper;

####################################################################################
#
# Global variables

my $DEBUG;
my @EXCLUDES;
my $HELP;
my $KEY;
my $ONLY;
my $QUERY;
my %QUERY_OPTIONS;
my @TYPES;
my $VERSION;

####################################################################################
#
# Processing

# Get options value from command line
GetOptions( 'debug'      => \$DEBUG,
            'excludes=s' => \@EXCLUDES,
            'help'       => \$HELP,
            'key=s'      => \$KEY,
            'only=s'     => \$ONLY,
            'query=s'    => \$QUERY,
            'type=s'     => \@TYPES,
            'version'    => \$VERSION,
) or die usage();

if ($HELP) {
    print usage();
    exit 0;
}

if ($VERSION) {
    print "$0  -  using Net::Whois::RIPE $Net::Whois::RIPE::VERSION\n";
    exit 0;
}

# Query can be implicit or explicit
$QUERY = $ARGV[0] unless $QUERY;

# You can now do
if (@TYPES) {
    my $query_types = lc join '|', @TYPES;
    $query_types =~ s/-//g;
    $QUERY_OPTIONS{type} = $query_types;
}

if ($KEY) {
    $QUERY = "-i $KEY " . $ARGV[0] unless $QUERY =~ /-i/;
}

if ($DEBUG) {
    print "QUERY=($QUERY)\n";
    print "OPTIONS=", Dumper \%QUERY_OPTIONS;
}

my @objects = Net::Whois::Generic->query( $QUERY, \%QUERY_OPTIONS );

# And manipulate the object the OO ways
for my $object (@objects) {
    print $object->dump;
    print $/;
}

exit 0;

sub excluded {
    my $tested = shift;

    return 0 unless @EXCLUDES;

    if ($ONLY) {
        return 1 unless $tested =~ /$ONLY/msi;
    }

    for my $ex_pattern (@EXCLUDES) {
        return 1 if $tested =~ /$ex_pattern/msi;
    }

    return 0;
}

sub usage {

    return <<EOT;

NAME

    $0 - WHOIS client for RIPE database

SYNOPSIS

    $0 [options] [query ...]

    # Get objects whose maintener is JAGUAR-MNT
    $0 --key mnt-by JAGUAR-MNT

    # Get objects about ASN 30781
    $0 AS30781


OPTIONS


--help

    Print a brief help message and exits.

--debug

    Display debugging information

--exclude

    Not yet implemented

--key

    The attribute to be used as the key for the search

--only

    Not yet implemented

--type

    The type of record to be returned (example: person, role, inetnum, route...)

--version

    Display version information


DESCRIPTION

This program is a WHOIS client requesting the RIPE database

EOT
}

