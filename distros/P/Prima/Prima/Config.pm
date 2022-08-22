# This file was automatically generated.
# Do not edit, you'll loose your changes anyway.
package Prima::Config;
use strict;
use warnings;
use vars qw(%Config %Config_inst);

%Config_inst = (
	incpaths              => [ '$(lib)/Prima/CORE','$(lib)/Prima/CORE/generic','/usr/include/fribidi','/usr/include/glib-2.0','/usr/lib/glib-2.0/include','/usr/include/freetype2','/usr/include/harfbuzz','/usr/include/gtk-3.0','/usr/include/pango-1.0','/usr/include/cairo','/usr/include/gdk-pixbuf-2.0','/usr/include/atk-1.0','/usr/include/libpng16' ],
	gencls                => '$(bin)/prima-gencls',
	tmlink                => '$(bin)/prima-tmlink',
	libname               => '$(lib)/auto/Prima/libPrima.dll.a',
	dlname                => '$(lib)/auto/Prima/Prima.dll',
	ldpaths               => ['/usr/lib/w32api'],

	inc                   => '-I$(lib)/Prima/CORE -I$(lib)/Prima/CORE/generic -I/usr/include/fribidi -I/usr/include/glib-2.0 -I/usr/lib/glib-2.0/include -I/usr/include/freetype2 -I/usr/include/harfbuzz -I/usr/include/gtk-3.0 -I/usr/include/pango-1.0 -I/usr/include/cairo -I/usr/include/gdk-pixbuf-2.0 -I/usr/include/atk-1.0 -I/usr/include/libpng16',
	libs                  => '-L$(lib)/auto/Prima -lPrima',
);

%Config = (
	ifs                   => '\/',
	quote                 => '\'',
	platform              => 'unix',
	incpaths              => [ '/cygdrive/c/home/Prima/Prima.cygwin/include','/cygdrive/c/home/Prima/Prima.cygwin/include/generic','/usr/include/fribidi','/usr/include/glib-2.0','/usr/lib/glib-2.0/include','/usr/include/freetype2','/usr/include/harfbuzz','/usr/include/gtk-3.0','/usr/include/pango-1.0','/usr/include/cairo','/usr/include/gdk-pixbuf-2.0','/usr/include/atk-1.0','/usr/include/libpng16' ],
	gencls                => '/cygdrive/c/home/Prima/Prima.cygwin/blib/script/prima-gencls',
	tmlink                => '/cygdrive/c/home/Prima/Prima.cygwin/blib/script/prima-tmlink',
	scriptext             => '',
	genclsoptions         => '--tml --h --inc',
	cobjflag              => '-o ',
	coutexecflag          => '-o ',
	clinkprefix           => '',
	clibpathflag          => '-L',
	cdefs                 => [],
	libext                => '.dll.a',
	libprefix             => 'lib',
	libname               => '/cygdrive/c/home/Prima/Prima.cygwin/blib/arch/auto/Prima/libPrima.dll.a',
	dlname                => '/cygdrive/c/home/Prima/Prima.cygwin/blib/arch/auto/Prima/Prima.dll',
	ldoutflag             => '-o ',
	ldlibflag             => '-l',
	ldlibpathflag         => '-L',
	ldpaths               => ['/usr/lib/w32api'],
	ldlibs                => ['jpeg','heif','gif','fribidi','glib-2.0','intl','thai','X11','Xext','Xft','freetype','fontconfig','Xrender','harfbuzz','gtk-3','gdk-3','pango-1.0','gobject-2.0','pangocairo-1.0','cairo','gdk_pixbuf-2.0','cairo-gobject','atk-1.0','gio-2.0','Xrandr','Xcomposite','Xcursor','heif','png16','z','tiff','webp','webpdemux','webpmux','Xpm'],
	ldlibext              => '',
	inline                => 'inline',
	dl_load_flags         => 0,
	optimize              => '-O3 -Wall',
	openmp                => '-fopenmp',

	inc                   => '-I/cygdrive/c/home/Prima/Prima.cygwin/include -I/cygdrive/c/home/Prima/Prima.cygwin/include/generic -I/usr/include/fribidi -I/usr/include/glib-2.0 -I/usr/lib/glib-2.0/include -I/usr/include/freetype2 -I/usr/include/harfbuzz -I/usr/include/gtk-3.0 -I/usr/include/pango-1.0 -I/usr/include/cairo -I/usr/include/gdk-pixbuf-2.0 -I/usr/include/atk-1.0 -I/usr/include/libpng16',
	define                => '',
	libs                  => '-L/cygdrive/c/home/Prima/Prima.cygwin/blib/arch/auto/Prima -lPrima',
);

1;
