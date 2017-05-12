

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.03    |15.12.2005| JSTENZEL | added a few more POD lines, still to be completed;
# 0.02    |11.07.2004| JSTENZEL | new (startet as 0.01 - ?).
# ---------------------------------------------------------------------------------------

# = POD SECTION =========================================================================

=head1 NAME

B<PerlPoint::Generator::Object::Page> - generators page object class

=head1 VERSION

This manual describes version B<0.03>.

=head1 SYNOPSIS



=head1 DESCRIPTION

This is an internal class. Objects represent chapters and provide access
to various chapter data, see method descriptions below.

=head1 METHODS

=cut




# check perl version
require 5.00503;

# = PACKAGE SECTION ======================================================================

# declare package
package PerlPoint::Generator::Object::Page;

# declare package version and author
$VERSION=0.03;
$AUTHOR=$AUTHOR='J. Stenzel (perl@jochen-stenzel.de), 2004-2005';


# = PRAGMA SECTION =======================================================================

# set pragmata
use strict;

# declare object data fields
use fields qw(
              nr
              fpath
              spath
              npath
              ppath
              vars
             );


# = LIBRARY SECTION ======================================================================

# load modules
use Carp;


# = CODE SECTION =========================================================================

=pod

=head2 new()


B<Parameters:>

=over 4

=item class

The class name.

=back

B<Returns:> the new object.

B<Example:>


=cut
sub new
 {
  # get parameter
  my ($class, %params)=@_;

  # check parameters
  confess "[BUG] Missing class name.\n" unless $class;

  # build new object
  my __PACKAGE__ $me=fields::new($class);

  # init it
  $me->{nr}    = exists $params{nr}    ? $params{nr}    : 0;
  $me->{fpath} = exists $params{fpath} ? $params{fpath} : undef;
  $me->{spath} = exists $params{spath} ? $params{spath} : undef;
  $me->{npath} = exists $params{npath} ? $params{npath} : [0];    # for intros before a first headline (like a (LOCAL)TOC)
  $me->{ppath} = exists $params{ppath} ? $params{ppath} : [0];    # for intros before a first headline (like a (LOCAL)TOC)
  $me->{vars}  = exists $params{vars}  ? $params{vars}  : undef;

  # and supply it
  $me;
 }


=pod

=head2 path()

Provides the path of a chapter, this means, the sequence of main and subchapters to enter the document
part under a certain headline.

B<Parameters:>

=over 4

=item object

An object as produced by C<new()>.

=item parameters

This should be a reference to a hash containing the following keys:

=over 4

=item type

A chapter path has various forms (or types). Choose here which is of interest.

=over 4

=item fpath

the path of full (or long) chapter titles (headlines)

=item npath

the I<numerical> path - levels are represented by their I<public> numbers, as used in schemes like
C<1.2.3.4.>.

=item ppath

the I<page> headline path: each level holds its chapter number.

=item spath

the path of I<short> chapter titles (or headlines), these are the parts entered after
an optional C<~> in a headline:

  =Long headline ~ Short

=back

=item mode

Configures how the path should be suppplied:

=over 4

=item array

All parts of the path are elements of an array that is supplied via reference.

=item full

The path is provided as a string. Parts are delimited by the value of option
C<delimiter> which is mandatory in this mode.

=item title

Supplies just the last part of the path (this is the chapters own title).

=back

=item delimiter

In mode C<full> this needs to be set to a string that is used as a
delimiter between the path parts.

=back

=back

B<Returns:> the requested path, as configured by option C<mode>.

B<Example:>


=cut
sub path
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my %params)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing type parameter.\n" unless exists $params{type};
  confess "[BUG] Invalid type parameter.\n" unless $params{type}=~/^[fnps]path$/; # full, numerical, page or short
  confess "[BUG] Missing mode parameter.\n" unless exists $params{mode};
  confess "[BUG] Invalid mode parameter.\n" unless $params{mode}=~/^(array|full|title)$/;
  confess "[BUG] Missing delimiter parameter.\n" if $params{mode} eq 'full' and not exists $params{delimiter};

  # build and supply the path, mode dependend
  if ($params{mode} eq 'array')
    {defined($me->{$params{type}}) ? [@{$me->{$params{type}}}] : [];}
  elsif ($params{mode} eq 'full')
    {defined($me->{$params{type}}) ? join($params{delimiter}, map {(defined) ? $_ : ''} @{$me->{$params{type}}}[0..($#{$me->{$params{type}}}-1)]) : '';}
  elsif ($params{mode} eq 'title')
    {defined($me->{$params{type}}) ? $me->{$params{type}}[-1] : '';}
  else
    {die "[BUG] Unimplemented case.";}
 }


=pod

=head2 nr()

Provide chapter number.

B<Parameters:>

=over 4

=item object

An object as produced by C<new()>.

=back

B<Returns:> the page (or chapter) number.

B<Example:>


=cut
sub nr
 {
  # get and check parameters
  ((my __PACKAGE__ $me))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # supply data
  $me->{nr};
 }


=pod

=head2 vars()

Provide chapter variables.

B<Parameters:>

=over 4

=item object

An object as produced by C<new()>.

=back

B<Returns:> the chapters variables, as a hash.

B<Example:>


=cut
sub vars
 {
  # get and check parameters
  ((my __PACKAGE__ $me))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # supply data (as copy as usual)
  return {%{$me->{vars}}};
 }



# MODULE FRAME COMPLETION ####################################################


# flag successful loading
1;


# = POD TRAILER SECTION =================================================================

=pod

=head1 NOTES


=head1 SEE ALSO

=over 4



=back


=head1 SUPPORT

A PerlPoint mailing list is set up to discuss usage, ideas,
bugs, suggestions and translator development. To subscribe,
please send an empty message to perlpoint-subscribe@perl.org.

If you prefer, you can contact me via perl@jochen-stenzel.de
as well.

=head1 AUTHOR

Copyright (c) Jochen Stenzel (perl@jochen-stenzel.de), 2004-2005.
All rights reserved.

This module is free software, you can redistribute it and/or modify it
under the terms of the Artistic License distributed with Perl version
5.003 or (at your option) any later version. Please refer to the
Artistic License that came with your Perl distribution for more
details.

The Artistic License should have been included in your distribution of
Perl. It resides in the file named "Artistic" at the top-level of the
Perl source tree (where Perl was downloaded/unpacked - ask your
system administrator if you dont know where this is).  Alternatively,
the current version of the Artistic License distributed with Perl can
be viewed on-line on the World-Wide Web (WWW) from the following URL:
http://www.perl.com/perl/misc/Artistic.html


=head1 DISCLAIMER

This software is distributed in the hope that it will be useful, but
is provided "AS IS" WITHOUT WARRANTY OF ANY KIND, either expressed or
implied, INCLUDING, without limitation, the implied warranties of
MERCHANTABILITY and FITNESS FOR A PARTICULAR PURPOSE.

The ENTIRE RISK as to the quality and performance of the software
IS WITH YOU (the holder of the software).  Should the software prove
defective, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR
CORRECTION.

IN NO EVENT WILL ANY COPYRIGHT HOLDER OR ANY OTHER PARTY WHO MAY CREATE,
MODIFY, OR DISTRIBUTE THE SOFTWARE BE LIABLE OR RESPONSIBLE TO YOU OR TO
ANY OTHER ENTITY FOR ANY KIND OF DAMAGES (no matter how awful - not even
if they arise from known or unknown flaws in the software).

Please refer to the Artistic License that came with your Perl
distribution for more details.

