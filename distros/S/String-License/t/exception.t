use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.5.0';

use Path::Tiny;

use lib 't/lib';
use Uncruft;

use String::License;
use String::License::Naming::Custom;

plan 47;

my %crufty = (
	'Autoconf/autotroll.m4'                => undef,
	'Autoconf/ax_pthread.m4'               => undef,
	'Autoconf/m4_ax_func_getopt_long.m4'   => undef,
	'Autoconf/mkerrcodes1.awk'             => undef,
	'Autoconf/pkg.m4'                      => undef,
	'Bison/grammar.cxx'                    => undef,
	'Bison/parse-date.c'                   => undef,
	''                                     => undef,
	''                                     => undef,
	''                                     => undef,
	''                                     => undef,
	''                                     => undef,
	''                                     => undef,
	''                                     => undef,
	''                                     => undef,
	''                                     => undef,
	'Classpath/CDDL-GPL-2-CP'              => undef,
	'Classpath/GPL-2-CP'                   => undef,
	'Classpath/LICENSE'                    => undef,
	'EPL/mdb_bot_sup.erl'                  => undef,
	'EPL/ts_proxy_http.erl'                => undef,
	'FAUST/alsa-dsp.h'                     => undef,
	'GCC/unwind-cxx.h'                     => undef,
	'GStreamer/ev-properties-main.c'       => undef,
	'GStreamer/hwp-properties-main.c'      => undef,
	'GStreamer/totem-object.c'             => undef,
	'Libtool/lt__dirent.h'                 => undef,
	'non-GPL/buildnum.pl'                  => undef,
	'OCaml/LICENSE.txt'                    => undef,
	'OpenSSL/LICENSE'                      => undef,
	'OpenSSL/crypto_openssl.c'             => undef,
	'OpenSSL/pokerth.cpp'                  => undef,
	'OpenSSL/retr.h'                       => undef,
	'OpenSSL/simplexml.h'                  => undef,
	'Proguard/GPL-with-Proguard-exception' => undef,
	'Proguard/LICENSE_exception.md'        => undef,
	'Qt/kcmaudiocd.h'                      => undef,
	'Qt/konsolekalendaradd.h'              => undef,
	'Qt/qatomic_aarch64.h'                 => undef,
	'Qt/qsslconfiguration.h'               => undef,
	'SDC/sdc.py'                           => undef,
	'Cecill/tv_implementpoly.reference'    => undef,
	'Warzone/COPYING.README'               => undef,
	'Xerces/generator.cxx'                 => undef,
);

my $naming
	= String::License::Naming::Custom->new( schemes => [qw(debian spdx)] );

my $todo;

sub parse
{
	my $path   = path(shift);
	my $string = $path->slurp_utf8;
	$string = uncruft($string)
		if exists $crufty{ $path->relative('t/exception') };
	my $license = String::License->new(
		string => $string,
		naming => $naming,
	)->as_text;

	return $license;
}

# Autotools
like parse('t/exception/Autoconf/autotroll.m4'),
	'GPL-2+ with Autoconf-2.0~AutoTroll exception';
like parse('t/exception/Autoconf/ax_pthread.m4'),
	'GPL-3+ with Autoconf-2.0~Archive exception';
like parse('t/exception/Autoconf/m4_ax_func_getopt_long.m4'),
	'GPL-2+ with Autoconf-2.0~Archive exception';
like parse('t/exception/Autoconf/mkerrcodes1.awk'),
	'GPL-2+ with Autoconf-2.0~g10 exception';
like parse('t/exception/Autoconf/pkg.m4'),
	'GPL-2+ with Autoconf-data exception';

# Bison
like parse('t/exception/Bison/grammar.cxx'),
	'(Apache-2.0 and/or GPL-2+ and/or MPL-2.0) with Bison-1.24 exception';
like parse('t/exception/Bison/parse-date.c'),
	'GPL-3+ with Bison-2.2 exception';

$todo = todo 'not yet supported';
like parse('t/exception/Bison/grammar.cxx'),
	'Apache-2.0 and/or GPL-2+ with Bison-1.24 exception and/or MPL-2.0';
$todo = undef;

# Classpath
like parse('t/exception/Classpath/CDDL-GPL-2-CP'),
	'(CDDL-1.0 and/or GPL-2) with Classpath-2.0 exception';
like parse('t/exception/Classpath/GPL-2-CP'),
	'GPL-2 with Classpath-2.0 exception';
like parse('t/exception/Classpath/LICENSE'),
	'GPL-2 with Classpath-2.0 exception';

$todo = todo 'not yet supported';
like parse('t/exception/Classpath/CDDL-GPL-2-CP'),
	'CDDL-1.0 and/or GPL-2 with Classpath-2.0 exception';
$todo = undef;

# EPL
like parse('t/exception/EPL/mdb_bot_sup.erl'),
	'(EPL and/or GPL-2+) with EPL-library exception';
like parse('t/exception/EPL/ts_proxy_http.erl'),
	'(EPL and/or GPL-2+) with EPL-MPL-library exception';

$todo = todo 'not yet supported';
like parse('t/exception/EPL/mdb_bot_sup.erl'),
	'EPL with EPL-library exception and/or GPL-2+';
like parse('t/exception/EPL/ts_proxy_http.erl'),
	'EPL with EPL-MPL-library exception and/or GPL-2+';
$todo = undef;

# FAUST
like parse('t/exception/FAUST/alsa-dsp.h'), 'GPL-3+ with FAUST exception';

# Font
$todo = todo 'not yet supported by Regexp::Pattern::License';
like parse('t/exception/Font/LICENSE'),
	'AGPL-3 with PS-or-PDF-font exception';
$todo = undef;

# GCC
# Libtool
like parse('t/exception/GCC/unwind-cxx.h'), 'GPL-2+ with mif exception';

# GStreamer
# Libtool
like parse('t/exception/GStreamer/ev-properties-main.c'),
	'GPL-2+ with GStreamer exception';
like parse('t/exception/GStreamer/hwp-properties-main.c'),
	'GPL-2+ with GStreamer exception';
like parse('t/exception/GStreamer/totem-object.c'),
	'GPL-2+ with GStreamer exception';

# Libtool
like parse('t/exception/Libtool/lt__dirent.h'),
	'LGPL-2+ with Libtool exception';

# non-GPL
like parse('t/exception/non-GPL/buildnum.pl'), 'GPL-2 with 389 exception';

# OCaml
like parse('t/exception/OCaml/LICENSE.txt'),
	'LGPL-2 with OCaml-LGPL-linking exception';

# OpenSSL
like parse('t/exception/OpenSSL/LICENSE'), 'GPL-2 with OpenSSL~s3 exception';
like parse('t/exception/OpenSSL/crypto_openssl.c'),
	'LGPL-2.1+ with OpenSSL~LGPL exception';
like parse('t/exception/OpenSSL/pokerth.cpp'),
	'(AGPL-3+ and/or OpenSSL) with OpenSSL exception';
like parse('t/exception/OpenSSL/retr.h'),
	'(GPL-3+ and/or OpenSSL) with OpenSSL exception';
like parse('t/exception/OpenSSL/simplexml.h'),
	'GPL-3 with OpenSSL~s3 exception';

$todo = todo 'not yet supported';
like parse('t/exception/OpenSSL/pokerth.cpp'),
	'AGPL-3+ with OpenSSL exception';
like parse('t/exception/OpenSSL/retr.h'), 'GPL-3+ with OpenSSL exception';
$todo = undef;

# Proguard
like parse('t/exception/Proguard/GPL-with-Proguard-exception'),
	'GPL-2+ with Proguard exception';
like parse('t/exception/Proguard/LICENSE_exception.md'),
	'GPL-2+ with Proguard exception';

# Qt
like parse('t/exception/Qt/kcmaudiocd.h'), 'GPL-2+ with Qt-kernel exception';
like parse('t/exception/Qt/konsolekalendaradd.h'),
	'GPL-2+ with Qt-no-source exception';

like parse('t/exception/Qt/main.cpp'), 'GPL with Qt-GPL-Eclipse exception';

like parse('t/exception/Qt/qatomic_aarch64.h'),
	'(GPL-3 and/or LGPL-2.1) with Qt-LGPL-1.1 exception';
like parse('t/exception/Qt/qsslconfiguration.h'),
	'(GPL-3 and/or LGPL-2.1 or LGPL-3) with Qt-GPL-OpenSSL_AND_Qt-LGPL-1.1 exception';

$todo = todo 'not yet supported';
like parse('t/exception/Qt/main.cpp'),
	'(GPL-2 or GPL-3) with Qt-GPL-Eclipse exception';
like parse('t/exception/Qt/qatomic_aarch64.h'),
	'GPL-3 or LGPL-2.1 with Qt-LGPL-1.1 exception';
like parse('t/exception/Qt/qsslconfiguration.h'),
	'GPL-3 with Qt-GPL-OpenSSL exception or LGPL-2.1 with Qt-LGPL-1.1 exception';
$todo = undef;

# SDC
like parse('t/exception/SDC/sdc.py'),
	'(GPL-2+ and/or LGPL-2.1+) with SDC exception';

$todo = todo 'not yet supported';
like parse('t/exception/SDC/sdc.py'), 'GPL-2+ with SDC exception';
$todo = undef;

# Sollya
like parse('t/exception/Cecill/tv_implementpoly.reference'),
	'CECILL-C with Sollya-4.1 exception';

# Warzone
like parse('t/exception/Warzone/COPYING.README'),
	'GPL-2+ with Warzone exception';

# Xerces
like parse('t/exception/Xerces/generator.cxx'), 'GPL-2 with Xerces exception';

done_testing;
