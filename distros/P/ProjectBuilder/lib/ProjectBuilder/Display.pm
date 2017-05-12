#!/usr/bin/perl -w
#
# Display subroutines brought by the the Project-Builder project
# which can be easily used by whatever perl project
#
# Copyright B. Cornec 2007-2016
# Provided under the GPL v2
#
# $Id$
#

package ProjectBuilder::Display;

use strict;
use lib qw (lib);
use Data::Dumper;
use Pod::Usage;
use English;
use POSIX qw(locale_h);
use ProjectBuilder::Base;
use ProjectBuilder::Version;

# Inherit from the "Exporter" module which handles exporting functions.
 
use vars qw($VERSION $REVISION @ISA @EXPORT);
use Exporter;
 
# Export, by default, all the functions into the namespace of
# any code which uses this module.
 
our $pbdisplaytype = "text";
						# default display mode for messages
our $pblocale = "C";

our @ISA = qw(Exporter);
our @EXPORT = qw(pb_display pb_display_init $pbdisplaytype $pblocale);
($VERSION,$REVISION) = pb_version_init();

=pod

=head1 NAME

ProjectBuilder::Display, part of the project-builder.org - module dealing with display functions suitable for perl project development

=head1 DESCRIPTION

This modules provides display functions suitable for perl project development 

=head1 SYNOPSIS

  use ProjectBuilder::Display;

  #
  # Manages prints of the program
  #
  pb_display_init("text","fr_FR:UTF-8");
  pb_display("Message to print\n");

=head1 USAGE

=over 4

=item B<pb_display_init>

This function initializes the environment used by the pb_display function.

The first parameter is the type of display which will be used. Could be "text", "web", "newt",...
The second parameter is the loacle to be used.

The call to B<pb_display_init> is typically done after getting a parameter on the CLI indicating the locale used or the type of interface to report messages to.

=cut

sub pb_display_init {

$pbdisplaytype = shift || "text";
$pblocale = shift || "C";

setlocale(LC_ALL, $pblocale);
pb_log(1,"Using $pbdisplaytype interface with $pblocale locale\n");

if ($pbdisplaytype =~ /text/) {
} elsif ($pbdisplaytype = /newt/) {
} else {
	die "display system $pbdisplaytype unsupported";
}
}

=item B<pb_display>

This function prints the messages passed as parameter using the configuration set up with the B<pb_display_init> function.

Here is a usage example:

  pb_display_init("text","fr_FR.UTF-8");
  pb_display("Hello World\n");

  will print:
  
  Bonjour Monde

=cut 

sub pb_display {

my $msg = shift;

if ($pbdisplaytype =~ /text/) {
	print STDOUT gettext($msg);
	}
}

1;
