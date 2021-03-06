# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Symantec-PCAnywhere-Profile-CIF.t'

#########################

use strict;
use warnings;
use Digest::MD5;
use Test::More tests => 2;
#
# Test 1 ensures we have the module to begin with
#
BEGIN { use_ok('Symantec::PCAnywhere::Profile::CIF') };

###
# Main tests start here
###

# TODO: Test more/all fields
my %pairs = (
	CallerName      => 'JohnDoe',
	CallerPassword  => 'acw938nrh!'
);
# See note on test 3
#my @known_sums = (
#	'd6dd5cf070c554c465ec819a1e411d27'
#);

my @chf;
$chf[0] = new Symantec::PCAnywhere::Profile::CIF;
$chf[0]->set_attrs(%pairs);
my $data = $chf[0]->encode;

$chf[1] = new Symantec::PCAnywhere::Profile::CIF(-data => $data);
my $results = $chf[1]->get_attrs(keys %pairs);

#
# Test 2 checks whether parsing a fresh file gives sane output
#
is_deeply($results, \%pairs, 'Parse new file');

#
# Test 3 would test output against known checksums, but I no longer have an
# authoritative source.
#
#my @sums;
#my $md5 = new Digest::MD5;
#$chf[2] = new Symantec::PCAnywhere::Profile::CIF;
#$md5->add($chf[2]->encode);
#$sums[0] = $md5->hexdigest;
#is_deeply(\@sums, \@known_sums, "Correct checksums on default output");

