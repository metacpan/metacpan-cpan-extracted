

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.02    |30.04.2006| JSTENZEL | bugfixes: module was not adapted to some stream format
#         |          |          | changes and extensions (page parts after headline
#         |          |          | wrapped into array, initial main stream entry point
#         |          |          | marked as well);
# 0.01    |23.05.2003| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# = POD SECTION =========================================================================

=head1 NAME

B<PerlPoint::Generator::SDF::Default> - default, traditional SDF generator class

=head1 VERSION

This manual describes version B<0.02>.

=head1 SYNOPSIS



=head1 DESCRIPTION


=head1 METHODS

=cut




# check perl version
require 5.00503;

# = PACKAGE SECTION (internal helper package) ==========================================

# declare package
package PerlPoint::Generator::SDF::Default;

# declare package version
$VERSION=0.02;
$AUTHOR='J. Stenzel (perl@jochen-stenzel.de), 2003-2006';



# = PRAGMA SECTION =======================================================================

# set pragmata
use strict;

# inherit from common generator class
use base qw(PerlPoint::Generator::SDF);

# declare object data fields
use fields qw(
              targethandles
              docstreamdata
              docstreamhandles
             );


# = LIBRARY SECTION ======================================================================

# load modules
use Carp;
use PerlPoint::Constants;
use PerlPoint::Converters;
use PerlPoint::Generator::SDF;

# = CODE SECTION =========================================================================


# inits: placeholder counter
my $phc=0;


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
  confess "[BUG] Missing options hash.\n" unless exists $params{options};

  # build object
  my $me=fields::new($class);

  # store options of interest
  $me->{options}{$_}=$params{options}{$_}
   for grep(exists $params{options}{$_}, qw(
                                           ),
           );

  # supply new object
  $me;
 }



# check usage
sub checkUsage
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # don't forget the base class
  $me->SUPER::checkUsage;

  # check your own options, if necessary
 }


# sub bootstrap
#  {
#   # get and check parameters
#   (my __PACKAGE__ $me)=@_;
#   confess "[BUG] Missing object parameter.\n" unless $me;
#   confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

#   # don't forget the base class
#   $me->SUPER::bootstrap;
#  }

# initializations done when a backend is available
sub initBackend
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # don't forget the base class
  $me->SUPER::initBackend;

  # open result file(s): docstreams to handle?
  if (
          (
              not exists $me->{options}{dstreaming}
           or $me->{options}{dstreaming}==DSTREAM_DEFAULT
          )
      and $me->{backend}->docstreams
     )
    {
     # scopies
     my ($c, $d)=(0, 1);

     # open a target file for each handle
     foreach my $docstream (grep(($_ ne 'main'), sort $me->{backend}->docstreams))
       {
        # build filename
        my $filename="$me->{options}{targetdir}/$me->{options}{prefix}-stream-$d$me->{options}{suffix}";

        # inform user, if necessary
        warn qq([Info] Document stream "$docstream" generates result file $filename.\n) unless exists $me->{options}{noinfo};

        # open file
        $me->{targethandles}[$c]=new IO::File(">$filename");

        # store handle
        $me->{docstreamhandles}{$docstream}=$me->{targethandles}[$c];

        # update counters
        $c++; $d++;
       }
    }
  else
    {
     # default output file, named as specified
     $me->{docstreamhandles}{main}=$me->{targethandles}[0]=new IO::File(">$me->{options}{targetdir}/$me->{options}{prefix}$me->{options}{suffix}");
    }
 }


# docstream entry formatter
{
 # define a call counter
 my $dstreamCounter;

 sub formatDStreamEntrypoint
  {
   # get and check parameters
   ((my __PACKAGE__ $me), my ($page, $item))=@_;
   confess "[BUG] Missing object parameter.\n" unless $me;
   confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
   confess "[BUG] Missing page data parameter.\n" unless $page;
   confess "[BUG] Missing item parameter.\n" unless $item;

   # provide this part in a simple structure (avoid to use a hash reference),
   # but skip the stream name if this is the first stream (initial entry point
   # of the default main stream)
   [$dstreamCounter++ ? $item->{cfg}{data}{name} : (), join('', @{$item->{parts}})];
  }


# we have an own headline formatter to reset the docstream counter
sub formatHeadline
 {
  # get and check parameters
  my ($me, $page, $item)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # reset docstream counter
  $dstreamCounter=0;

  # call base method to do the real formatting
  $me->SUPER::formatHeadline($page, $item);
 }
}


# docstream frame formatter
sub formatDStreamFrame
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($page, $item))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless $item;

  # generate a placeholder string
  my $placeholder=join('::', ref($me), $phc++);

  # store stream data (concatenated within every stream)
  foreach my $dstream (@{$item->{parts}})
    {
     # extract stream name and data
     my ($name, $data)=@$dstream;

     # add data
     $me->{docstreamdata}{$placeholder}{$name}.=$data;
    }

  # supply the generic placeholder
  $placeholder;
 }


# page formatter
sub formatPage
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($page, $item))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless $item;

  # concatenate the parts (first part is the headline, further parts are wrapped into an array)
  my $template=join('', $item->{parts}[0], @{$item->{parts}}>1 ? @{ref($item->{parts}[1]) ? $item->{parts}[1] : $item->{parts}} : ());

  # produce a page for every stream we know
  foreach my $stream (sort keys %{$me->{docstreamhandles}})
    {
     # use a copy of the template
     my $page=$template;

     # replace all placeholders appropriately
     foreach my $placeholder (sort keys %{$me->{docstreamdata}})
       {
        my $replacement=exists $me->{docstreamdata}{$placeholder}{$stream} ? $me->{docstreamdata}{$placeholder}{$stream} : '';
        $page=~s/$placeholder/$replacement/;
       }

     # print page via the handle associated with its stream
     my $handle=$me->{docstreamhandles}{$stream};
     print $handle $page;
    }

  # cleanup: delete all stored stream data
  $me->{docstreamdata}={};  

  # supply nothing
  '';
 }

# flag successfull loading
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

Copyright (c) Jochen Stenzel (perl@jochen-stenzel.de), 2003-2006.
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

