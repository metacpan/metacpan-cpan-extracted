use Test2::V0;

plan 1;

use Regexp::Pattern::License;

my %RE = %Regexp::Pattern::License::RE;

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

is \%names, hash {
	field agpl_3      => 'GNU Affero General Public License, Version 3';
	field apache_1_1  => 'Apache Software License, Version 1.1';
	field apache_2_0  => 'Apache License, Version 2.0';
	field artistic_1  => 'Artistic License, (Version 1)';
	field artistic_2  => 'Artistic License, Version 2.0';
	field bsd         => 'BSD License (three-clause)';
	field freebsd     => 'FreeBSD License (two-clause)';
	field gfdl_1_2    => 'GNU Free Documentation License, Version 1.2';
	field gfdl_1_3    => 'GNU Free Documentation License, Version 1.3';
	field gpl_1       => 'GNU General Public License, Version 1';
	field gpl_2       => 'GNU General Public License, Version 2';
	field gpl_3       => 'GNU General Public License, Version 3';
	field lgpl_2_1    => 'GNU Lesser General Public License, Version 2.1';
	field lgpl_3_0    => 'GNU Lesser General Public License, Version 3.0';
	field mit         => 'MIT (aka X11) License';
	field mozilla_1_0 => 'Mozilla Public License, Version 1.0';
	field mozilla_1_1 => 'Mozilla Public License, Version 1.1';
	field openssl     => 'OpenSSL License';
	field perl_5      => 'The Perl 5 License (Artistic 1 & GPL 1 or later)';
	field qpl_1_0     => 'Q Public License, Version 1.0';
	field ssleay      => 'Original SSLeay License';
	field sun         => 'Sun Internet Standards Source License (SISSL)';
	field zlib        => 'zlib License';

	end();
}, 'coverage of <https://metacpan.org/pod/CPAN::Meta::Spec#license>',
	\%names;

done_testing;
