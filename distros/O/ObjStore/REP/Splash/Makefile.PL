#!./perl -w
use strict;
use ExtUtils::MakeMaker;
use lib '../../lib';
use ObjStore::MakeMaker qw(add_os_args os_schema_rule);

my $v = '02';
sub MY::postamble { os_schema_rule("REP-Splash-$v.sch") }

WriteMakefile(add_os_args(NAME => 'ObjStore::REP::Splash',
			  OBJECT => "Splash.o REP-Splash-$v.o"));
