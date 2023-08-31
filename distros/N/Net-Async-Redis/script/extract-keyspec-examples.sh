#!/bin/bash

# git clone git@github.com:redis/redis-doc
perl -lne'if(my ($section) = /^\@(\w+)/) { $current_section = $section } next unless $current_section eq "examples"; print if /```cli/.../```/ and /^[A-Z]/i'
