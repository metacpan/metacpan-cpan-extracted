# $Id: 40regression_test.t 976 2007-03-04 20:47:36Z nicolaw $

chdir('t') if -d 't';

use strict;
use warnings;
use Test::More;
use lib qw(./lib ../lib);
use Parse::DMIDecode qw();

my @files = glob('testdata/*');
plan tests => (scalar(@files)*21) + 1;

my $dmi;
ok($dmi = Parse::DMIDecode->new(nowarnings => 1),'new');

for my $file (@files) {
	ok($dmi->parse(slurp($file)),$file);

	ok($dmi->smbios_version >= 2.0,"$file \$dmi->smbios_version");
	#ok($dmi->dmidecode_version >= 2.0,"$file \$dmi->dmidecode_version");
	ok($dmi->table_location,"$file \$dmi->table_location");

	my @handle_addresses = $dmi->handle_addresses;
	my @uniq_handle_addresses = uniq(@handle_addresses); 
	ok(scalar(@handle_addresses) >= $dmi->structures,"$file \$dmi->handle_addresses >= \$dmi->handle_structures");
	ok(scalar(@uniq_handle_addresses) == $dmi->structures,"$file unique handle address == \$dmi->handle_structures");

	for my $dmitype (qw(0 1 2 3)) {
		my @handles;
		ok(
			@handles = $dmi->get_handles( dmitype => $dmitype ),
			"$file \$dmi->get_handles(dmitype => $dmitype)"
		);
		ok($handles[0]->dmitype == $dmitype,"$file \$handle->dmitype");
		ok($handles[0]->bytes =~ /^\d+$/,"$file \$handle->bytes");
		ok($handles[0]->description =~ /^\S.{4,64}$/,"$file \$handle->description");
	}
}

sub uniq {
	my %uniq;
	$uniq{$_} = undef for @_;
	return sort keys %uniq;
}

sub slurp {
	my $file = shift;
	my $data = '';
	if (open(FH,'<',$file)) {
		local $/ = undef;
		$data = <FH>;
		close(FH);
	}
	return $data;
}

1;

