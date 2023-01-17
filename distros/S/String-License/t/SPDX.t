use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.9.0';

use Path::Tiny;

use lib 't/lib';
use Uncruft;

use String::License;
use String::License::Naming::SPDX;

plan 88;

my %crufty = (
	'AGPL-3.0'             => undef,
	'BSD-2-Clause'         => undef,
	'CC-BY-1.0'            => undef,
	'CC-BY-NC-ND-1.0'      => undef,
	'CC-BY-NC-ND-2.0'      => undef,
	'CC-BY-NC-ND-2.5'      => undef,
	'CC-BY-NC-ND-3.0'      => undef,
	'CC-BY-ND-1.0'         => undef,
	'CC-BY-ND-2.0'         => undef,
	'CC-BY-ND-2.5'         => undef,
	'CC-BY-ND-3.0'         => undef,
	'LGPL-2.0'             => undef,
	'LGPL-2.1'             => undef,
	'Python-2.0'           => undef,
	Zlib                   => undef,
	'zlib-acknowledgement' => undef,
);

# TODO: Report SPDX bug: Missing versioning
my %Debian2SPDX = (
	'AGPLv3'  => 'AGPL-3.0',
	'LGPL-2'  => 'LGPL-2.0',
	'WTFPL-2' => 'WTFPL',
);

my $naming = String::License::Naming::SPDX->new;

sub scanner
{
	my $expected = $_->basename('.txt');
	my $string   = $_->slurp_utf8;
	$string = uncruft($string)
		if exists $crufty{$expected};

	my $license = String::License->new(
		string => $string,
		naming => $naming,
	)->as_text;
	my $todo;

	is $Debian2SPDX{$license} || $license, $expected, "Corpus file $_";
}

path("t/SPDX")->visit( \&scanner );

done_testing;
