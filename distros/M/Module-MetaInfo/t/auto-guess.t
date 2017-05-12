
=head1 DESCRIPTION

Tests for Module::MetaInfo

We use a specially chosen module for which the description and
documentation files are known to us...

=cut

BEGIN {print "1..6\n"}
END {print "not ok 1\n" unless $loaded;}

sub nogo () {print "not "}
sub ok ($) {my $t=shift; print "ok $t\n";}

use Module::MetaInfo::AutoGuess;

$verbose = 255;
$loaded = 1;
ok(1);
$mod=new Module::MetaInfo::AutoGuess("test-data/Getopt-Function-0.007.tar.gz");

#make a temporary scratch directory... 

#we want to use only one so that we don't build up a big history of
#them taking up space but we can leave it lying around 
ok(2);

$scratch_dir= "/tmp/perl-metainfo-test-temp."
  . ( $ENV{LOGNAME} ? $ENV{LOGNAME} : ( $ENV{USER} ? $ENV{USER} : "dumb" ) );

Module::MetaInfo::AutoGuess->scratch_dir($scratch_dir);
ok(3);

Module::MetaInfo::AutoGuess->verbose($verbose);
ok(4);

$desc=$mod->description();

( $desc =~ m/hash/ ) && ( $desc =~ m/subroutine/ ) && ( $desc =~ m/hash/ )
  or nogo;

ok(5);

$doc=$mod->doc_files;

( grep (/README/, @$doc ) == 1 ) &&
( grep (/COPYING/, @$doc ) == 1 )or nogo;  # &&( grep ("TODO", @$doc ) == 1 )

ok(6);

