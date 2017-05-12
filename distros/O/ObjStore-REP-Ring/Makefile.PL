#!./perl -w

use strict;
use ExtUtils::MakeMaker;
use ObjStore::MakeMaker qw(add_os_args os_schema_rule);
my $v = '01';

my @PREFIX = (PREFIX => $ENV{PERL5PREFIX})
    if exists $ENV{PERL5PREFIX};

my %args = (
	    @PREFIX,
	    VERSION_FROM => "Ring.pm",
	    PREREQ_PM	 => { ObjStore => '1.47' },
	    NAME         => 'ObjStore::REP::Ring',
	    OBJECT       => "Ring.o REP-Ring-$v.o",
);

WriteMakefile(add_os_args(%args));

sub MY::postamble { os_schema_rule("REP-Ring-$v.sch") }
