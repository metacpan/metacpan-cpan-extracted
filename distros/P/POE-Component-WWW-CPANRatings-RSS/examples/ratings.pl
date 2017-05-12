#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(../lib lib); 
use POE qw(Component::WWW::CPANRatings::RSS);

my $poco = POE::Component::WWW::CPANRatings::RSS->spawn;

POE::Session->create(
    package_states => [ main => [qw(_start ratings )] ],
);

my $Count = 0;

$poe_kernel->run;

sub _start {
    $poco->fetch( {
            event   => 'ratings',
            unique  => 1,
            repeat  => 10,
            file    => 'foo.file.store',
        }
    );
}

sub ratings {
    my $in_ref = $_[ARG0];

use Data::Dumper;
print Dumper $in_ref;
    
    if ( $in_ref->{error} ) {
        print "ERROR: $in_ref->{error}\n\n";
    }
    else {
        print "New reviews:\n";
        for ( @{ $in_ref->{ratings} } ) {
            printf "%s - %s stars - by %s\n--- %s ---\nsee %s\n\n\n",
                @$_{ qw/dist rating creator comment link/ };
        }
    }
}

