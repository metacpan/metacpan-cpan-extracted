#!/usr/bin/perl

=head1 NAME

picasru - Get PICA+ records from an SRU server

=cut

use strict;
use utf8;
use PICA::Source;
use PICA::Writer;
use Getopt::Long;
use Pod::Usage;

my $version = "0.6";

my ($user, $password, $help, $man, $output, $limit);
GetOptions(
    'help|?' => \$help,
    'man' => \$man,
    'user=s' => \$user,
    'password=s' => \$password,
    'output=s' => \$output,
    'limit=s' => \$limit,
) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

my $baseurl = shift @ARGV;
my $query = join " ", @ARGV;
pod2usage(1) unless $baseurl and $query ne '';

$limit = 10 unless $limit > 0;

# handle the records with this function
my $record_handler = sub {
    my $record = shift;
    # filter and/or process records as you like
    return $record; # don't drop records, so you can later access them
};

if ($output) {
    print "Write records to $output\n";
    $output = PICA::Writer->new( $output );
}

print "Base URL: $baseurl\n";
print "User:     $user\n" if defined $user;
print "Password: $password\n" if defined $password;
print "Query:    $query\n";

# connect and query via SRU
my $server = PICA::Source->new(
    SRU => $baseurl, password => $password, user => $user 
);
my $parser = $server->cqlQuery( $query, Record => $record_handler, Limit => $limit );

print "Read " . $parser->counter() . " PICA+ records.\n";

=head1 SYNOPSIS

picasru [OPTIONS] host[:port]/databaseName query...

=head1 OPTIONS

 -help|?          this help message
 -man             more documentation with examples
 -user USER       username for authentification (optional)
 -password PWD    password for authentification (optional)
 -output          print records to a file (use '-' for STDOUT)

=head1 DESCRIPTION

This script demonstrates how to query PICA+ records from an SRU server.

=head1 EXAMPLES

Get records from GVK union catalog with 'märchensammlung' in its title:

  picasru http://gso.gbv.de/sru/DB=2.1 pica.tit=märchensammlung

=head1 AUTHOR

Jakob Voss C<< jakob.voss@gbv.de >>
