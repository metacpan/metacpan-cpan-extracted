#!/bin/bash

if [ -d "lib/PhysicsPerl/Astro" ]; then
    cd lib/PhysicsPerl/Astro
elif [ -d "PhysicsPerl/Astro" ]; then
    cd PhysicsPerl/Astro
else
    echo "Can't find lib/PhysicsPerl/Astro or PhysicsPerl/Astro directories, dying"
    exit
fi

rm Body.h 2> /dev/null
rm Body.cpp 2> /dev/null
rm Body.pmc 2> /dev/null

rm System.h 2> /dev/null
rm System.cpp 2> /dev/null
rm System.pmc 2> /dev/null

rm System.pm 2> /dev/null

ln -s System.pm.PERLOPS_PERLTYPES_SSE System.pm
