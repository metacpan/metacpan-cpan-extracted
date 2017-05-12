
=head1 DESCRIPTION

Tests for Module::MetaInfo::DirTree

We use a specially chosen module for which the description and
documentation files are known to us...

=cut

BEGIN {print "1..9\n"}
END {print "not ok 1\n" unless $loaded;}

sub nogo () {print "not "}
sub ok ($) {my $t=shift; print "ok $t\n";}

use Module::MetaInfo::DirTree;

$verbose = 255;
$loaded = 1;

#make a temporary scratch directory... 
$scratch_dir= "/tmp/perl-metainfo-test-temp."
  . ( $ENV{LOGNAME} ? $ENV{LOGNAME} : ( $ENV{USER} ? $ENV{USER} : "dumb" ) );

system 'rm -rf $scratch_dir';

ok(1);

Module::MetaInfo::DirTree->scratch_dir($scratch_dir);
ok(2);

$mod=new Module::MetaInfo::DirTree("test-data/Getopt-Function-0.007.tar.gz");


#we want to use only one so that we don't build up a big history of
#them taking up space but we can leave it lying around 
ok(3);

Module::MetaInfo::DirTree->verbose($verbose);
ok(4);

$desc=$mod->description();

( $desc =~ m/interface/ ) && ( $desc =~ m/automatically/ ) 
	&& ( $desc =~ m/option/ )
  or nogo;

ok(5);

$doc=$mod->doc_files();

( grep (/README/, @$doc ) == 1 ) &&
( grep (/COPYING/, @$doc ) == 1 )or nogo;  # &&( grep ("TODO", @$doc ) == 1 )

ok(6);

$mod=new Module::MetaInfo::DirTree("test-data/Getopt-Function-0.004.tar.gz");

ok(7);

$desc=$mod->description();

#there is no description so we return undef

nogo if defined $desc;

ok(8);

$files=$mod->doc_files();

#there is no description so we return undef

nogo if defined $files;

ok(9);
