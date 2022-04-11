# This file was automatically generated.
# Do not edit, you'll loose your changes anyway.
package Prima::Config;
use strict;
use warnings;
use vars qw(%Config %Config_inst);

%Config_inst = (
	incpaths              => [ '$(lib)/Prima/CORE','$(lib)/Prima/CORE/generic','/usr/local/include/fribidi','/usr/local/include','/usr/local/include/freetype2','/usr/local/include/harfbuzz','/usr/local/include/glib-2.0','/usr/local/lib/glib-2.0/include','/usr/local/include/gtk-2.0','/usr/local/include/pango-1.0','/usr/local/include/cairo','/usr/local/include/pixman-1','/usr/local/include/libdrm','/usr/local/include/libpng16','/usr/local/include/gdk-pixbuf-2.0','/usr/local/include/atk-1.0' ],
	gencls                => '$(bin)/prima-gencls',
	tmlink                => '$(bin)/prima-tmlink',
	libname               => '$(lib)/auto/Prima/Prima.a',
	dlname                => '$(lib)/auto/Prima/Prima.so',
	ldpaths               => ['/usr/local/lib'],

	inc                   => '-I$(lib)/Prima/CORE -I$(lib)/Prima/CORE/generic -I/usr/local/include/fribidi -I/usr/local/include -I/usr/local/include/freetype2 -I/usr/local/include/harfbuzz -I/usr/local/include/glib-2.0 -I/usr/local/lib/glib-2.0/include -I/usr/local/include/gtk-2.0 -I/usr/local/include/pango-1.0 -I/usr/local/include/cairo -I/usr/local/include/pixman-1 -I/usr/local/include/libdrm -I/usr/local/include/libpng16 -I/usr/local/include/gdk-pixbuf-2.0 -I/usr/local/include/atk-1.0',
	libs                  => '',
);

%Config = (
	ifs                   => '\/',
	quote                 => '\'',
	platform              => 'unix',
	incpaths              => [ '/usr/home/dk/src/Prima/include','/usr/home/dk/src/Prima/include/generic','/usr/local/include/fribidi','/usr/local/include','/usr/local/include/freetype2','/usr/local/include/harfbuzz','/usr/local/include/glib-2.0','/usr/local/lib/glib-2.0/include','/usr/local/include/gtk-2.0','/usr/local/include/pango-1.0','/usr/local/include/cairo','/usr/local/include/pixman-1','/usr/local/include/libdrm','/usr/local/include/libpng16','/usr/local/include/gdk-pixbuf-2.0','/usr/local/include/atk-1.0' ],
	gencls                => '/usr/home/dk/src/Prima/blib/script/prima-gencls',
	tmlink                => '/usr/home/dk/src/Prima/blib/script/prima-tmlink',
	scriptext             => '',
	genclsoptions         => '--tml --h --inc',
	cobjflag              => '-o ',
	coutexecflag          => '-o ',
	clinkprefix           => '',
	clibpathflag          => '-L',
	cdefs                 => [],
	libext                => '.a',
	libprefix             => '',
	libname               => '/usr/home/dk/src/Prima/blib/arch/auto/Prima/Prima.a',
	dlname                => '/usr/home/dk/src/Prima/blib/arch/auto/Prima/Prima.so',
	ldoutflag             => '-o ',
	ldlibflag             => '-l',
	ldlibpathflag         => '-L',
	ldpaths               => ['/usr/local/lib'],
	ldlibs                => ['jpeg','gif','fribidi','X11','Xext','Xft','freetype','fontconfig','Xrender','harfbuzz','iconv','gtk-x11-2.0','gdk-x11-2.0','pangocairo-1.0','atk-1.0','cairo','pthread','gdk_pixbuf-2.0','gio-2.0','pangoft2-1.0','pango-1.0','gobject-2.0','glib-2.0','intl','Xrandr','Xcomposite','Xcursor','png16','tiff','webp','webpdemux','webpmux','Xpm'],
	ldlibext              => '',
	inline                => 'inline',
	dl_load_flags         => 1,
	optimize              => '-O2 -pipe -fstack-protector -fno-strict-aliasing  -Wall',
	openmp                => '',

	inc                   => '-I/usr/home/dk/src/Prima/include -I/usr/home/dk/src/Prima/include/generic -I/usr/local/include/fribidi -I/usr/local/include -I/usr/local/include/freetype2 -I/usr/local/include/harfbuzz -I/usr/local/include/glib-2.0 -I/usr/local/lib/glib-2.0/include -I/usr/local/include/gtk-2.0 -I/usr/local/include/pango-1.0 -I/usr/local/include/cairo -I/usr/local/include/pixman-1 -I/usr/local/include/libdrm -I/usr/local/include/libpng16 -I/usr/local/include/gdk-pixbuf-2.0 -I/usr/local/include/atk-1.0',
	define                => '',
	libs                  => '',
);

1;
