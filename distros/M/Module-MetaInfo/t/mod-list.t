
=head1 DESCRIPTION

Tests for Module::MetaInfo::ModList

=cut

BEGIN {print "1..5\n"}
END {print "not ok 1\n" unless $loaded;}

sub nogo () {print "not "}
sub ok ($) {my $t=shift; print "ok $t\n";}

use Module::MetaInfo::ModList;

#$verbose = 255;
$loaded = 1;
ok(1);

$mod=new Module::MetaInfo::ModList("test-data/CDB_File-BiIndex-0.007.tar.gz",
				  "test-data/03modlist.data");

#make a temporary scratch directory... 

#we want to use only one so that we don't build up a big history of
#them taking up space but we can leave it lying around 
ok(2);

#Module::MetaInfo::AutoGuess->verbose($verbose);
nogo unless $mod->development_stage() eq 'a';

ok(3);

nogo unless $mod->support_level() eq 'u';

ok(4);

my $desc=$mod->description();

( $desc =~ m/index/ ) && ( $desc =~ m/CDB/ )
  or nogo;

ok(5);
