package Pgreet::ExecMason;
require Exporter;
#
# File: ExecMason.pm

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
#           Perl Module: Pgreet::ExecMason
#
# This is the Penguin Greetings (pgreet) module is a quick wrapper
# for Mason modules so that the Perl autouse pragma can be used
# to load either Embperl or Mason on the fly and spare users of
# only one Embedded Perl solution the overhead of the other.
######################################################################
# $Id: ExecMason.pm,v 1.3 2005/05/31 16:44:39 elagache Exp $

$VERSION = "1.0.0"; # update after release

use HTML::Mason ();

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(ExecMason ExecObjMason);

sub ExecMason {
#
# A Wrapper for a wrapper.  This function simply adds the
# argument to HTML::Mason::Interp->new that disables
# autohandlers and then calls ExecObjMason
#
  my $Interp_obj_args = shift;
  my $comp_path = shift;
  my $Transfer = shift;

  # This causes HTML::Mason to not search for autohandlers
  $Interp_obj_args->{autohandler_name} = "";

  ExecObjMason($Interp_obj_args, $comp_path, $Transfer);
}

sub ExecObjMason {
#
# Wrapper function to execute a Penguin Greetings
# template in HTML::Mason
#
  my $Interp_obj_args = shift;
  my $comp_path = shift;
  my $Transfer = shift;

  my $Mason_obj = HTML::Mason::Interp->new(%{$Interp_obj_args});

  $Mason_obj->exec($comp_path, $Transfer);
}

=head1 NAME

Pgreet::ExecEmbperl - Penguin Greetings wrapper for calls to Embperl

=head1 SYNOPSIS

  # Call HTML::Mason without use of autohanders (mainly for text files.)
  ExecMason({comp_root  => $comp_root,
             data_dir   => $data_dir,
             out_method => \$result_str,
            },
            $comp_path,
            $Transfer
           );

  # Call HTML::Mason to create an HTML page with Mason object-oriented
  # features
  ExecObjMason({comp_root  => $comp_root,
                data_dir   => $data_dir,
                 out_method => \$result_str,
                },
               $comp_path,
               $Transfer
              );



=head1 DESCRIPTION

The module C<Pgreet::ExecMason> exists to wrap calls to the Embperl
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

=head1 USAGE

The two functions in this package are identical except that one sets
the autohandler name to an empty string in order to disable
inheritance.  There are 3 arguments.  The first is a hash-ref
containing the argument to C<HTML::Mason::Interp::new>.  The remaining
two arguments (component path and arguments list) are passed to
C<HTML::Mason::Interp::exec>.

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
L<Pgreet::ExecEmbperl>, L<CGI::Carp>


1;
