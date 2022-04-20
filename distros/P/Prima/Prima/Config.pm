# This file was automatically generated.
# Do not edit, you'll loose your changes anyway.
package Prima::Config;
use strict;
use warnings;
use vars qw(%Config %Config_inst);

%Config_inst = (
	incpaths              => [ '$(lib)/Prima/CORE','$(lib)/Prima/CORE/generic','/usr/include/fribidi','/usr/local/include','/usr/include/freetype2','/usr/include/libpng16','/usr/include/freetype2','/usr/include/libpng16','/usr/include/harfbuzz','/usr/include/glib-2.0','/usr/lib/x86_64-linux-gnu/glib-2.0/include','/usr/include/gtk-2.0','/usr/lib/x86_64-linux-gnu/gtk-2.0/include','/usr/include/gio-unix-2.0/','/usr/include/cairo','/usr/include/pango-1.0','/usr/include/atk-1.0','/usr/include/cairo','/usr/include/pixman-1','/usr/include/gdk-pixbuf-2.0','/usr/include/pango-1.0','/usr/include/pango-1.0','/usr/include/x86_64-linux-gnu' ],
	gencls                => '$(bin)/prima-gencls',
	tmlink                => '$(bin)/prima-tmlink',
	libname               => '$(lib)/auto/Prima/Prima.a',
	dlname                => '$(lib)/auto/Prima/Prima.so',
	ldpaths               => [],

	inc                   => '-I$(lib)/Prima/CORE -I$(lib)/Prima/CORE/generic -I/usr/include/fribidi -I/usr/local/include -I/usr/include/freetype2 -I/usr/include/libpng16 -I/usr/include/freetype2 -I/usr/include/libpng16 -I/usr/include/harfbuzz -I/usr/include/glib-2.0 -I/usr/lib/x86_64-linux-gnu/glib-2.0/include -I/usr/include/gtk-2.0 -I/usr/lib/x86_64-linux-gnu/gtk-2.0/include -I/usr/include/gio-unix-2.0/ -I/usr/include/cairo -I/usr/include/pango-1.0 -I/usr/include/atk-1.0 -I/usr/include/cairo -I/usr/include/pixman-1 -I/usr/include/gdk-pixbuf-2.0 -I/usr/include/pango-1.0 -I/usr/include/pango-1.0 -I/usr/include/x86_64-linux-gnu',
	libs                  => '',
);

%Config = (
	ifs                   => '\/',
	quote                 => '\'',
	platform              => 'unix',
	incpaths              => [ '/home/dk/src/Prima/include','/home/dk/src/Prima/include/generic','/usr/include/fribidi','/usr/local/include','/usr/include/freetype2','/usr/include/libpng16','/usr/include/freetype2','/usr/include/libpng16','/usr/include/harfbuzz','/usr/include/glib-2.0','/usr/lib/x86_64-linux-gnu/glib-2.0/include','/usr/include/gtk-2.0','/usr/lib/x86_64-linux-gnu/gtk-2.0/include','/usr/include/gio-unix-2.0/','/usr/include/cairo','/usr/include/pango-1.0','/usr/include/atk-1.0','/usr/include/cairo','/usr/include/pixman-1','/usr/include/gdk-pixbuf-2.0','/usr/include/pango-1.0','/usr/include/pango-1.0','/usr/include/x86_64-linux-gnu' ],
	gencls                => '/home/dk/src/Prima/blib/script/prima-gencls',
	tmlink                => '/home/dk/src/Prima/blib/script/prima-tmlink',
	scriptext             => '',
	genclsoptions         => '--tml --h --inc',
	cobjflag              => '-o ',
	coutexecflag          => '-o ',
	clinkprefix           => '',
	clibpathflag          => '-L',
	cdefs                 => [],
	libext                => '.a',
	libprefix             => '',
	libname               => '/home/dk/src/Prima/blib/arch/auto/Prima/Prima.a',
	dlname                => '/home/dk/src/Prima/blib/arch/auto/Prima/Prima.so',
	ldoutflag             => '-o ',
	ldlibflag             => '-l',
	ldlibpathflag         => '-L',
	ldpaths               => [],
	ldlibs                => ['jpeg','gif','fribidi','thai','X11','Xext','Xft','freetype','fontconfig','Xrender','harfbuzz','gtk-x11-2.0','gdk-x11-2.0','pangocairo-1.0','atk-1.0','cairo','gdk_pixbuf-2.0','gio-2.0','pangoft2-1.0','pango-1.0','gobject-2.0','glib-2.0','Xrandr','Xcomposite','Xcursor','png16','z','tiff','webp','webpdemux','webpmux','Xpm'],
	ldlibext              => '',
	inline                => 'inline',
	dl_load_flags         => 1,
	optimize              => '-O2 -g -Wall',
	openmp                => '-fopenmp',

	inc                   => '-I/home/dk/src/Prima/include -I/home/dk/src/Prima/include/generic -I/usr/include/fribidi -I/usr/local/include -I/usr/include/freetype2 -I/usr/include/libpng16 -I/usr/include/freetype2 -I/usr/include/libpng16 -I/usr/include/harfbuzz -I/usr/include/glib-2.0 -I/usr/lib/x86_64-linux-gnu/glib-2.0/include -I/usr/include/gtk-2.0 -I/usr/lib/x86_64-linux-gnu/gtk-2.0/include -I/usr/include/gio-unix-2.0/ -I/usr/include/cairo -I/usr/include/pango-1.0 -I/usr/include/atk-1.0 -I/usr/include/cairo -I/usr/include/pixman-1 -I/usr/include/gdk-pixbuf-2.0 -I/usr/include/pango-1.0 -I/usr/include/pango-1.0 -I/usr/include/x86_64-linux-gnu',
	define                => '',
	libs                  => '',
);

1;
