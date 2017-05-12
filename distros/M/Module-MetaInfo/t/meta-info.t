
=head1 DESCRIPTION

Tests for Module::MetaInfo

We use a specially chosen module for which the description and
documentation files are known to us...

=cut

BEGIN {print "1..19\n"}
END {print "not ok 1\n" unless $loaded;}

sub nogo () {print "not "}
sub ok ($) {my $t=shift; print "ok $t\n";}

use Module::MetaInfo;

$verbose = 255;
$loaded = 1;
ok(1);

#first we will test a module which doesn't have any explicit module info

$mod=new Module::MetaInfo("test-data/Getopt-Function-0.002.tar.gz",
			  "test-data/03modlist.data");

ok(2);

#make a temporary scratch directory...

#we want to use only one so that we don't build up a big history of
#them taking up space but we can leave it lying around

$scratch_dir= "/tmp/perl-metainfo-test-temp."
  . ( $ENV{LOGNAME} ? $ENV{LOGNAME} : ( $ENV{USER} ? $ENV{USER} : "dumb" ) );

Module::MetaInfo->scratch_dir($scratch_dir);
ok(3);
Module::MetaInfo->verbose($verbose);
ok(4);

$desc=$mod->description();

( $desc =~ m/hash/ ) && ( $desc =~ m/subroutine/ ) && ( $desc =~ m/hash/ )
  or nogo;

ok(5);

$doc=$mod->doc_files;

( grep (/README/, @$doc ) == 1 ) &&
( grep (/COPYING/, @$doc ) == 1 )or nogo;  # &&( grep ("TODO", @$doc ) == 1 )

ok(6);

#now test a module with packaged meta information

$mod=new Module::MetaInfo("test-data/Getopt-Function-0.007.tar.gz");

Module::MetaInfo->scratch_dir($scratch_dir);
ok(7);
Module::MetaInfo->verbose($verbose);
ok(8);

$desc=$mod->description();

( $desc =~ m/interface/ ) && ( $desc =~ m/automatically/ )
	&& ( $desc =~ m/option/ )
  or nogo;

ok(9);

$doc=$mod->doc_files();

( grep (/README/, @$doc ) == 1 ) &&
( grep (/COPYING/, @$doc ) == 1 )or nogo;  # &&( grep ("TODO", @$doc ) == 1 )

ok(10);

#check that we can do metainfo properly with the modlist even if the
#module isn't listed

$mod=new Module::MetaInfo("test-data/Getopt-Function-0.007.tar.gz",
			 "test-data/03modlist.data");

Module::MetaInfo->scratch_dir($scratch_dir);
ok(11);
Module::MetaInfo->verbose($verbose);
ok(12);

$desc=$mod->description();

( $desc =~ m/interface/ ) && ( $desc =~ m/automatically/ )
	&& ( $desc =~ m/option/ )
  or nogo;

ok(13);

$doc=$mod->doc_files();

( grep (/README/, @$doc ) == 1 ) &&
( grep (/COPYING/, @$doc ) == 1 )or nogo;  # &&( grep ("TODO", @$doc ) == 1 )

ok(14);

#check that we can cope with a module with no reasonable description..

$mod=new Module::MetaInfo("test-data/Not_A_Module-0.1.tar.gz",
			  "test-data/03modlist.data");

Module::MetaInfo->scratch_dir($scratch_dir);
Module::MetaInfo->verbose($verbose);

$desc=$mod->description();

nogo if defined $desc;

ok(15);

$mod=new Module::MetaInfo("test-data/CDB_File-BiIndex-0.001fake.tar.gz",
			 "test-data/03modlist.data");


#make a temporary scratch directory... 

#we want to use only one so that we don't build up a big history of
#them taking up space but we can leave it lying around 
ok(16);

#Module::MetaInfo::AutoGuess->verbose($verbose);
nogo unless $mod->development_stage() eq 'a';

ok(17);

nogo unless $mod->support_level() eq 'u';

ok(18);

my $desc=$mod->description();

( $desc =~ m/index/ ) && ( $desc =~ m/CDB/ )
  or nogo;

ok(19);
