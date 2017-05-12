package Pgreet::I18N::i_default;
#
# File: i_default.pm
######################################################################
#
#                ** PENGUIN GREETINGS (pgreet) **
#
# A Perl CGI-based web card application for LINUX and probably any
# other UNIX system supporting standard Perl extensions.
#
#   Edouard Lagache, elagache@canebas.org, Copyright (C)  2003-2005
#
# Penguin Greetings (pgreet) consists of a Perl CGI script that
# handles interactions with users wishing to create and/or
# retrieve cards and a system daemon that works behind the scenes
# to store the data and email the cards.
#
# ** This program has been released under GNU GENERAL PUBLIC
# ** LICENSE.  For information, see the COPYING file included
# ** with this code.
#
# For more information and for the latest updates go to the
# Penguin Greetings official web site at:
#
#     http://pgreet.sourceforge.net/
#
# and the SourceForge project page at:
#
#     http://sourceforge.net/projects/pgreet/
#
# ----------
#
#           Perl Module: Pgreet::I18N::i_default.pm
# This file is part of the 'Locale::Maketext' Internationalization
# support for the Penguin Greetings Secondary ecard sites.  It is
# shamelessly adapted from the 'File::Findgrep' example.  This file
# sets up the initialization of the 'Locale::Maketext' system and
# defaults the project language to English
######################################################################
# $Id: i_default.pm,v 1.3 2005/05/31 16:44:39 elagache Exp $

$VERSION = "1.0.0"; # update after release

# Default directly to en_us
use base qw(Pgreet::I18N);


=head1 NAME

Pgreet::I18N::i_default  -  Locale::Maketext localization for Penguin Greetings

=head1 DESCRIPTION

This module is part of the L<Locale::Maketext> localization of
secondary ecard sites of Penguin Greetings.  See the
L<Locale::Maketext> documentation for more information on using this
scheme for handling Internationalization/Localization.

=head1 COPYRIGHT

Copyright (c) 2003-2005 Edouard Lagache

This software is released under the GNU General Public License, Version 2.
For more information, see the COPYING file included with this software or
visit: http://www.gnu.org/copyleft/gpl.html

=head1 BUGS

No known bugs at this time.

=head1 AUTHOR

Edouard Lagache <pgreetdev@canebas.org>

=head1 VERSION

1.0.0

=head1 SEE ALSO

L<Locale::Maketext>, L<File::Findgrep>

=cut

1;
