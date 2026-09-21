Tcl::Tk - Extension module for Perl providing access to Tcl/Tk graphics library

DESCRIPTION
===========

The Tcl::Tk module acts as a bridge between Perl and the Tcl/Tk installation.
It creates a Tcl/Tk interpreter object and provides an interface that closely
follows the classic Perl/Tk syntax, giving you complete access to the core Tk
package and its extensions.

Starting with version 1.52, Tcl::Tk includes native, out-of-the-box support for
modern themed widgets (Ttk). You can create highly polished user interfaces
that seamlessly adopt the native look and feel of the host operating system
(Windows, macOS, or Linux/GTK) without any external toolkits.

In addition, it allows you to leverage the full variety of other installed
Tcl/Tk extensions (such as Tix, BLT, BWidgets, Treectrl, etc.) directly from Perl.


WHAT'S NEW IN VERSION 1.52
==========================

* Added native CamelCase mappings for the entire standard Ttk themed widget set.
* Modern widgets like TtkNoteBook, TtkTreeview, and TtkButton can now be used
  directly without loading legacy 'tile' packages.
* Improved test coverage for modern GUI environments.
* Refined configuration warnings for standard toolkits (like tklib/tooltip).


NATIVE THEMED WIDGETS (TTK)
===========================

All themed widgets are accessible using the standard Perl/Tk method syntax with
a 'Ttk' prefix.

The following modern widgets are fully supported:
* Buttons & Controls:  TtkButton, TtkCheckbutton, TtkRadiobutton
* Labels & Entries:    TtkLabel, TtkEntry, TtkFrame, TtkLabelframe
* Navigation & Layout: TtkNoteBook, TtkPanedwindow, TtkScrollbar, TtkSeparator
* Advanced Inputs:     TtkCombobox, TtkSpinbox, TtkTreeview, TtkScale
* Specialized UI:      TtkProgressbar, TtkSizegrip

Quick Example:
--------------
    use Tcl::Tk;
    
    my $mw = Tcl::Tk::MainWindow->new();
    
    # Create a modern native notebook frame
    my $nb = $mw->TtkNotebook()->pack(-fill => 'both', -expand => 1);
    
    # Add a tab with a native button
    my $tab = $nb->TtkFrame();
    $nb->add($tab, -text => "Main Tab");
    
    my $btn = $tab->TtkButton(
        -text    => "Click Me",
        -command => sub { print "Hello from Ttk!\n" }
    )->pack(-pady => 20);
    
    Tcl::Tk::MainLoop();


INSTALLATION
============

To install this module, run the following standard commands:

    perl Makefile.PL
    make
    make test
    make install

Note: During 'perl Makefile.PL', the script will automatically detect your
system's Tcl/Tk installation. Having 'tklib' installed on your system is highly
recommended to enable modern 'tooltip' support.


DEPENDENCIES
============

This module requires:
* Tcl (Perl core wrapper)
* A working Tcl/Tk installation (v8.5 or v8.6 recommended for full Ttk support)


COPYRIGHT AND LICENSE
=====================

Copyright (c) 1999-2008 Malcolm Beattie, Vadim Konovalov, and Gisle Aas.
Copyright (c) 2026 Vadim Konovalov. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

