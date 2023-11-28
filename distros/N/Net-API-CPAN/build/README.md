Most modules are auto-generated based on certain files in this build directory.

First, we generate the `api.json` file based on the `fields.json` file. fields.json file is an aggregation of all the MetaCPAN objects fields with their properties definition.

Some correction and addition has been made to this file to reflect the reality of the data sent and retrieved from the MetaCPAN API.

From this `fields.json` file, we run the script `fields2api_def.pl`, which will apply some corrections and generate the reference `api.json` file.

For a more authoritative document, please check the file `cpan-openapi-spec-3.0.0.pl`, which is compliant with the Open API specifications.

From this `api.json`, we run the script `build_modules.pl`, which will generate all the necessary modules with their methods and POD documentation under this directory `build`.

You can check those modules generated under `./build/modules` and if they are satisfactory, you can simply move them under the distribution directory `./lib/Net/API/CPAN/` with `cp -a -v ./build/modules/. ./lib/Net/API/CPAN/` and copy the unit tests with `cp -a -v ./build/t/0*.t ./t/`

The simplest is probably to run the script `./build/build.sh` which does all the above starting from running `fields2api_def.pl`.

The JSON files here are used for example data only for each generated module, in their `API SAMPLE` POD section.

