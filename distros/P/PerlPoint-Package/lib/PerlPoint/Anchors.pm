

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.03    |18.08.2003| JSTENZEL | new method generic();
#         |05.05.2004| JSTENZEL | anchors now store the absolute number of their page,
#         |          |          | (which changes the results of query() from scalar string
#         |          |          | to [$headline, $page]!;
#         |12.09.2004| JSTENZEL | using the portable fields::new();
#         |16.09.2004| JSTENZEL | objects declared as typed lexicals now;
# 0.02    |< 14.04.02| JSTENZEL | new methods checkpoint() and reportNew();
#         |19.04.2002| JSTENZEL | adapted the construction of reportNew()'s return
#         |          |          | value construction to certainly reply a hash ref.;
# 0.01    |11.10.2001| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# = POD SECTION =========================================================================

=head1 NAME

B<PerlPoint::Anchors> - simple anchor collection class

=head1 VERSION

This manual describes version B<0.03>.

=head1 SYNOPSIS

  # make a new object
  my $anchors=new PerlPoint::Anchors;

  # register an anchor
  $anchors->add('page number', '500');

  # check an anchor for being known
  ... if $anchors->query('page number');

  # get a list of all registered anchors
  my %regAnchors=%{$anchors->query};  


=head1 DESCRIPTION

Anchors are no part of the PerlPoint language definition, but used by various tags
which either define or reference them. To support those tags, this simple collection
class was implemented. It provides a consistent and general interface for dealing
with anchors.

By using the module, one can register an anchor together with a value and query
these data later, to check if a certain anchor was already registered or to access
the anchor related value. A value can be any valid Perl data. Additionally, the
complete collection can be requested.


=head1 METHODS

=cut




# check perl version
require 5.00503;

# = PACKAGE SECTION (internal helper package) ==========================================

# declare package
package PerlPoint::Anchors;

# declare package version
$VERSION=0.03;



# = PRAGMA SECTION =======================================================================

# set pragmata
use strict;

# declare attributes
use fields qw(anchors logMode newAnchors genericPrefix generator);



# = LIBRARY SECTION ======================================================================

# load modules
use Carp;


# = CODE SECTION =========================================================================


=pod

=head2 new()

The constructor builds and prepares a new collection object. You may
have more than one object at a certain time, they work independently.

B<Parameters:>

=over 4

=item class

The class name.

=item class

An optional prefix for generic anchor names. Defaults to "__GANCHOR__".

=back

B<Returns:> the new object.

B<Example:>

  my $anchors=new PerlPoint::Anchors;

=cut
sub new
 {
  # get parameter
  my ($class, $genericPrefix)=@_;

  # check parameters
  confess "[BUG] Missing class name.\n" unless $class;

  # build object
  my $me=fields::new($class);

  # set logging up
  $me->checkpoint(0);

  # init generator of anchor generic anchor names
  $me->{generator}=0;
  $me->{genericPrefix}=defined $genericPrefix ? $genericPrefix : '__GANCHOR__';

  # supply new object
  $me;
 }



=pod

=head2 add()

Registers a new anchor together with a related value. The value is optional
and might be whatever data Perl allows to store via a scalar.

B<Parameters:>

=over 4

=item object

An object made by C<new>.

=item name

The anchors name. This is a string. It is I<not> checked if the name was
already registered before, an existing entry will be overwritten quietly.

=item value

Data related to the anchor. This is an scalar. The object does nothing
with it then storing and providing it on request, so it is up to the user
what kind of data is collected here.

=item page

The absolute number of the page the anchor is located in. This counting starts
with 1 for the first chapter and continues with 2, 3 etc. regardless of chapter levels.

=back

B<Returns:> the object.

B<Example:>

  $anchors->add('new anchor', [{new=>'anchor'}], 17);

=cut
sub add
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($name, $value, $page))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and ref $me eq __PACKAGE__;
  confess "[BUG] Missing anchor name parameter.\n" unless defined $name;
  confess "[BUG] Missing page number parameter.\n" unless defined $page;

  # add new anchor (should we check overwriting?)
  $me->{anchors}{$name}=[defined $value ? $value : undef, $page];

  # update anchor log, if necessary
  $me->{newAnchors}{$name}=$me->{anchors}{$name} if $me->{logMode};

  # supply modified object
  $me;
 }



=pod

=head2 query()

Requests anchors from the collection. This can be either the complete
collection or just one entry. The method can be used both to check
if an anchor was registered and to get its value.


B<Parameters:>

=over 4

=item object

An object made by C<new()>.

=item name

The name of the anchor of interest.

This parameter is optional.

=back

B<Returns:>

If no C<name> was passed, the complete collection is provided as a
reference to a hash containing name-value/page-pairs. The referenced hash
is the objects own hash used internally, so modifications will affect
the object.

If an anchor name was passed and this name was registered, a hash
reference is provided as well (for reasons of consistency). The
referenced hash is a I<copy> and contains the appropriate pair of
anchor name and a reference to an array of its value and page.

If an anchor name was passed and this name was I<not> registered,
the method returns an undefined value.

B<Examples:>

  # check an anchor for being known
  ... if $anchors->query('new anchor');

  # get the value of an anchor
  if ($anchors->query('new anchor'))
   {$value=$anchors->query('new anchor')->{'new anchor'};}

  # get the collection
  my %anchorHash=%{$anchors->query};

=cut
sub query
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my $name)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and ref $me eq __PACKAGE__;

  # certain name of interest?
  if (defined $name)
    {return exists $me->{anchors}{$name} ? {$name=>$me->{anchors}{$name}} : undef;}

  # ok, provide the complete list
  %{$me->{anchors}} ? $me->{anchors} : undef;
 }


=pod

=head2 checkpoint()

Activates or deactivates logging of all anchors added after this call.
By default, logging is switched off.

The list of new anchors can be requested by a call of I<reportNew()>.

Previous logs are I<reset> by a new call of C<checkpoint()>.

B<Parameters:>

=over 4

=item object

An object made by C<new>.

=item logging mode

Logging is activated by a true value, disabled otherwise.

=back

B<Returns:> the object.

B<Example:>

  $anchors->checkpoint;

=cut
sub checkpoint
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my $mode)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and ref $me eq __PACKAGE__;

  # reset log, flag logging state
  $me->{newAnchors}={};
  $me->{logMode}=(defined $mode and $mode) ? 1 : 0;

  # supply modified object
  $me;
 }


=pod

=head2 reportNew()

Reports anchors added after the last recent call of C<checkpoint()>.
If the C<checkpoint()> invokation disabled anchor logging, the result
will by empty even if anchors I<were> added.

Requesting the log does I<not> reset the logging data. To reset it,
I<checkpoint()> needs to be called again.

B<Parameters:>

=over 4

=item object

An object made by C<new>.

=back

B<Returns:> A reference to a hash containing names and values of
newly added anchors. The supplied hash can be modified without
effect to the object.

B<Example:>

  my $newAnchorHash=$anchors->reportNew;

=cut
sub reportNew
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and ref $me eq __PACKAGE__;

  # supply a reference to a hash of added anchors (use a helper variable
  # to enforce perl to recognize the hash reference constructor)
  my $rc={%{$me->{newAnchors}}};
  $rc;
 }


=pod

=head2 generic()

Supplies a generic anchor name build according to the pattern /^<generic prefix>\d+$/ (with
the <generic prefix> set up in the call of I<new()>) - so it is recommended not to use those
names explicitly.

B<Parameters:>

=over 4

=item object

An object made by C<new>.

=back

B<Returns:> The new anchor name.

B<Example:>

  $anchors->add($anchors->generic, $data);

=cut
sub generic
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and ref $me eq __PACKAGE__;

  # suppply a new generic name
  join('', $me->{genericPrefix}, ++$me->{generator});
 }




# flag successful loading
1;

# = POD TRAILER SECTION =================================================================

=pod

=head1 NOTES


=head1 SEE ALSO

=over 4

=item B<PerlPoint::Parser>

The parser module working on base of the declarations.


=back


=head1 SUPPORT

A PerlPoint mailing list is set up to discuss usage, ideas,
bugs, suggestions and translator development. To subscribe,
please send an empty message to perlpoint-subscribe@perl.org.

If you prefer, you can contact me via perl@jochen-stenzel.de
as well.

=head1 AUTHOR

Copyright (c) Jochen Stenzel (perl@jochen-stenzel.de), 1999-2004.
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

