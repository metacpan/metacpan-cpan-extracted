use lib 't/lib';
use blib 'perl_impl';
use SPVM 'Digest::SHA';
use Digest::SHA;
use SPVMImpl;
Digest::SHA::is_spvm();
die unless $INC{'Digest/SHA.pm'} =~ /\bblib\b/;

use strict;

my $skip;

BEGIN {
	eval "use Test::More";
	$skip = $@ ? 1 : 0;
	unless ($skip) {
		eval "use Test::Pod 1.00";
		$skip = 2 if $@;
	}
}

if ($skip == 1) {
	print "1..0 # Skipped: Test::More not installed\n";
	exit;
}

if ($skip == 2) {
	print "1..0 # Skipped: Test::Pod 1.00 required for testing POD\n";
	exit;
}

all_pod_files_ok();
