#!perl

use utf8;
use strict;
use warnings;

use Test::More tests => 1;

use Regexp::Pattern::License;

my %RE = %Regexp::Pattern::License::RE;

my %NAMES = (
	agpl_3      => 'GNU Affero General Public License, Version 3',
	apache_1_1  => 'Apache Software License, Version 1.1',
	apache_2_0  => 'Apache License, Version 2.0',
	artistic_1  => 'Artistic License, (Version 1)',
	artistic_2  => 'Artistic License, Version 2.0',
	bsd         => 'BSD License (three-clause)',
	freebsd     => 'FreeBSD License (two-clause)',
	gfdl_1_2    => 'GNU Free Documentation License, Version 1.2',
	gfdl_1_3    => 'GNU Free Documentation License, Version 1.3',
	gpl_1       => 'GNU General Public License, Version 1',
	gpl_2       => 'GNU General Public License, Version 2',
	gpl_3       => 'GNU General Public License, Version 3',
	lgpl_2_1    => 'GNU Lesser General Public License, Version 2.1',
	lgpl_3_0    => 'GNU Lesser General Public License, Version 3.0',
	mit         => 'MIT (aka X11) License',
	mozilla_1_0 => 'Mozilla Public License, Version 1.0',
	mozilla_1_1 => 'Mozilla Public License, Version 1.1',
	openssl     => 'OpenSSL License',
	perl_5      => 'The Perl 5 License (Artistic 1 & GPL 1 or later)',
	qpl_1_0     => 'Q Public License, Version 1.0',
	ssleay      => 'Original SSLeay License',
	sun         => 'Sun Internet Standards Source License (SISSL)',
	zlib        => 'zlib License',
);

my %names = map {
	$RE{$_}{'name.alt.org.perl.synth.nogrant'}
		// $RE{$_}{'name.alt.org.perl'} =>
		$RE{$_}{'caption.alt.org.perl.synth.nogrant'}
		// $RE{$_}{'caption.alt.org.perl'} // $RE{$_}{caption}
	}
	grep {
	grep {/^name\.alt\.org\.perl(?:\.synth\.nogrant)?$/}
		keys %{ $RE{$_} }
	}
	keys %RE;

is_deeply(
	\%names, \%NAMES,
	'coverage of <https://metacpan.org/pod/CPAN::Meta::Spec#license>'
) || diag explain \%names;

done_testing;
