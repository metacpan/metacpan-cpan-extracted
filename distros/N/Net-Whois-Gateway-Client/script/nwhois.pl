#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  nwhois.pl
#
#        USAGE:  ./nwhois.pl 
#
#  DESCRIPTION:  Net-Whois-Gateway-Client based whois utility
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (), <davinchi@cpan.org>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  31.07.2009 14:35:45 MSD
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Getopt::Long;
use YAML;

use Data::Dumper;

use Net::Whois::Gateway::Client;

my $host = 'localhost';
my $port = 54321;;
my $config_file = '/etc/nwhois.yaml';
my $verbose = 0;

my %options;

GetOptions (
    'host=s'	=> \$host,
    'port=s'	=> \$port,
    'config=s'	=> \$config_file,
    'port=s'	=> \$port,
    'verbose'	=> \$verbose,
    'options=s' => \%options,
) or die "$!";

my @query = @ARGV;

warn Dumper \%options, \@query	if $verbose;

if ( -f $config_file && -s _ ) {
    Net::Whois::Gateway::Client::configure(
	YAML::LoadFile( $config_file ),
	gateway_port => $port,
	gateway_host => $host,
    );
}

my @response = Net::Whois::Gateway::Client::whois( 
    %options,
    query => \@query,
    gateway_port => $port,
    gateway_host => $host,
);

warn Dumper \@response		if $verbose;

if ( @response != @query ) {
    warn "Incorrect count of responses or queries\n";
}

while( @response && @query ) {
    my $r = shift @response;
    my $q = $r->{query};

    print '-'x40, "\n";
    print "Domain: $q\n";
    print 'v'x40, "\n";

    foreach ( @{ $r->{subqueries} || [ $r ] } ) {
	print "\n", '---------' x 3, "\n";
	print "Server: $_->{server}\n";
	print '---------' x 3, "\n";
	print $_->{whois} || $r->{error}, "\n";
    }

    print '^'x40, "\n";
    print "End of domain: $q\n";
    print '-'x40, "\n";
}

