package POE::Component::IKC::Util;

############################################################
# $Id$
# Copyright 2014 Philip Gwyn.  All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# Contributed portions of IKC may be copyright by their respective
# contributors.  

#
# Utility functions
#



use strict;
use warnings;

use POE;
use Carp;

sub monitor_error
{
    my( $heap, $operation, $errnum, $errstr, $ignore ) = @_;

    if( $heap->{on_error} ) {
        $heap->{on_error}->( $operation, $errnum, $errstr );
    }
    else {
        $poe_kernel->call( IKC => 'channel_error', 
                        [ "[$errnum] $errstr", 
                          $heap->{remote_ID}, 
                          $operation 
                     ] ) and return;
        return if $ignore;
        my( $source ) = caller;
        carp "$$: $source $operation error: $errnum $errstr";
    }
}

1;

