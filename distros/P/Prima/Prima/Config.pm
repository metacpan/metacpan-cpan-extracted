# This file was automatically generated.
# Do not edit, you'll loose your changes anyway.
package Prima::Config;
use strict;
use warnings;
use vars qw(%Config %Config_inst);

%Config_inst = (
	incpaths              => [ '$(lib)/Prima/CORE','$(lib)/Prima/CORE/generic','/usr/include/fribidi','/usr/include/uuid','/usr/include/freetype2','/usr/include/libpng16','/usr/include/harfbuzz','/usr/include/glib-2.0','/usr/lib/x86_64-linux-gnu/glib-2.0/include','/usr/include/gtk-3.0','/usr/include/at-spi2-atk/2.0','/usr/include/at-spi-2.0','/usr/include/dbus-1.0','/usr/lib/x86_64-linux-gnu/dbus-1.0/include','/usr/include/gtk-3.0','/usr/include/gio-unix-2.0','/usr/include/cairo','/usr/include/pango-1.0','/usr/include/pango-1.0','/usr/include/atk-1.0','/usr/include/cairo','/usr/include/pixman-1','/usr/include/gdk-pixbuf-2.0','/usr/include/x86_64-linux-gnu','/usr/include/libmount','/usr/include/blkid' ],
	gencls                => '$(bin)/prima-gencls',
	tmlink                => '$(bin)/prima-tmlink',
	libname               => '$(lib)/auto/Prima/Prima.a',
	dlname                => '$(lib)/auto/Prima/Prima.so',
	ldpaths               => [],

	inc                   => '-I$(lib)/Prima/CORE -I$(lib)/Prima/CORE/generic -I/usr/include/fribidi -I/usr/include/uuid -I/usr/include/freetype2 -I/usr/include/libpng16 -I/usr/include/harfbuzz -I/usr/include/glib-2.0 -I/usr/lib/x86_64-linux-gnu/glib-2.0/include -I/usr/include/gtk-3.0 -I/usr/include/at-spi2-atk/2.0 -I/usr/include/at-spi-2.0 -I/usr/include/dbus-1.0 -I/usr/lib/x86_64-linux-gnu/dbus-1.0/include -I/usr/include/gtk-3.0 -I/usr/include/gio-unix-2.0 -I/usr/include/cairo -I/usr/include/pango-1.0 -I/usr/include/pango-1.0 -I/usr/include/atk-1.0 -I/usr/include/cairo -I/usr/include/pixman-1 -I/usr/include/gdk-pixbuf-2.0 -I/usr/include/x86_64-linux-gnu -I/usr/include/libmount -I/usr/include/blkid',
	libs                  => '',
);

%Config = (
	ifs                   => '\/',
	quote                 => '\'',
	platform              => 'unix',
	incpaths              => [ '/home/dk/src/Prima/include','/home/dk/src/Prima/include/generic','/usr/include/fribidi','/usr/include/uuid','/usr/include/freetype2','/usr/include/libpng16','/usr/include/harfbuzz','/usr/include/glib-2.0','/usr/lib/x86_64-linux-gnu/glib-2.0/include','/usr/include/gtk-3.0','/usr/include/at-spi2-atk/2.0','/usr/include/at-spi-2.0','/usr/include/dbus-1.0','/usr/lib/x86_64-linux-gnu/dbus-1.0/include','/usr/include/gtk-3.0','/usr/include/gio-unix-2.0','/usr/include/cairo','/usr/include/pango-1.0','/usr/include/pango-1.0','/usr/include/atk-1.0','/usr/include/cairo','/usr/include/pixman-1','/usr/include/gdk-pixbuf-2.0','/usr/include/x86_64-linux-gnu','/usr/include/libmount','/usr/include/blkid' ],
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
	ldlibs                => ['jpeg','heif','gif','fribidi','thai','X11','Xext','Xft','freetype','fontconfig','Xrender','harfbuzz','gtk-3','gdk-3','pangocairo-1.0','pango-1.0','atk-1.0','cairo-gobject','cairo','gdk_pixbuf-2.0','gio-2.0','gobject-2.0','glib-2.0','Xrandr','Xcomposite','Xcursor','heif','png16','z','tiff','webp','webpdemux','webpmux','Xpm'],
	ldlibext              => '',
	inline                => 'inline',
	dl_load_flags         => 1,
	optimize              => '-O2 -g -Wall',
	openmp                => '-fopenmp',

	inc                   => '-I/home/dk/src/Prima/include -I/home/dk/src/Prima/include/generic -I/usr/include/fribidi -I/usr/include/uuid -I/usr/include/freetype2 -I/usr/include/libpng16 -I/usr/include/harfbuzz -I/usr/include/glib-2.0 -I/usr/lib/x86_64-linux-gnu/glib-2.0/include -I/usr/include/gtk-3.0 -I/usr/include/at-spi2-atk/2.0 -I/usr/include/at-spi-2.0 -I/usr/include/dbus-1.0 -I/usr/lib/x86_64-linux-gnu/dbus-1.0/include -I/usr/include/gtk-3.0 -I/usr/include/gio-unix-2.0 -I/usr/include/cairo -I/usr/include/pango-1.0 -I/usr/include/pango-1.0 -I/usr/include/atk-1.0 -I/usr/include/cairo -I/usr/include/pixman-1 -I/usr/include/gdk-pixbuf-2.0 -I/usr/include/x86_64-linux-gnu -I/usr/include/libmount -I/usr/include/blkid',
	define                => '',
	libs                  => '',
);

1;
