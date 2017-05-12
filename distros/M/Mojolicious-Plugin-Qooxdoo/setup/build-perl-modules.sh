#!/bin/bash

. `dirname $0`/sdbs.inc

for module in \
    Mojolicious@5.0 \
; do
    perlmodule $module
done

#    Devel::NYTProf 
        
