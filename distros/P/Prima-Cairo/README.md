NAME
====

Prima::Cairo - Prima extension for Cairo drawing

DESCRIPTION
===========

The module allows for programming Cairo library together with Prima
widgets.

SYNOPSIS
========

    use strict;
    use warnings;
    use Prima qw(Application Cairo);
    
    my $w = Prima::MainWindow->new( onPaint => sub {
        my ( $self, $canvas ) = @_;
        $canvas->clear;
    
        my $cr = $canvas->cairo_context;
    
        $cr->rectangle (10, 10, 40, 40);
        $cr->set_source_rgb (0, 0, 0);
        $cr->fill;
    
        $cr->rectangle (50, 50, 40, 40);
        $cr->set_source_rgb (1, 1, 1);
        $cr->fill;
    
        $cr->show_page;
    });
    run Prima;


Installation on Strawberry win32
--------------------------------

Before installing the module, you need to install Cairo perl wrapper.
That requires libcairo binaries, includes, and pkg-config.

In case you don't have cairo binaries and include files, grab them here:

http://prima.eu.org/Cairo/cairo-win.zip

unzip and run <code>make install</code>.

Strawberry 5.20 is shipped with a broken pkg-config (
https://rt.cpan.org/Ticket/Display.html?id=96315,
https://rt.cpan.org/Ticket/Display.html?id=96317 ), if you need a
working one grab it here:

http://karasik.eu.org/misc/cairo/pkgconfig.zip

This setup is needed both for Cairo and Prima-Cairo.

Debian/Ubuntu
-------------

apt-get install libextutils-pkgconfig-perl libcairo-dev libcairo-perl

AUTHOR
=====

Dmitry Karasik, <dmitry@karasik.eu.org>.

LICENSE
=======

This software is distributed under the BSD License.

