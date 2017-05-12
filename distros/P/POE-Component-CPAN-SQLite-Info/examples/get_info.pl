#!/usr/bin/perl -w

use strict;
use warnings;

use lib qw(../lib  lib);
use POE qw(Component::CPAN::SQLite::Info);

die "Usage: $0 MODULE_TO_LOOKUP\n"
    unless @ARGV;

my $Module_Name = shift;

my $poco = POE::Component::CPAN::SQLite::Info->spawn;

POE::Session->create(
    options => { debug => 1, },
    package_states => [
        main => [
            qw(
                _start
                fetched
                info
            ),
        ],
    ],
);

$poe_kernel->run;

sub _start {
    $poco->freshen( {
            event  => 'fetched',
        }
    );
}

sub fetched {
    my ( $kernel, $input ) = @_[ KERNEL, ARG0 ];

    if ( $input->{freshen_error} ) {
        
        # if {freshen_error} says 'fetch' we got an error
        # on the network side.
        # otherwise, it's something with creating dirs for our files.
        if ( $input->{freshen_error} eq 'fetch' ) {
            # since we are fetching 3 files, we gonna have 1-3 errors here.
            print "Could not fetch file(s)\n";
            foreach my $file ( keys %{ $input->{freshen_errors} } ) {
                print "\t$file  => $input->{freshen_errors}{ $file }\n";
            }
        }
        else {
            print "Failed to create storage dir: $input->{freshen_error}\n";
        }
        $poco->shutdown;
    }
    else {
        # we got our files, let's parse them now.
        $poco->fetch_info( {
                event => 'info'
            }
        );
    }
}

sub info {
    my ( $kernel, $results ) = @_[ KERNEL, ARG0 ];

    use Data::Dumper;
    print Dumper ( $results->{mods}{$Module_Name} );
    
    # shut the PoCo down
    $poco->shutdown;
}



