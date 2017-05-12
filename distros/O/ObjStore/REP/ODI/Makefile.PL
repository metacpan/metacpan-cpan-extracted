#!./perl -w
use strict;
use ExtUtils::MakeMaker;
use lib '../../lib';
use ObjStore::MakeMaker qw(add_os_args);

my $v = '01';
sub MY::postamble { os_schema_rule("REP-ODI-$v.sch") }

WriteMakefile(add_os_args(['-loscol'],
			  NAME => 'ObjStore::REP::ODI',
			  OBJECT => "ODI.o osp_hkey.o REP-ODI-$v.o"));
