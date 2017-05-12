#!/bin/bash

cd lib/PhysicsPerl/Astro

rm Body.h 2> /dev/null
rm Body.cpp 2> /dev/null
rm Body.pmc 2> /dev/null

rm System.h 2> /dev/null
rm System.cpp 2> /dev/null
rm System.pmc 2> /dev/null

ln -s Body.h.CPPOPS_CPPTYPES Body.h
ln -s Body.cpp.CPPOPS_CPPTYPES Body.cpp
ln -s Body.pmc.CPPOPS_DUALTYPES Body.pmc

ln -s System.h.CPPOPS_CPPTYPES System.h
ln -s System.cpp.CPPOPS_CPPTYPES_SSE System.cpp
ln -s System.pmc.CPPOPS_DUALTYPES System.pmc
