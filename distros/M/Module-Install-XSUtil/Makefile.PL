#!perl
use strict;
use inc::Module::Install;

all_from 'lib/Module/Install/XSUtil.pm';

requires 'Module::Install' => 0.91;

test_requires 'Test::More' => 0.88;

# these modules are required for t/01_example.t
test_requires 'Devel::PPPort'     => 3.19;
test_requires 'ExtUtils::ParseXS' => 2.21;
test_requires 'XSLoader'          => 0.10;
test_requires 'B::Hooks::OP::Annotation'
                                  => 0.43;

tests 't/*.t';
author_tests 'xt';

auto_set_repository;

clean_files qw(
		Module-Install-XSUtil-* *.stackdump
		cover_db
		nytprof
		*.out
);

WriteAll check_nmake => 0;
