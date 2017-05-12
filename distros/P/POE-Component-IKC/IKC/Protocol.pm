package POE::Component::IKC::Protocol;

############################################################
# $Id$
# Copyright 2011-2014 Philip Gwyn.  All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# Contributed portions of IKC may be copyright by their respective
# contributors.  

use strict;
use Socket;


sub __build_setup
{
    my( $aliases, $freezers ) = @_;
    return 'SETUP '.join ';', 'KERNEL='.join( ',', @$aliases ), 
                              'FREEZER='.join( ',', @$freezers ),
                              "PID=$$";
}        

sub __neg_setup
{
    my( $setup ) = @_;
    my $neg = {
            kernel => [],
            freezer => [],
            bad => 0,
            pid => 0
        };
    foreach my $bit ( split ';', $1 ) {
        if( $bit =~ m/KERNEL=(.+)/ ) {
            push @{ $neg->{kernel} }, split ',', $1;
        }
        elsif( $bit =~ m/FREEZER=(.+)/ ) {
            push @{ $neg->{freezer} }, split ',', $1;
        }
        elsif( $bit =~ m/PID=(\d+)/ ) {
            # warn "pid=$1";
            $neg->{pid} = $1;
        }
        else {
            warn "Server sent unknown setup '$bit' during negociation\n";
            $neg->{bad}++;
        }
    }
    unless( @{ $neg->{kernel} } ) {
        warn "Server didn't send KERNEL in $setup\n";
        $neg->{bad}++;
    }
    return $neg;
}

1;
