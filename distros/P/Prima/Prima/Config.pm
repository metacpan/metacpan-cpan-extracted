# This file was automatically generated.
# Do not edit, you'll loose your changes anyway.
package Prima::Config;
use strict;
use warnings;
use vars qw(%Config %Config_inst);

%Config_inst = (
	incpaths              => [ '$(lib)/Prima/CORE','$(lib)/Prima/CORE/generic','C:/usr/local/perl/sb64.532.1/c/lib/pkgconfig/../../include/fribidi','C:/usr/local/perl/sb64.532.1/c/lib/pkgconfig/../../include/libpng16' ],
	gencls                => '$(bin)/prima-gencls.bat',
	tmlink                => '$(bin)/prima-tmlink.bat',
	libname               => '$(lib)/auto/Prima/libPrima.a',
	dlname                => '$(lib)/auto/Prima/Prima.xs.dll',
	ldpaths               => [],

	inc                   => '-I$(lib)/Prima/CORE -I$(lib)/Prima/CORE/generic -IC:/usr/local/perl/sb64.532.1/c/lib/pkgconfig/../../include/fribidi -IC:/usr/local/perl/sb64.532.1/c/lib/pkgconfig/../../include/libpng16',
	libs                  => '$(lib)/auto/Prima/libPrima.a',
);

%Config = (
	ifs                   => '\/',
	quote                 => '\"',
	platform              => 'win32',
	incpaths              => [ 'C:/home/Prima/Prima/include','C:/home/Prima/Prima/include/generic','C:/usr/local/perl/sb64.532.1/c/lib/pkgconfig/../../include/fribidi','C:/usr/local/perl/sb64.532.1/c/lib/pkgconfig/../../include/libpng16' ],
	gencls                => 'C:/home/Prima/Prima/blib/script/prima-gencls.bat',
	tmlink                => 'C:/home/Prima/Prima/blib/script/prima-tmlink.bat',
	scriptext             => '.bat',
	genclsoptions         => '--tml --h --inc',
	cobjflag              => '-o ',
	coutexecflag          => '-o ',
	clinkprefix           => '',
	clibpathflag          => '-L',
	cdefs                 => [],
	libext                => '.a',
	libprefix             => 'lib',
	libname               => 'C:/home/Prima/Prima/blib/arch/auto/Prima/libPrima.a',
	dlname                => 'C:/home/Prima/Prima/blib/arch/auto/Prima/Prima.xs.dll',
	ldoutflag             => '-o ',
	ldlibflag             => '-l',
	ldlibpathflag         => '-L',
	ldpaths               => [],
	ldlibs                => ['jpeg','gif','usp10','gdi32','mpr','winspool','comdlg32','msimg32','ole32','uuid','fribidi','png16','z','tiff','webp','webpdemux','webpmux','Xpm'],
	ldlibext              => '',
	inline                => 'inline',
	dl_load_flags         => 0,
	optimize              => '-s -O2 -Wall',
	openmp                => '-fopenmp',

	inc                   => '-IC:/home/Prima/Prima/include -IC:/home/Prima/Prima/include/generic -IC:/usr/local/perl/sb64.532.1/c/lib/pkgconfig/../../include/fribidi -IC:/usr/local/perl/sb64.532.1/c/lib/pkgconfig/../../include/libpng16',
	define                => '',
	libs                  => 'C:/home/Prima/Prima/blib/arch/auto/Prima/libPrima.a',
);

1;
