
=head1 DESCRIPTION

Tests for Module::MetaInfo::_Extractor 

This is the base class which doesn't do much useful..  But it does
unpack the distributions for us.

=cut

BEGIN {print "1..11\n"}
END {print "not ok 1\n" unless $loaded;}

sub nogo () {print "not "}
sub ok ($) {my $t=shift; print "ok $t\n";}

use Module::MetaInfo::_Extractor;
$loaded = 1;

ok(1);

$scratch_dir= "/tmp/perl-metainfo-test-temp."
  . ( $ENV{LOGNAME} ? $ENV{LOGNAME} : ( $ENV{USER} ? $ENV{USER} : "dumb" ) );

Module::MetaInfo::_Extractor->verbose(4);
my $verb=Module::MetaInfo::_Extractor->verbose();

nogo unless $verb==4;

ok(2);

Module::MetaInfo::_Extractor->scratch_dir($scratch_dir);
my $sdir=Module::MetaInfo::_Extractor->scratch_dir();

nogo unless $sdir eq $scratch_dir;

ok(3);

#create an extractor
$mod=
  new Module::MetaInfo::_Extractor("test-data/Getopt-Function-0.007.tar.gz");

# check that verbose is what we set it to

$verb=$mod->verbose();
nogo unless $verb==4;

ok(4);

# check that the scratchdir is what we set it to

$sdir=Module::MetaInfo::_Extractor->scratch_dir();
nogo unless $sdir eq $scratch_dir;

ok(5);

# check that we can change the objects verbosity

$mod->verbose(8);

$verb=$mod->verbose();

nogo unless $verb==8;

ok(6);

# check that we can change the objects scratchdir


$scratch_dir_two= "/tmp/perl-metainfo-test-temp."
  . ( $ENV{LOGNAME} ? $ENV{LOGNAME} : ( $ENV{USER} ? $ENV{USER} : "dumb" ) );

$mod->scratch_dir($scratch_dir_two);
$sdir=$mod->scratch_dir();
nogo unless $sdir eq $scratch_dir_two;

ok(7);

# check that we didn't change the module verbose setting

$verb=Module::MetaInfo::_Extractor->verbose();

nogo unless $verb==4;

ok(8);

# check that we didn't change the module scratch_dir setting

$sdir=Module::MetaInfo::_Extractor->scratch_dir();

nogo unless $sdir eq $scratch_dir;

ok(9);

#clean out the scratch dir.. being careful

die "test error: scratch dir not defined" unless $scratch_dir_two;
system 'rm',  '-rf',  $scratch_dir_two;# == 0 or die 'call to rm failed';

# try setting up

-e $scratch_dir_two and die "Failed to delete scratch directory $scratch_dir_two";

$mod->setup();

-e $scratch_dir_two .'/'. "Getopt-Function-0.007.tar.gz/Getopt-Function-0.007/"
  . "Makefile.PL" or nogo;

ok(10);

my $name=$mod->name();

nogo unless $name eq "Getopt-Function-0.007";

ok(11);

