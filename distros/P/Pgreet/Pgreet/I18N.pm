package Pgreet::I18N;
#
# File: I18N.pm
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
#           Perl Module: Pgreet::I18N
# This file is part of the 'Locale::Maketext' Internationalization
# support for the Penguin Greetings Secondary ecard sites.  It is
# shamelessly adapted from the 'File::Findgrep' example.  This file
# sets up the initialization of the 'Locale::Maketext' system and
# defaults the project language to English
######################################################################
# $Id: I18N.pm,v 1.4 2005/05/31 16:44:39 elagache Exp $

$VERSION = "1.0.0"; # update after release

use Locale::Maketext 1.01;
use base ('Locale::Maketext');

# Development is in en-US

%Lexicon = (
  '_AUTO' => 1,
  # That means that lookup failures can't happen -- if we get as far
  #  as looking for something in this lexicon, and we don't find it,
  #  then automagically set $Lexicon{$key} = $key, before possibly
  #  compiling it.

  # Since all text in Penguin Greetings uses the English text as the
  # lexicon key. There are no special entries in this file.  Only other
  # languages will have entries in this hash.
);
# End of lexicon.

=head1 NAME

Pgreet::I18N  -  Locale::Maketext localization for Penguin Greetings

=head1 DESCRIPTION

This module is part of the L<Locale::Maketext> localization of
secondary ecard sites of Penguin Greetings.  See the
L<Locale::Maketext> documentation for more information on using this
scheme for handling Internationalization/Localization.

=head1 USING Pgreet::I18N PENGUIN GREETINGS TEMPLATES

Because this module contains the translation strings used within the
Penguin Greetings secondary ecard sites, it could not be used for new
applications that require new strings without being overridden or
modified.  The example below is intended simply to be illustrative as
to how the C<Locale::Maketext> module is used within Penguin Greetings
secondary ecard sites.

In order to use these translation services first the module must be
brought into the template using the C<use> command:

  use Pgreet::I18N;

Next in lieu of using a new constructor, one should get a language
handle.  The C<get_handle> method requires a language string to be
used.  This can be gotten from Penguin Greetings by using the
C<lang_code> value from the C<$trans> hash passed to every template.

  $LN = Pgreet::I18N->get_handle($trans->{'lang_code'});

Once one has a language handle localization is done by calls to the
C<maketext> method.  An example below is shown first in Embperl and
then in Mason:

  [# Using $LN->maketext in Embperl #]
  [+ $LN->maketext("Received a Savoring Seattle note card?") +]

  <%doc> Using $LN->maketext in Mason </%doc>
  <% $LN->maketext("Received a Savoring Seattle note card?") %>

Please see the C<Locale::Maketext> documentation for general
information on how to use this technique for localizing a Perl
application.

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

1;  # End of module.

