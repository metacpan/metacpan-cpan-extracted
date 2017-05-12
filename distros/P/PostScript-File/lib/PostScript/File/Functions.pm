#---------------------------------------------------------------------
package PostScript::File::Functions;
#
# Copyright 2012 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created:  2 Feb 2012
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Collection of useful PostScript functions
#---------------------------------------------------------------------

use 5.008;
use strict;
use warnings;

our $VERSION = '2.23';
# This file is part of PostScript-File 2.23 (October 10, 2015)

use Carp qw(croak);
use PostScript::File 2.20 (); # strip method

# Constant indexes of the arrayrefs in the _functions hash:
sub _id_       () { 0 } ## no critic
sub _code_     () { 1 } ## no critic
sub _requires_ () { 2 } ## no critic

#=====================================================================
# Initialization:
#
# Subclasses should call __PACKAGE__->_init_module(\*DATA);

sub _init_module
{
  my ($class, $fh) = @_;

  my $function = $class->_functions;
  my @keys;
  my $routine;

  while (<$fh>) {
    if (/^%-+$/) {
      PostScript::File::->strip(all_comments => $routine);
      next unless $routine;
      $routine =~ m!^/(\w+)! or die "Can't find name in $routine";
      push @keys, $1;
      $function->{$1} = [ undef, $routine ];
      $routine = '';
    }

    $routine .= $_;
  } # end while <DATA>

  my $id = 'A';
  $id   .= 'A' while @keys > 26 ** length $id;

  my $re = join('|', @keys);
  $re = qr/\b($re)\b/;

  for my $name (@keys) {
    my $f = $function->{$name};
    $$f[_id_] = $id++;

    my %req;

    $req{$_} = 1 for $$f[_code_] =~ m/$re/g;
    delete $req{$name};

    $$f[_requires_] = [ keys %req ] if %req;
  } # end for each $f in @keys

  close $fh;

  1;
} # end _init_module
#=====================================================================


sub new
{
  my ($class) = @_;

  # Create the object:
  bless {}, $class;
} # end new

#---------------------------------------------------------------------
# The hash of available functions (class attribute):
#
# This is automatically per-class, so subclasses normally don't need
# to override it.

{
my %functions;
sub _functions
{
  my $self = shift;

  $functions{ref($self) || $self} ||= {};
} # end _functions
} # end scope of %functions

#---------------------------------------------------------------------


sub add
{
  my ($self, @names) = @_;

  my $available = $self->_functions;

  while (@names) {
    my $name = shift @names;

    croak "$name is not an available function" unless $available->{$name};
    $self->{$name} = 1;

    next unless my $need = $available->{$name}[_requires_];
    push @names, grep { not $self->{$_} } @$need;
  } # end while @names to add

  return $self;
} # end add
#---------------------------------------------------------------------


sub generate_procset
{
  my ($self, $name) = @_;

  my @list = sort { $a->[_id_] cmp $b->[_id_] }
                  @{ $self->_functions }{ keys %$self };

  my $code = join('', map { $_->[_code_] } @list);

  my $blkid = join('', map { $_->[_id_] } @list);

  unless (defined $name) {
    $name = ref $self;
    $name =~ s/::/_/g;
  }

  return wantarray
      ? ("$name-$blkid", $code, $self->VERSION)
      : $code;
} # end generate_procset
#---------------------------------------------------------------------


sub add_to_file
{
  my $self = shift;
  my $ps   = shift;

  $ps->add_procset( $self->generate_procset(@_) );
} # end add_to_file

#=====================================================================
# Package Return Value:

__PACKAGE__->_init_module(\*DATA);

#use YAML::Tiny; print Dump(\%function);

=head1 NAME

PostScript::File::Functions - Collection of useful PostScript functions

=head1 VERSION

This document describes version 2.23 of
PostScript::File::Functions, released October 10, 2015
as part of PostScript-File version 2.23.

=head1 SYNOPSIS

  use PostScript::File;

  my $ps = PostScript::File->new;
  $ps->use_functions(qw( setColor showCenter ));
  $ps->add_to_page("1 setColor\n" .
                   "400 400 (Hello, World!) showCenter\n");

=head1 DESCRIPTION

PostScript::File::Functions provides a library of handy PostScript
functions that can be used in documents created with PostScript::File.
You don't normally use this module directly; PostScript::File's
C<use_functions> method loads it automatically.

=head1 POSTSCRIPT FUNCTIONS

=head2 boxPath

  LEFT TOP RIGHT BOTTOM boxPath

Given the coordinates of the sides of a box, this creates a new,
closed path starting at the bottom right corner, across to the
bottom left, up to the top left, over to the top right, and then
back to the bottom right.

=head2 clipBox

   LEFT TOP RIGHT BOTTOM clipBox

This clips to the box defined by the coordinates.

=head2 drawBox

   LEFT TOP RIGHT BOTTOM drawBox

This calls L<boxPath> to and then strokes the path using the current
pen.

=head2 fillBox

  LEFT TOP RIGHT BOTTOM COLOR fillBox

This fills the path created by L<boxPath> with C<COLOR>, which can
be anything accepted by L<setColor>.

=head2 hLine

  WIDTH X Y hline

Stroke a horizontal line with the current pen with the left endpoint
at position C<X, Y>, extending C<WIDTH> points rightwards.

=head2 setColor

  RGB-ARRAY|BW-NUMBER setColor

This combines C<setgray> and C<setrgbcolor> into a single function.
You can provide either an array of 3 numbers for C<setrgbcolor>, or
a single number for C<setgray>.  The L<PostScript::File/str>
function was designed to format the parameter to this function.

=head2 showCenter

  X Y STRING showCenter

This prints C<STRING> centered horizontally at position X using
baseline Y and the current font.

=head2 showLeft

  X Y STRING showLeft

This prints C<STRING> left justified at position X using baseline Y
and the current font.

=head2 showLines

  X Y LINES SPACING FUNC showLines

This calls C<FUNC> for each element of C<LINES>, which should be an
array of strings.  C<FUNC> is called with C<X Y STRING> on the
stack, and it must pop those off.  C<SPACING> is subtracted from
C<Y> after every line.  C<FUNC> will normally be C<showCenter>,
C<showLeft>, or C<showRight>.

=head2 showRight

  X Y STRING showRight

This prints C<STRING> right justified at position X using baseline Y
and the current font.

=head2 vLine

  HEIGHT X Y vline

Stroke a vertical line with the current pen with the bottom endpoint
at position C<X, Y>, extending C<HEIGHT> points upwards.

=head1 METHODS

While you don't normally deal with PostScript::File::Functions objects
directly, it is possible.  The following methods are available:



=head2 new

  $funcs = PostScript::File::Functions->new;

The constructor takes no parameters.


=head2 add

  $funcs->add('functionRequested', ...);

Add one or more functions to the procset to be generated.  All
dependencies of the requsted functions are added automatically.  See
L</"POSTSCRIPT FUNCTIONS"> for the list of available functions.


=head2 add_to_file

  $funcs->add_to_file($ps, $basename);

This is short for

  $ps->add_procset( $funcs->generate_procset($basename) );

C<$ps> should normally be a PostScript::File object.
See L<PostScript::File/add_procset>.


=head2 generate_procset

  ($name, $code, $version) = $funcs->generate_procset($basename);

This collects the requsted functions into a block of PostScript code.

C<$name> is a suitable name for the procset, created by appending the
ids of the requsted functions to C<$basename>.  If C<$basename> is
omitted, it defaults to the class name with C<::> replaced by C<_>.

C<$code> is a block of PostScript code that defines the functions.  It
contains no comments or excess whitespace.

C<$version> is the version number of the procset.

In scalar context, returns C<$code>.

=head1 DIAGNOSTICS

=over

=item C<< %s is not an available function >>

You requsted a function that this version of
PostScript::File::Functions doesn't provide.


=back

=head1 CONFIGURATION AND ENVIRONMENT

PostScript::File::Functions requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-PostScript-File AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=PostScript-File >>.

You can follow or contribute to PostScript-File's development at
L<< https://github.com/madsen/postscript-file >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

__DATA__

%---------------------------------------------------------------------
% Set the color:  RGB-ARRAY|BW-NUMBER setColor
%
% This combines C<setgray> and C<setrgbcolor> into a single function.
% You can provide either an array of 3 numbers for C<setrgbcolor>, or
% a single number for C<setgray>.  The L<PostScript::File/str>
% function was designed to format the parameter to this function.

/setColor
{
  dup type (arraytype) eq {
    % We have an array, so it's RGB:
    aload pop
    setrgbcolor
  }{
    % Otherwise, it must be a gray level:
    setgray
  } ifelse
} bind def

%---------------------------------------------------------------------
% Create a rectangular path:  LEFT TOP RIGHT BOTTOM boxPath
%
% Given the coordinates of the sides of a box, this creates a new,
% closed path starting at the bottom right corner, across to the
% bottom left, up to the top left, over to the top right, and then
% back to the bottom right.

/boxPath
{
  % stack L T R B
  newpath
  2 copy moveto                 % move to BR
  3 index exch lineto	        % line to BL
  % stack L T R
  1 index
  % stack L T R T
  4 2 roll
  % stack R T L T
  lineto                        % line to TL
  lineto                        % line to TR
  closepath
} bind def

%---------------------------------------------------------------------
% Clip to a rectangle:   LEFT TOP RIGHT BOTTOM clipBox
%
% This clips to the box defined by the coordinates.

/clipBox { boxPath clip } bind def

%---------------------------------------------------------------------
% Draw a rectangle:   LEFT TOP RIGHT BOTTOM drawBox
%
% This calls L<boxPath> to and then strokes the path using the current
% pen.

/drawBox { boxPath stroke } bind def

%---------------------------------------------------------------------
% Fill a box with color:  LEFT TOP RIGHT BOTTOM COLOR fillBox
%
% This fills the path created by L<boxPath> with C<COLOR>, which can
% be anything accepted by L<setColor>.

/fillBox
{
  gsave
  setColor
  boxPath
  fill
  grestore
} bind def

%---------------------------------------------------------------------
% Print text centered at a point:  X Y STRING showCenter
%
% This prints C<STRING> centered horizontally at position X using
% baseline Y and the current font.

/showCenter
{
  newpath
  0 0 moveto
  % stack X Y STRING
  dup 4 1 roll                          % Put a copy of STRING on bottom
  % stack STRING X Y STRING
  false charpath flattenpath pathbbox   % Compute bounding box of STRING
  % stack STRING X Y Lx Ly Ux Uy
  pop exch pop                          % Discard Y values (... Lx Ux)
  add 2 div neg                         % Compute X offset
  % stack STRING X Y Ox
  0                                     % Use 0 for y offset
  newpath
  moveto
  rmoveto
  show
} bind def

%---------------------------------------------------------------------
% Print left justified text:  X Y STRING showLeft
%
% This prints C<STRING> left justified at position X using baseline Y
% and the current font.

/showLeft
{
  newpath
  3 1 roll  % STRING X Y
  moveto
  show
} bind def

%---------------------------------------------------------------------
% Print right justified text:  X Y STRING showRight
%
% This prints C<STRING> right justified at position X using baseline Y
% and the current font.

/showRight
{
  newpath
  0 0 moveto
  % stack X Y STRING
  dup 4 1 roll                          % Put a copy of STRING on bottom
  % stack STRING X Y STRING
  false charpath flattenpath pathbbox   % Compute bounding box of STRING
  % stack STRING X Y Lx Ly Ux Uy
  pop exch pop                          % Discard Y values (... Lx Ux)
  add neg                               % Compute X offset
  % stack STRING X Y Ox
  0                                     % Use 0 for y offset
  newpath
  moveto
  rmoveto
  show
} bind def

%---------------------------------------------------------------------
% Print text on multiple lines:  X Y LINES SPACING FUNC showLines
%
% This calls C<FUNC> for each element of C<LINES>, which should be an
% array of strings.  C<FUNC> is called with C<X Y STRING> on the
% stack, and it must pop those off.  C<SPACING> is subtracted from
% C<Y> after every line.  C<FUNC> will normally be C<showCenter>,
% C<showLeft>, or C<showRight>.

/showLines
{
  cvx                    % convert name of FUNC to executable function
  5 2 roll               % stack SPACING FUNC X Y LINES
  {                      % stack SPACING FUNC X Y STRING
    2 index              % stack SPACING FUNC X Y STRING X
    2 index              % stack SPACING FUNC X Y STRING X Y
    6 index  sub         % subtract SPACING from Y
    5 2 roll             % stack SPACING FUNC X Y' X Y STRING
    5 index exec         % execute FUNC; stack SPACING FUNC X Y'
  } forall
  pop pop pop pop
} bind def

%---------------------------------------------------------------------
% Stroke a horizontal line:  WIDTH X Y hline
%
% Stroke a horizontal line with the current pen with the left endpoint
% at position C<X, Y>, extending C<WIDTH> points rightwards.

/hLine
{
  newpath
  moveto
  0 rlineto stroke
} bind def

%---------------------------------------------------------------------
% Stroke a vertical line:  HEIGHT X Y vline
%
% Stroke a vertical line with the current pen with the bottom endpoint
% at position C<X, Y>, extending C<HEIGHT> points upwards.

/vLine
{
  newpath
  moveto
  0 exch rlineto stroke
} bind def

%---------------------------------------------------------------------
%EOF
