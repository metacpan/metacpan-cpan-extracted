use inc::Module::Install;

name "Plack-App-Prack";
all_from "lib/Plack/App/Prack.pm";
readme_from "lib/Plack/App/Prack.pm";
build_requires "Test::More";
requires "Plack";
requires "JSON";
requires "parent";
requires_external_bin "rackup";
auto_set_repository;
WriteAll;
