#!./perl -w

use strict;
use lib './lib';
use ExtUtils::MakeMaker;
use ObjStore::MakeMaker ':ALL';

print "
*** Be sure to read the ./INSTALL file first!  The usual make, ***
*** test, and install steps are not sufficient!                ***

Edit ./lib/ObjStore/Config.pm to change the following:
  SCHEMA_DBDIR = ".$ObjStore::Config::SCHEMA_DBDIR."
  TMP_DBDIR    = ".$ObjStore::Config::TMP_DBDIR."

";

my @PREFIX = (PREFIX => $ENV{PERL5PREFIX})
    if exists $ENV{PERL5PREFIX};

#$Verbose = 1;
WriteMakefile
    (
     @PREFIX,
     NAME         => 'ObjStore',
     PREREQ_PM	  => { Test => '1.03' },
#     OPTIMIZE => '-g',
     LINKTYPE => 'dynamic',  # static not supported!!!
     VERSION_FROM => './lib/ObjStore.pm',
     EXE_FILES  => [qw/posh osperlserver qtposh/],
    );

sub MY::linkext { 
    'linkext::
	@$(NOOP)

'
}
