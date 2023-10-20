#!/bin/bash
rm -r ./build/modules;
rm -r ./build/t;
perl ./build/fields2api_def.pl && ./build/build_modules.pl && ( for f in t/{006..025}_*.t; do [ -f $f ] && rm $f; done ) && cp -a -v ./build/modules/. ./lib/Net/API/CPAN/ && cp -a -v ./build/t/0*.t ./t/;
echo "modules and unit tests built and copied";
