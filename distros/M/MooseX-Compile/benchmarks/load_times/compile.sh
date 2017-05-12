#!/bin/sh

mkdir -p compiled_lib
mxcompile clean -vf compiled_lib
mxcompile compile -vC compiled_lib -I ../../t/lib Moose::Object Point Point3D
