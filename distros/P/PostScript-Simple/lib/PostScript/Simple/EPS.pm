#! /usr/bin/perl

package PostScript::Simple::EPS;

use strict;
use Exporter;
use Carp;
use PostScript::Simple;

use vars qw($VERSION @ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw();
$VERSION = "0.02";


#-------------------------------------------------------------------------------

=head1 NAME

PostScript::Simple::EPS - EPS support for PostScript::Simple

=head1 SYNOPSIS

    use PostScript::Simple;
    
    # create a new PostScript object
    $p = new PostScript::Simple(papersize => "A4",
                                colour => 1,
                                units => "in");
    
    # create a new page
    $p->newpage;
    
    # add an eps file
    $p->add_eps({xsize => 3}, "test.eps", 1,1);
    $p->add_eps({yscale => 1.1, xscale => 1.8}, "test.eps", 4,8);

    # create an eps object
    $e = new PostScript::Simple::EPS(file => "test.eps");
    $e->rotate(90);
    $e->xscale(0.5);
    $p->add_eps($e, 3, 3); # add eps object to postscript object
    $e->xscale(2);
    $p->add_eps($e, 2, 5); # add eps object to postscript object again
    
    # write the output to a file
    $p->output("file.ps");


=head1 DESCRIPTION

PostScript::Simple::EPS allows you to add EPS files into PostScript::Simple
objects.  Included EPS files can be scaled and rotated, and placed anywhere
inside a PostScript::Simple page.

Remember when using translate/scale/rotate that you will normally need to do
the operations in the reverse order to that which you expect.

=head1 PREREQUISITES

This module requires C<PostScript::Simple>, C<strict>, C<Carp> and C<Exporter>.

=head2 EXPORT

None.

=cut

=head1 CONSTRUCTOR

=over 4

=item C<new(options)>

Create a new PostScript::Simple::EPS object. The options
that can be set are:

=over 4

=item file

EPS file to be included. This or C<source> must exist when the C<new> method is
called.

=item source

PostScript code for the EPS document. Either this or C<file> must be set when
C<new> is called.

=item clip

Set to 0 to disable clipping to the EPS bounding box. Default is to clip.

=back

Example:

    $ps = new PostScript::Simple(landscape => 1,
                                 eps => 0,
                                 xsize => 4,
                                 ysize => 3,
                                 units => "in");

    $eps = new PostScript::Simple::EPS(file => "test.eps");

    $eps->scale(0.5);

Scale the EPS file by x0.5 in both directions.

    $ps->newpage();
    $ps->importeps($eps, 1, 1);

Add the EPS file to the PostScript document at coords (1,1).

    $ps->importepsfile("another.eps", 1, 2, 4, 4);

Easily add an EPS file to the PostScript document using bounding box (1,2),(4,4).

The methods C<importeps> and C<importepsfile> are described in the documentation
of C<PostScript::Simple>.

=back

=cut

sub new
{
  my ($class, %data) = @_;
  my $self = {
    file         => undef,    # filename of the eps file
    xsize        => undef,
    ysize        => undef,
    units        => "bp",     # measuring units (see below)
    clip         => 1,        # clip to the bounding box

    bbx1         => 0,        # Bounding Box definitions
    bby1         => 0,
    bbx2         => 0,
    bby2         => 0,

    epsprefix    => [],
    epsfile      => undef,
    epspostfix   => [],
  };

  foreach (keys %data)
  {
    $self->{$_} = $data{$_};
  }

  if ((!defined $self->{"file"}) && (!defined $self->{"source"})) {
    croak "must provide file or source";
  }
  if ((defined $self->{"file"}) && (defined $self->{"source"})) {
    croak "cannot provide both file and source";
  }

  bless $self, $class;
  $self->init();

  return $self;
}


#-------------------------------------------------------------------------------

sub init
{
  my $self = shift;
  my $foundbbx = 0;

  if (defined($$self{source})) {
    croak "EPS file must contain a BoundingBox" if (!$self->_getsourcebbox());
  } else {
    croak "EPS file must contain a BoundingBox" if (!_getfilebbox($self));
  }

  if (($$self{bbx2} - $$self{bbx1} == 0) ||
      ($$self{bby2} - $$self{bby1} == 0)) {
    $self->_error("PostScript::Simple::EPS: Bounding Box has zero dimension");
    return 0;
  }

  $self->reset();

  return 1;
}


#-------------------------------------------------------------------------------

=head1 OBJECT METHODS

All object methods return 1 for success or 0 in some error condition
(e.g. insufficient arguments). Error message text is also drawn on
the page.

=over 4

=item C<get_bbox>

Returns the EPS bounding box, as specified on the %%BoundingBox line
of the EPS file. Units are standard PostScript points.

Example:

    ($x1, $y1, $x2, $y2) = $eps->get_bbox();

=cut

sub get_bbox
{
  my $self = shift;

  return ($$self{bbx1}, $$self{bby1}, $$self{bbx2}, $$self{bby2});
}


#-------------------------------------------------------------------------------

=item C<width>

Returns the EPS width, in PostScript points.

Example:

  print "EPS width is " . abs($eps->width()) . "\n";

=cut

sub width
{
  my $self = shift;

  return ($$self{bbx2} - $$self{bbx1});
}


#-------------------------------------------------------------------------------

=item C<height>

Returns the EPS height, in PostScript points.

Example:

To scale $eps to 72 points high, do:

  $eps->scale(1, 72/$eps->height());

=cut

sub height
{
  my $self = shift;

  return ($$self{bby2} - $$self{bby1});
}


#-------------------------------------------------------------------------------

=item C<scale(x, y)>

Scales the EPS file. To scale in one direction only, specify 1 as the
other scale. To scale the EPS file the same in both directions, you
may use the shortcut of just specifying the one value.

Example:

    $eps->scale(1.2, 0.8); # make wider and shorter
    $eps->scale(0.5);      # shrink to half size

=cut

sub scale
{
  my $self = shift;
  my ($x, $y) = @_;

  $y = $x if (!defined $y);
  croak "bad arguments to scale" if (!defined $x);

  push @{$$self{epsprefix}}, "$x $y scale";

  return 1;
}


#-------------------------------------------------------------------------------

=item C<rotate(deg)>

Rotates the EPS file by C<deg> degrees anti-clockwise. The EPS file is rotated
about it's own origin (as defined by it's bounding box). To rotate by a particular
co-ordinate (again, relative to the EPS file, not the main PostScript document),
use translate, too.

Example:

    $eps->rotate(180);        # turn upside-down

To rotate 30 degrees about point (50,50):

    $eps->translate(50, 50);
    $eps->rotate(30);
    $eps->translate(-50, -50);
    
=cut

sub rotate
{
  my $self = shift;
  my ($d) = @_;

  croak "bad arguments to rotate" if (!defined $d);

  push @{$$self{epsprefix}}, "$d rotate";

  return 1;
}


#-------------------------------------------------------------------------------

=item C<translate(x, y)>

Move the EPS file by C<x>,C<y> PostScript points.

Example:

    $eps->translate(10, 10);      # move 10 points in both directions

=cut

sub translate
{
  my $self = shift;
  my ($x, $y) = @_;

  croak "bad arguments to translate" if (!defined $y);

  push @{$$self{epsprefix}}, "$x $y translate";

  return 1;
}


#-------------------------------------------------------------------------------

=item C<reset>

Clear all translate, rotate and scale operations.

Example:

    $eps->reset();

=cut

sub reset
{
  my $self = shift;

  @{$$self{"epsprefix"}} = ();

  return 1;
}


#-------------------------------------------------------------------------------

=item C<load>

Reads the EPS file into memory, to save reading it from file each time if
inserted many times into a document. Can not be used with C<preload>.

=cut

sub load
{
  my $self = shift;
  local *EPS;

  return 1 if (defined $$self{"epsfile"});
  return 1 if (defined $$self{"source"});

  $$self{"epsfile"} = "\%\%BeginDocument: ($$self{file})\n";
  open EPS, "< $$self{file}" || croak "can't open eps file $$self{file}";
  while (<EPS>)
  {
    $$self{"epsfile"} .= $_;
  }
  close EPS;
  $$self{"epsfile"} .= "\%\%EndDocument\n";

  return 1;
}


#-------------------------------------------------------------------------------

=item C<preload(object)>

Experimental: defines the EPS at in the document prolog, and just runs a
command to insert it each time it is used. C<object> is a PostScript::Simple
object. If the EPS file is included more than once in the PostScript file then
this will probably shrink the filesize quite a lot.

Can not be used at the same time as C<load>, or when using EPS objects defined
from PostScript source.

Example:

    $p = new PostScript::Simple();
    $e = new PostScript::Simple::EPS(file => "test.eps");
    $e->preload($p);

=cut

sub preload
{
  my $self = shift;
  my $ps = shift;
  my $randcode = "";

  croak "already loaded" if (defined $$self{"epsfile"});
  croak "can't preload when using source" if (defined $$self{"source"});

  croak "no PostScript::Simple module provided" if (!defined $ps);

  for my $i (0..7)
  {
    $randcode .= chr(int(rand()*26)+65); # yuk
  }

  $$self{"epsfile"} = "eps$randcode\n";

  $$ps{"psprolog"} .= "/eps$randcode {\n";
  $$ps{"psprolog"} .= "\%\%BeginDocument: ($$self{file})\n";
  open EPS, "< $$self{file}" || croak "can't open eps file $$self{file}";
  while (<EPS>)
  {
    $$ps{"psprolog"} .= $_;
  }
  close EPS;
  $$ps{"psprolog"} .= "\%\%EndDocument\n";
  $$ps{"psprolog"} .= "} def\n";

  return 1;
}


################################################################################
# PRIVATE methods

sub _getfilebbox
{
  my $self = shift;
  my $foundbbx = 0;

  return 0 if (!defined $$self{file});
  open EPS, "< $$self{file}" || croak "can't open eps file $$self{file}";
  SCAN: while (<EPS>)
  {
    s/[\r\n]*$//; #ultimate chomp
    if (/^\%\%BoundingBox:\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)\s*$/)
    {
      $$self{bbx1} = $1; 
      $$self{bby1} = $2; 
      $$self{bbx2} = $3; 
      $$self{bby2} = $4; 
      $foundbbx = 1;
      last SCAN;
    }
  }
  close EPS;

  return $foundbbx;
}


#-------------------------------------------------------------------------------

sub _getsourcebbox
{
  my $self = shift;

  my $ref;

  $ref = \$self->{epsfile} if defined $self->{epsfile};
  $ref = \$self->{source}  if defined $self->{source};

  return 0 unless defined $$ref;

  if ($$ref =~
      /^\%\%BoundingBox:\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)$/m)
  {
    $$self{bbx1} = $1; 
    $$self{bby1} = $2; 
    $$self{bbx2} = $3; 
    $$self{bby2} = $4; 
    return 1;
  }

  return 0;
}


#-------------------------------------------------------------------------------

sub _get_include_data
{
  my $self = shift;
  my ($x, $y) = @_;
  my $data = "";

  croak "argh... internal error (incorrect arguments)" if (scalar @_ != 2);

  foreach my $line (@{$$self{"epsprefix"}}) {
    $data .= "$line\n";
  }

  if ($$self{"clip"}) {
    $data .= "newpath $$self{bbx1} $$self{bby1} moveto
$$self{bbx2} $$self{bby1} lineto $$self{bbx2} $$self{bby2} lineto
$$self{bbx1} $$self{bby2} lineto closepath clip newpath\n";
  }

  if (defined $$self{"epsfile"}) {
    $data .= $$self{"epsfile"};
  } elsif (defined $$self{"source"}) {
    $data .= "\%\%BeginDocument: (undef)\n";
    $data .= $$self{"source"};
    $data .= "\%\%EndDocument\n";
  } else {
    $data .= "\%\%BeginDocument: ($$self{file})\n";
    open EPS, "< $$self{file}" || croak "can't open eps file $$self{file}";
    while (<EPS>) {
      $data .= $_;
    }
    close EPS;
    $data .= "\%\%EndDocument\n";
  }

  foreach my $line (@{$$self{"epspostfix"}}) {
    $data .= "$line\n";
  }

  return $data;
}

sub _error
{
  my $self = shift;
  my $msg = shift;
  $self->{pspages} .= "(error: $msg\n) print flush\n";
}


=back

=head1 BUGS

This is software in development; some current functionality may not be as
expected, and/or may not work correctly.

=head1 AUTHOR

The PostScript::Simple::EPS module was written by Matthew Newton, after prods
for such a feature from several people around the world. A useful importeps
function that provides scaling and aspect ratio operations was gratefully
received from Glen Harris, and merged into this module.

Copyright (C) 2002-2014 Matthew C. Newton

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, version 2.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details,
available at http://www.gnu.org/licenses/gpl.html.

=head1 SEE ALSO

L<PostScript::Simple>

=cut

1;

# vim:foldmethod=marker:
