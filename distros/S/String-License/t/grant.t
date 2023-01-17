use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.9.0';

use Path::Tiny;

use lib 't/lib';
use Uncruft;

use String::License;
use String::License::Naming::Custom;

plan 50;

my %crufty = (
	'AFL_and_more/xdgmime.c'           => undef,
	'AGPL/fastx.c'                     => undef,
	'AGPL/fet.cpp'                     => undef,
	'Apache_and_more/select2.js'       => undef,
	'CC-BY-SA_and_more/utilities.scad' => undef,
	'LGPL/Model.pm'                    => undef,
	'LGPL/criu.h'                      => undef,
	'LGPL/gnome.h'                     => undef,
	'LGPL/jitterbuf.h'                 => undef,
	'LGPL/libotr.m4'                   => undef,
	'LGPL/strv.c'                      => undef,
	'LGPL/table.py'                    => undef,
	'LGPL/videoplayer.cpp'             => undef,
	'LGPL_and_more/colamd.c'           => undef,
	'MPL_and_more/symbolstore.py'      => undef,
	'misc/rpplexer.h'                  => undef,
	'MIT/gc.h'                         => undef,
	'MIT/harfbuzz-impl.c'              => undef,
	'MIT/spaces.c'                     => undef,
	'NTP/helvO12.bdf'                  => undef,
	'NTP/gslcdf-module.c'              => undef,
	'NTP/install.sh'                   => undef,
	'WTFPL/COPYING.WTFPL'              => undef,
);

my $naming
	= String::License::Naming::Custom->new(
	schemes => [qw(debian spdx internal)] );

my $todo;

sub parse
{
	my $path   = path(shift);
	my $string = $path->slurp_utf8;
	$string = uncruft($string)
		if exists $crufty{ $path->relative('t/grant') };

	my $license = String::License->new(
		string => $string,
		naming => $naming,
	)->as_text;

	return $license;
}

# AFL
like parse('t/grant/AFL_and_more/xdgmime.c'), 'AFL-2.0 and/or LGPL-2+';

$todo = todo 'not yet supported';
like parse('t/grant/AFL_and_more/xdgmime.c'), 'AFL-2.0 or LGPL-2+';
$todo = undef;

# AGPL
like parse('t/grant/AGPL/fastx.c'),  'AGPL-3+';
like parse('t/grant/AGPL/fet.cpp'),  'AGPL-3+';
like parse('t/grant/AGPL/setup.py'), 'AGPL-3+';

# Apache
like parse('t/grant/Apache_and_more/PIE.htc'), 'Apache-2.0 or GPL-2';
like parse('t/grant/Apache_and_more/rust.lang'),
	'Apache-2.0 or MIT~unspecified';
like parse('t/grant/Apache_and_more/select2.js'),  'Apache-2.0 or GPL-2';
like parse('t/grant/Apache_and_more/test_run.py'), 'UNKNOWN';

$todo = todo 'not yet supported';
like parse('t/grant/Apache_and_more/test_run.py'),
	'Apache-2.0 or BSD-3-clause';
$todo = undef;

# CC-BY-SA
like parse('t/grant/CC-BY-SA_and_more/WMLA'),           'UNKNOWN';
like parse('t/grant/CC-BY-SA_and_more/cewl.rb'),        'CC-BY-SA-2.0';
like parse('t/grant/CC-BY-SA_and_more/utilities.scad'), 'CC-BY-SA-3.0';

$todo = todo 'not yet supported';
like parse('t/grant/CC-BY-SA_and_more/WMLA'), 'CC-BY-SA-3.0 and/or GFDL-1.2';
like parse('t/grant/CC-BY-SA_and_more/cewl.rb'), 'CC-BY-SA-2.0 or GPL-3';
like parse('t/grant/CC-BY-SA_and_more/utilities.scad'),
	'CC-BY-SA-3.0 or LGPL-2';
$todo = undef;

# EPL
like parse('t/grant/EPL_and_more/Activator.java'),   'EPL-1.0';
like parse('t/grant/EPL_and_more/Base64Coder.java'), 'UNKNOWN';

$todo = todo 'not yet supported';
like parse('t/grant/EPL_and_more/Activator.java'),
	'BSD-3-clause~Refractions or EPL-1.0';
like parse('t/grant/EPL_and_more/Base64Coder.java'),
	'AGPL-3+ or Apache-2.0+ or EPL-1.0+ or GPL-3+ or LGPL-2.1+';
$todo = undef;

# LGPL
like parse('t/grant/LGPL/Model.pm'),          'LGPL-2.1';
like parse('t/grant/LGPL/PKG-INFO'),          'LGPL';
like parse('t/grant/LGPL/criu.h'),            'LGPL-2.1';
like parse('t/grant/LGPL/dqblk_xfs.h'),       'LGPL';
like parse('t/grant/LGPL/exr.h'),             'LGPL';
like parse('t/grant/LGPL/gnome.h'),           'LGPL-2.1';
like parse('t/grant/LGPL/jitterbuf.h'),       'LGPL';
like parse('t/grant/LGPL/libotr.m4'),         'LGPL-2.1';
like parse('t/grant/LGPL/pic.c'),             'LGPL-3';
like parse('t/grant/LGPL/strv.c'),            'LGPL-2.1+';
like parse('t/grant/LGPL/table.py'),          'LGPL-2+';
like parse('t/grant/LGPL/videoplayer.cpp'),   'LGPL-2.1 or LGPL-3';
like parse('t/grant/LGPL_and_more/colamd.c'), 'LGPL-2.1+ and/or LGPL-bdwgc';
like parse('t/grant/LGPL_and_more/da.aff'),   'UNKNOWN';

$todo = todo 'not yet supported';
like parse('t/grant/LGPL_and_more/da.aff'), 'GPL-2 or LGPL-2.1 or MPL-1.1';
$todo = undef;

# MPL
like parse('t/grant/MPL_and_more/symbolstore.py'),
	'GPL-2+ and/or GPL-2+ or LGPL-2.1+ and/or MPL-1.1';

$todo = todo 'not yet supported';
like parse('t/grant/MPL_and_more/symbolstore.py'),
	'GPL-2+ or LGPL-2.1+ or MPL-1.1';
$todo = undef;

# misc
like parse('t/grant/misc/rpplexer.h'),
	'(GPL-3 and/or LGPL-2.1 or LGPL-3) with Qt-LGPL-1.1 exception';

$todo = todo 'not yet supported';
like parse('t/grant/misc/rpplexer.h'),
	'GPL-3 or LGPL-2.1 with Qt exception or LGPL-3 with Qt-LGPL-1.1 exception or Qt';
$todo = undef;

# MIT
like parse('t/grant/MIT/gc.h'),            qr/MIT~Boehm|bdwgc/;
like parse('t/grant/MIT/old_colamd.c'),    'bdwgc-matlab';
like parse('t/grant/MIT/harfbuzz-impl.c'), 'MIT~old';
like parse('t/grant/MIT/spaces.c'),        'MIT~oldstyle~permission';

# NTP
like parse('t/grant/NTP/helvO12.bdf'),     'NTP';
like parse('t/grant/NTP/directory.h'),     'NTP';
like parse('t/grant/NTP/map.h'),           'NTP';
like parse('t/grant/NTP/monlist.c'),       'NTP';
like parse('t/grant/NTP/gslcdf-module.c'), 'NTP~disclaimer';
like parse('t/grant/NTP/install.sh'),      'HPND-sell-variant';

# WTFPL
like parse('t/grant/WTFPL/COPYING.WTFPL'), 'WTFPL-1.0';

done_testing;
