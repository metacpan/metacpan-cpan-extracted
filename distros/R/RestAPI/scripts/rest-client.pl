#!perl 
#===============================================================================
#
#         FILE: rest-client.pl
#
#        USAGE: ./rest-client.pl  -config <JSON-encoded config string>
#
#  DESCRIPTION: 
#   performs request and display (eventually decoded) response...
#
#       AUTHOR: Marco Masetti (), marco.masetti@sky.uk
# ORGANIZATION: SKY uk
#      VERSION: 1.0
#      CREATED: 02/06/2018 16:35:33
#===============================================================================
use strict;
use warnings;
use Getopt::Long    qw( GetOptions );
use JSON            qw( from_json to_json decode_json );
use Data::Dumper    qw( Dumper );
use LWP::ConsoleLogger::Everywhere ();
use RestAPI ();

$Data::Dumper::Indent = 1;

my $config_as_json;
my $config_file;

sub usage {
    return <<EOT
Usage: $0   
    -config         # a JSON-encoded configuration snippet, or
    -config_file    # a JSON-encoded file
EOT
}

GetOptions( 
    "config=s"      => \$config_as_json,
    "config_file=s" => \$config_file,
) or die usage();
die usage() unless ( $config_as_json || $config_file );

my $config;
if ( $config_as_json ) {
    $config = decode_json( $config_as_json )
        or die ( "Error decoding config params: $!\n");
}

if ( $config_file ) {
    local $/;

    die ("Error, config file not readable") unless ( -f $config_file );
    open my $fh, "<:encoding(UTF-8)", $config_file;
    my $json_txt = <$fh>;
    close( $fh );

    $config = decode_json( $json_txt )
        or die ( "Error decoding config params: $!\n");
}

print "Configuration parameters:\n";
print Dumper ( $config )."\n";

my $r = RestAPI->new( %$config )
    or die "Error getting a RestAPI object: $!\n";
my ($resp, $headers) = $r->do();
