package Pgreet::ExecEmbperl;
require Exporter;
#
# File: ExecEmbperl.pm
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
#           Perl Module: Pgreet::ExecEmbperl
#
# This is the Penguin Greetings (pgreet) module is a quick wrapper
# for Embperl modules so that the Perl autouse pragma can be used
# to load either Embperl or Mason on the fly and spare users of
# only one Embedded Perl solution the overhead of the other.
######################################################################
# $Id: ExecEmbperl.pm,v 1.3 2005/05/31 16:44:39 elagache Exp $

$VERSION = "1.0.0"; # update after release

use Embperl;
use Embperl::Object;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(ExecEmbperl ExecObjEmbperl);

##    . . .    - - -     . . .    - - -    . . .    - - -     . . .

sub ExecEmbperl {
#
# Wrapper function for Embperl::Execute
#
  my $Embperl_args = shift;

  Embperl::Execute ($Embperl_args);
}

sub ExecObjEmbperl {
#
# Wrapper function for Embperl::Object::Execute
#
  my $Embperl_args = shift;

  Embperl::Object::Execute($Embperl_args);
}

=head1 NAME

Pgreet::ExecEmbperl - Penguin Greetings wrapper for calls to Embperl

=head1 SYNOPSIS

  # Call Embperl without object-oriented features
  ExecEmbperl({inputfile => "/home/httpd/htdocs/pgreet/default.tpl.html",
               output => $result_string,
               param => [$Transfer]
              }
             );

  # Call Embperl with object-oriented features
  ExecObjEmbperl({inputfile => "/home/httpd/htdocs/pgreet/default.tpl.html",
                  output => $result_string,
                  param => [$Transfer]
                  object_addpath => "/home/httpd/htdocs/pgreet"
                  object_base => "pgreet_template.epl"
                  appname => "PgDefault"
                 }
                );

=head1 DESCRIPTION

The module C<Pgreet::ExecEmbperl> exists to wrap calls to the Embperl
enviroment so that the Perl C<autouse> pragma can be used to avoid
loading Embperl until runtime.  This is one half of the solution to
avoid requiring Penguin Greetings users to load both Embperl and
HTML::Mason when they might be using only one of the two environments.
The only reason to use this module would be to replicate this use of
the Perl pragma in some similar situation.  Example calls are provided
above and/or examine the use of this module in C<Pgreet::CGIUtils>.

There is only a functional interface to these wrappers in order to
support the manner in which the C<autouse> pragma swaps in a module's
procedures at runtime.

=head1 COPYRIGHT

Copyright (c) 2005 Edouard Lagache

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

L<Pgreet>, L<Pgreet::Config>, L<Pgreet::Error>, L<Pgreet::CGIUtils>,
L<Pgreet::ExecMason>, L<CGI::Carp>


1;
