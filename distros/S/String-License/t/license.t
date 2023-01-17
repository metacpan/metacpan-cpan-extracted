use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.9.0';

use Path::Tiny;

use lib 't/lib';
use Uncruft;

use String::License;
use String::License::Naming::Custom;

plan 35;

my %crufty = (
	'artistic-2-0-modules.pm'     => undef,
	'bsd-1-clause-1.c'            => undef,
	'bsd.f'                       => undef,
	'bsd-3-clause.cpp'            => undef,
	'gpl-1'                       => undef,
	'gpl-2+'                      => undef,
	'gpl-2+.scm'                  => undef,
	'gpl-3.sh'                    => undef,
	'gpl-3-only.c'                => undef,
	'gpl-3+'                      => undef,
	'gpl-3+-with-rem-comment.xml' => undef,
	'gpl-variation.c'             => undef,
	'gpl-3+.el'                   => undef,
	'comments-detection.h'        => undef,
	'mpl-1.1.sh'                  => undef,
	'mpl-2.0.sh'                  => undef,
	'mpl-2.0-comma.sh'            => undef,
	'cddl.h'                      => undef,
	'libuv-isc.am'                => undef,
	'info-at-eof.h'               => undef,
);

my $naming
	= String::License::Naming::Custom->new(
	schemes => [qw(debian spdx internal)] );

sub parse
{
	my $path   = path(shift);
	my $string = $path->slurp_utf8;
	$string = uncruft($string)
		if exists $crufty{ $path->relative('t/devscripts') };

	my $license = String::License->new(
		string => $string,
		naming => $naming,
	)->as_text;

	return $license;
}

like parse('t/devscripts/academic.h'), 'AFL-3.0';

like parse('t/grant/Apache/one_helper.rb'), 'Apache-2.0';

like parse('t/devscripts/artistic-2-0-modules.pm'), 'Artistic-2.0';
like parse('t/devscripts/artistic-2-0.txt'),        'Artistic-2.0';

like parse('t/devscripts/beerware.cpp'), 'Beerware';

like parse('t/devscripts/bsd-1-clause-1.c'), 'BSD-1-Clause';

like parse('t/devscripts/bsd.f'), 'BSD-2-clause';

like parse('t/devscripts/bsd-3-clause.cpp'),          'BSD-3-clause';
like parse('t/devscripts/bsd-3-clause-authorsany.c'), 'BSD-3-clause';
like parse('t/devscripts/mame-style.c'),              'BSD-3-clause';

like parse('t/devscripts/boost.h'), 'BSL-1.0';

like parse('t/devscripts/epl.h'), 'EPL-1.0';

# Lisp Lesser General Public License (BTS #806424)
# see http://opensource.franz.com/preamble.html
like parse('t/devscripts/llgpl.lisp'), 'LLGPL';

like parse('t/devscripts/gpl-no-version.h'), 'GPL';

like parse('t/devscripts/gpl-1'), 'GPL-1+';

like parse('t/devscripts/gpl-2'),                   'GPL-2';
like parse('t/devscripts/bug-559429'),              'GPL-2';
like parse('t/devscripts/gpl-2-comma.sh'),          'GPL-2';
like parse('t/devscripts/gpl-2-incorrect-address'), 'GPL-2';

like parse('t/devscripts/gpl-2+'),     'GPL-2+';
like parse('t/devscripts/gpl-2+.scm'), 'GPL-2+';

like parse('t/devscripts/gpl-3.sh'),     'GPL-3';
like parse('t/devscripts/gpl-3-only.c'), 'GPL-3';

like parse('t/devscripts/gpl-3+'),                      'GPL-3+';
like parse('t/devscripts/gpl-3+-with-rem-comment.xml'), 'GPL-3+';
like parse('t/devscripts/gpl-variation.c'),             'GPL-3+';

like parse('t/devscripts/gpl-3+.el'),            'GPL-3+';
like parse('t/devscripts/comments-detection.h'), 'GPL-3+';

like parse('t/devscripts/mpl-1.1.sh'), 'MPL-1.1';

like parse('t/devscripts/mpl-2.0.sh'),       'MPL-2.0';
like parse('t/devscripts/mpl-2.0-comma.sh'), 'MPL-2.0';

like parse('t/devscripts/freetype.c'), 'FTL';

like parse('t/devscripts/cddl.h'), 'CDDL';

like parse('t/devscripts/libuv-isc.am'), 'ISC';

like parse('t/devscripts/info-at-eof.h'), 'Expat';

done_testing;
