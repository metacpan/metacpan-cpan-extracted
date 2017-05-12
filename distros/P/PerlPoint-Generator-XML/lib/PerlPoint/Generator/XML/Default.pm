 

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.01    |18.08.2003| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# = POD SECTION =========================================================================

=head1 NAME

B<PerlPoint::Generator::XML::Default> - default XML generator class

=head1 VERSION

This manual describes version B<0.01>.

=head1 SYNOPSIS



=head1 DESCRIPTION


=head1 METHODS

=cut




# check perl version
require 5.00503;

# = PACKAGE SECTION (internal helper package) ==========================================

# declare package
package PerlPoint::Generator::XML::Default;

# declare package version
$VERSION=0.01;
$AUTHOR='J. Stenzel (perl@jochen-stenzel.de), 2003';



# = PRAGMA SECTION =======================================================================

# set pragmata
use strict;

# inherit from common generator class
use base qw(PerlPoint::Generator::XML);

# declare object data fields
use fields qw(
              slides
              targethandle
             );


# = LIBRARY SECTION ======================================================================

# load modules
use Carp;
use PerlPoint::Constants;
use PerlPoint::Converters;
use PerlPoint::Generator::XML;

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

  # being here means that the check suceeded
  1;
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

  # open result file
  my $handle=$me->{targethandle}=new IO::File(">$me->{options}{targetdir}/$me->{options}{prefix}$me->{options}{suffix}");

  # start XML
  print $handle $me->{xml}->xmldecl({version => 1.0,});
  print $handle $me->{xml}->xmldtd(
                                   [
                                    # document type (needs to match the root element)
                                    $me->elementName('__root'),

                                    # external id (e.g. "SYSTEM //W3C//DTD XHTML 1.0 Transitional//EN"
                                    exists $me->{options}{xmldoctypeid} ? $me->{options}{xmldoctypeid} : (),

                                    # DTD (e.g. "perlpoint-simple.dtd"
                                    exists $me->{options}{xmldtd} ? $me->{options}{xmldtd} : (),
                                   ]
                                  ), "\n\n";
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

  # store this slide
  my $tagname=$me->elementName('__slide');
  push(
       @{$me->{slides}},
       $me->{xml}->$tagname(
                            {
                            },
                            @{$item->{parts}},
                           )
      ) if @{$item->{parts}} and grep(ref($_)!~/::comment$/, @{$item->{parts}});

  # supply nothing
  '';
 }

# finish
sub finish
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # don't forget the base class
  $me->SUPER::finish;

  # write document
  my ($handle, $presentationTag, $docdataTag, $slidesTag)=($me->{targethandle}, $me->elementName('__root'), $me->elementName('__docdata'), $me->elementName('__slides'));
  print $handle $me->{xml}->$presentationTag(
                                             # add meta data part
                                             $me->{xml}->$docdataTag(
                                                                     # the "doc..." options are reserved for this ...
                                                                     map
                                                                      {
                                                                       /^doc(.+)$/;
                                                                       my $tag=$me->elementName("_$1");
                                                                       $me->{xml}->$tag($me->{options}{$_}),
                                                                      } sort grep(/^doc/, keys %{$me->{options}}),
                                                                    ),

                                             # embed slides into a special section
                                             $me->{xml}->$slidesTag(@{$me->{slides}}),
                                            ), "\n\n";


  # close document
  close($handle);
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

Copyright (c) Jochen Stenzel (perl@jochen-stenzel.de), 2003.
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

