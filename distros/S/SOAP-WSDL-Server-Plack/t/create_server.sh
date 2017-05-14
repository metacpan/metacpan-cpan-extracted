#!/bin/sh

# create client code
wsdl2perl.pl \
    --prefix 'Example::' \
    --base_path 't/lib/' \
    "file://$PWD/t/wsdl/helloworld.wsdl"

# create server
wsdl2perl.pl \
    --prefix 'Example::' \
    --base_path 't/lib/' \
    --server \
    "file://$PWD/t/wsdl/helloworld.wsdl"

