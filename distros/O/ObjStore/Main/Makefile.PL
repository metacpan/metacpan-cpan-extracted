#!./perl -w
# This is the generic part.

use strict;
use ExtUtils::MakeMaker;
# $Verbose = 1;

use lib '../lib';
use ObjStore::MakeMaker qw(add_os_args);

WriteMakefile(add_os_args(NAME => "ObjStore",
			  OBJECT => "ObjStore.o"));
