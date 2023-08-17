use v5.20;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.9.0';

use Path::Tiny;

use lib 't/lib';
use Uncruft;

use String::License;
use String::License::Naming::Custom;

my $CORPUS_DIR = 't/OSI';

my %crufty = (
	'BSD-2-Clause-Views' => undef,
	'BSD-3-Clause'       => undef,
	'GPL-2.0'            => undef,
	ISC                  => undef,
	MIT                  => undef,
	'MPL-1.1'            => undef,
	'MPL-2.0'            => undef,
	NTP                  => undef,
	'Python-2.0'         => 'CNRI-Python and/or PSF-2.0',
	Zlib                 => undef,
);

plan 26 + grep {defined} values %crufty;

my $naming
	= String::License::Naming::Custom->new( schemes => [qw(osi internal)] );

sub scanner ( $path, $state )
{
	my ( $expected, $string, $got, $todo );

	$expected = $path->basename('.txt');
	$string   = $path->slurp_utf8;
	$got      = String::License->new(
		string => $string,
		naming => $naming,
	)->as_text;

	if ( exists $crufty{ $path->relative($CORPUS_DIR) } ) {
		my $tolerated = $crufty{ $path->relative($CORPUS_DIR) };

		if ( defined $tolerated ) {
			my $got_too = String::License->new(
				string => uncruft($string),
				naming => $naming,
			)->as_text;

			note qq{tolerated: "$tolerated"};
			like $got_too, qr/^\Q$expected\E|\Q$tolerated\E$/,
				"Corpus file $path, pristine";
		}

		$todo = todo 'source content is messy';
	}

	like $got, $expected, "Corpus file $path";
}

path($CORPUS_DIR)->visit( \&scanner );

done_testing;
