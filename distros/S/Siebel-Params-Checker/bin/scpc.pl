#!/usr/bin/env perl
use warnings;
use strict;
use Getopt::Std;
use Siebel::Params::Checker qw(recover_info);
use File::HomeDir 1.00;
use File::Spec;
use Siebel::Params::Checker::Data qw(has_more_servers by_param by_server);
use Siebel::Params::Checker::Template qw(gen_report);
our $VERSION = '0.002'; # VERSION

$Getopt::Std::STANDARD_HELP_VERSION = 2;

sub HELP_MESSAGE {

    my $option = shift;

    if ( ( defined($option) ) and ( ref($option) eq '' ) ) {

        print "'-$option' parameter cannot be null\n";

    }

    print <<BLOCK;

scpc - version $main::VERSION

This program will connect to a Siebel server, check desired components parameters and print all information to STDOUT as a table for comparison.

The parameters available are:

    -n: required parameter of the component alias to export as parameter (case sensitive). The component alias must be unique.
    -o: required parameter with the complete pathname to the HTML file to be generated as result
    -c: optional parameter to the complete path to the configuration file (defaults to .scpc.cfg in the user home directory).
        See the Pod of Siebel::Params::Checker for details on the configuration file.

The parameters below are optional:

    -h: prints this help message and exits

Beware that environment variables required to connect to a Siebel Enterprise are expected to be already in place.

BLOCK

    exit(0);

}

our %opts;

getopts( 'n:c:o:h', \%opts );

HELP_MESSAGE() if ( exists( $opts{h} ) );

foreach my $option (qw(n o)) {

    HELP_MESSAGE($option) unless ( defined( $opts{$option} ) );

}

my $cfg_file;
my $default = File::Spec->catfile( File::HomeDir->my_home(), '.scpc.cfg' );

if ( exists( $opts{c} ) ) {

    if ( -r $opts{c} ) {
        $cfg_file = $opts{c};
    }
    else {
        die "file $opts{c} does not exist or is not readable";
    }

}
elsif ( -e $default ) {
    $cfg_file = $default;
}
else {
    die
"No default configuration file available, create it or specify one with -c option";
}

my $data_ref = recover_info( $cfg_file, $opts{n} );

my ( $header, $rows );

if ( has_more_servers($data_ref) ) {
    ( $header, $rows ) = by_server($data_ref);
}
else {
    ( $header, $rows ) = by_param($data_ref);
}

gen_report($opts{n}, $header, $rows, $opts{o});

