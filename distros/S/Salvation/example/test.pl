#!/usr/bin/perl

use strict;

package test;

use URMS ();

print URMS
       -> new(
               args => {
                       request_id => 42
               }
       )
       -> start()
, "\n";

exit 0;

