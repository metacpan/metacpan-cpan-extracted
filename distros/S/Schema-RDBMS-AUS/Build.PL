#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use lib 'lib';
use Module::Build;

our %opts = (
    module_name         =>  'Schema::RDBMS::AUS',
    license             =>  'perl',
    requires            =>  {
        'DBIx::Migration::Directories'  =>  '0.07',
        'DBIx::Transaction'             =>  '0.005',
        'CGI::Session'                  =>  '4.07',
        'CGI::Session::Serialize::yaml' =>  '0',
        'JSON::Syck'                    =>  '0.07',
    },
    build_requires      =>  {
        'Module::Build'                         =>  '0.27_03',
        'Test::Exception'                       =>  '0.20',
        'DBIx::Migration::Directories::Build'   =>  '0',
    },
    create_makefile_pl  =>  'passthrough',
);

eval { require DBIx::Migration::Directories::Build; };

my $build;

if($@) {
    $build = Module::Build->new(%opts, installdirs => {});
    print <<"EOT";
*** DBIx::Migration::Directories::Build is required to build this module!

    This is supplied by the DBIx::Migration::Directories package.
    Once you have installed this package, you may have to run "Build.PL"
    again. If you are installing from CPAN, you may need to quit and
    re-enter your CPAN shell.
        
EOT
    $build->prompt("Press enter to continue", ".");
} else {
    $build = DBIx::Migration::Directories::Build->new(%opts);
}

print qq{Example DSN: "DBI:mysql:database=test"\n};
if($build->notes(DBI_DSN => $build->prompt(
    "What DSN should we use for database tests? (Enter '0' to skip DB tests)",
    exists $ENV{DBI_DSN} ? $ENV{DBI_DSN} : 0
))) {
    $build->notes(DBI_USER => $build->prompt(
        "Username for the database connection:", $ENV{DBI_USER}
    ));
    $build->notes(DBI_PASS => $build->prompt(
        "Password for the database connection:", $ENV{DBI_PASS}
    ));
} else {
    $build->notes(DBI_USER => undef);
    $build->notes(DBI_PASS => undef);
}

$build->create_build_script;
