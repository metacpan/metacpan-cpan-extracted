use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.9.0';
use Test2::Require::Module 'Software::LicenseUtils'   => '0.104002';

use Software::LicenseUtils;
use Path::Tiny 0.053;

use lib 't/lib';
use Uncruft;

use String::License;
use String::License::Naming::SPDX;

my %LICENSES = (
	'AGPL-3.0'             => 'AGPLv3',
	'Apache-1.1'           => undef,
	'Apache-2.0'           => undef,
	'Artistic-1.0'         => undef,
	'Artistic-2.0'         => undef,
	'BSD'                  => 'BSD-3-Clause',
	'CC0-1.0'              => undef,
	'EUPL-1.1'             => undef,
	'EUPL-1.2'             => undef,
	'BSD-2-Clause-FreeBSD' => 'BSD-2-Clause',
	'GFDL-1.2-or-later'    => 'GFDL-1.2-or-later and/or GFDL-1.3',
	'GFDL-1.3-or-later'    => undef,
	'GPL-1.0-only'         => 'GPL-1.0',
	'GPL-2.0-only'         => 'GPL-2',
	'GPL-3.0-only'         => 'GPL-3',
	'ISC'                  => undef,
	'LGPL-2.1'             => undef,
	'LGPL-3.0'             => 'LGPL-3',
	'MIT'                  => undef,
	'MPL-1.0'              => undef,
	'MPL-1.1'              => undef,
	'MPL-2.0'              => undef,
	'OpenSSL'              => 'OpenSSL and/or SSLeay',
	'Artistic-1.0-Perl OR GPL-1.0-or-later' =>
		'Artistic-1.0 and/or GPL-1.0 and/or Perl',
	'PostgreSQL' => undef,
	'QPL-1.0'    => undef,
	'SSLeay'     => undef,
	'SISSL'      => undef,
	'Zlib'       => undef,
);

my %crufty = (
	'Apache-1.1'                              => 'UNKNOWN',
	'Artistic-1.0'                            => 'UNKNOWN',
	'Artistic-1.0 and/or GPL-1.0 and/or Perl' => 'GPL',
	'BSD-3-Clause'                            => 'UNKNOWN',
	'BSD-2-Clause'                            => 'UNKNOWN',
	'EUPL-1.1'                                => 'UNKNOWN',
	'GFDL-1.2-or-later and/or GFDL-1.3'       => 'GFDL-1.2-or-later',
	'GPL-1.0'                                 => 'GPL',
	'GPL-2'                                   => 'GPL',
	'ISC'                                     => 'UNKNOWN',
	'LGPL-3'                                  => 'UNKNOWN',
	'MIT'                                     => 'UNKNOWN',
	'MPL-1.0'                                 => 'UNKNOWN',
	'MPL-1.1'                                 => 'UNKNOWN',
	'MPL-2.0'                                 => 'UNKNOWN',
	'OpenSSL and/or SSLeay'                   => 'SSLeay',
	'QPL-1.0'                                 => 'QPL',
	'SISSL'                                   => 'UNKNOWN',
	'Zlib'                                    => 'UNKNOWN',
);

plan 0 + keys %LICENSES;

my $naming = String::License::Naming::SPDX->new;

my $workdir = Path::Tiny->tempdir( CLEANUP => ( not $ENV{PRESERVE} ) );
diag("Detect PRESERVE in environment, so will keep workdir: $workdir")
	if $ENV{PRESERVE};
foreach my $id ( sort keys %LICENSES ) {
	my ( $string, $license, $file, $expected, $resolved );
	eval {
		$license = Software::LicenseUtils->new_from_spdx_expression(
			{   spdx_expression => $id,
				holder => 'Testophilus Testownik <tester@testity.org>',
				year   => 2000,
			}
		);
	};
	skip_all "Software::License failed to create license $id" if $@;
	$file = $workdir->child($id);
	$file->spew_utf8( $license->notice, $license->license );
	$expected = $LICENSES{$id} // $id;
	$string   = $file->slurp_utf8;
	$string   = uncruft($string)
		if exists $crufty{$expected};
	$resolved = String::License->new(
		string => $string,
		naming => $naming,
	)->as_text;
	like $resolved, $expected,
		"matches expected license for SPDX id $id";
}

done_testing;
