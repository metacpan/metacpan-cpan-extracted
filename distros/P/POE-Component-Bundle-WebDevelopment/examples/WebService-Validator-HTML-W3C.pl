#!/usr/bin/perl -w

use strict;
use warnings;

# VERSION

# PLEASE: install local validator and change the line below
my $Validator = 'http://validator.w3.org/check';
use lib qw(../lib lib);
# use the PoCo along with POE goodies
use POE (qw(Component::WebService::Validator::HTML::W3C));

# for the sake of simplicity we will validate all the files from command line
unless ( @ARGV ) {
    die "You must specify the files to validate as arguments!\n";
}

my @Files           = @ARGV;
my $Total_Files     = @Files; # note the total number so we will know
my $Validated_Files = 0; # .. when to kill our PoCo

# create the validator component
POE::Component::WebService::Validator::HTML::W3C->spawn( alias => 'val' );

# create parent session which will accept events
POE::Session->create(
    package_states => [
        main => [ qw( _start got_val ) ],
    ],
);

$poe_kernel->run; # fire up the POE event loop \o/

sub _start {
    foreach my $file ( @Files ) {
        $poe_kernel->post( val => validate => {
                in   => $file,
                type => 'file',
                event => 'got_val',
                options => {
                    validator_uri => $Validator,
                }
            }
        );
    }
}

sub got_val {
    my ( $kernel, $results ) = @_[ KERNEL, ARG0 ];

    print "\n\n\n\t*** Results for file `$results->{in}` ***\n";
    if ( $results->{validator_error} ) {
        print "Could not validate: $results->{validator_error}\n";
    }
    else {
        if ( $results->{is_valid} ) {
            print "Perfectly valid!\n";
        }
        else {
            print "Contains $results->{num_errors} errors:\n";
            foreach my $error ( @{ $results->{errors} } ) {
                printf "\n--\nLine: %s Column: %s\n%s\n\n",
                        @$error{ qw( line col msg ) };
            }
        }
    }

    if ( ++$Validated_Files >= $Total_Files ) {
        print "\n\n---END---\n";
        $kernel->post( val => 'shutdown' );
    }
}


