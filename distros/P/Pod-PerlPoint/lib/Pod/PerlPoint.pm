

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.05    |28.12.2004| JSTENZEL | new configure() allows to switch to dotted text paragraphs
#         |          |          | (as introduced by PerlPoint::Parser 0.40);
# 0.04    |29.05.2004| JSTENZEL | now supports "=for perlpoint" and "=begin perlpoint";
#         |          | JSTENZEL | bugfix: X<word> is equivalent to \X{mode=index_only}<word>,
#         |          |          | not \X<word>;
# 0.03    |03.01.2003| JSTENZEL | headlines are preceded by explicit empty lines now;
#         |          | JSTENZEL | bugfix: \L's address option is "url", not "a";
#         |          | JSTENZEL | variable __pod2pp__empty__ is now (un)set within
#         |          |          | the generated PerlPoint, users do no longer have to
#         |          |          | take care of it themselves;
# 0.02    |04.12.2002| JSTENZEL | new implementation (derived from Pod::Simple::Text).
# 0.01    |01.09.2002| JSTENZEL | First version on base of Pod::Parser.
# ---------------------------------------------------------------------------------------

# = POD SECTION =========================================================================

=head1 NAME

B<Pod::PerlPoint> - a POD to PerlPoint converter class

=head1 VERSION

This manual describes version B<0.05>.

=head1 SYNOPSIS

 # load the module
 use Pod::PerlPoint;

 # build an object
 $d=new Pod::PerlPoint;

 # process the POD source
 $d->parse_file($podFile);


=head1 DESCRIPTION

C<Pod::PerlPoint> is a translator class to transform POD documents into PerlPoint
sources. It is based on C<Pod::Simple::Methody> and inherits all its capabilities, so please
see the docs of C<Pod::Simple::Methody> for advanced features.

Once you have transformed a POD document into PerlPoint, it may be furtherly processed
using the PerlPoint utilities.

If you prefer, you do not need to perform an explicit transformation. Beginning with
release 0.38, C<PerlPoint::Package> can process POD sources directly. Please see
C<PerlPoint::Parser> for details, or the documentation that comes with PerlPoint.

=head1 METHODS

This module directly provides a constructor only. As C<Pod::PerlPoint> is a subclass
of <Pod::Simple::Methody>, all the methods of this parent class are available as well.

The constructor takes the exactly same parameters as C<Pod::Simple::Methody::new()>,
please see there for details.

=cut




# check perl version
require 5;

# = PACKAGE SECTION ======================================================================

# declare package
package Pod::PerlPoint;

# declare package version
$VERSION=0.05;

# declare attributes
use fields qw(_safeStartString);

# inheritance
@ISA=(qw(Pod::Simple::Methody));


# = PRAGMA SECTION =======================================================================

# set pragmata
use strict;


# = LIBRARY SECTION ======================================================================

# load modules
use Carp;
use Pod::Simple;
use Pod::Simple::Methody;

use Data::Dumper;


# = CODE SECTION =========================================================================


# just copied from Pod::Simple::Text ...
BEGIN {*DEBUG=defined(&Pod::Simple::DEBUG) ? \&Pod::Simple::DEBUG : sub() {0}}

# constructor
sub new
 {
  # get parameters (classname or object)
  my $me=shift;

  # call base class constructor to build the new object
  my $new=$me->SUPER::new(@_);

  # register embedded perlpoint
  $new->accept_target('perlpoint');

  # configure output target
  $new->{output_fh}||=*STDOUT{IO};

  # configure object
  $new->{paragraph}='';
  $new->{_pod2ppEmptyVarDefined}=0;
  $new->{_safeStartString}='${__pod2pp__empty__}';

  # provide the new object
  $new;
 }

# configuration
sub configure
 {
  # get and check parameters
  my ($me, %pars)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # prepare dotted texts, if necessary
  $me->{_safeStartString}='.', $me->{_pod2ppEmptyVarDefined}=1
    if exists $pars{parser40} and $pars{parser40};
 }


# Declare several POD element handlers to produce PerlPoint equivalents.

# plain text
sub handle_text
 {
  # emit immediately in case we are handling embedded PerlPoint
  print({$_[0]->{output_fh}} $_[1], "\n\n"), return if $_[0]{perlpoint};

  # escape special characters (which are not only special at the *beginning*
  # of a paragraph), if necessary
  $_[1]=~s/([\\>~])/\\$1/g unless $_[0]{verbatimFlag};

  # check paragraph beginning, guard special characters, if necessary
  # (such characters which have a special PerlPoint meaning but are pure text in POD)
  $_[0]{paragraph}=$_[0]{_safeStartString} unless length($_[0]{paragraph});

  # add a definition of the special variable used, unless done before
  $_[0]{_pod2ppEmptyVarDefined}=1, $_[0]{paragraph}="\n\n\$__pod2pp__empty__=\n\n$_[0]{paragraph}" unless $_[0]{_pod2ppEmptyVarDefined};

  # update text collection
  $_[0]{paragraph}.=$_[1];

  # if we are at the beginning of a numbered list, flag that text was seen
  $_[0]{nlist}=2 if length($_[1]) and exists $_[0]{nlist} and $_[0]{nlist}==1;
 }


# paragraph - reset internal buffer at the beginning, flush it when completed
sub start_Para  {$_[0]{paragraph}='';}
sub end_Para    {$_[0]->emit_par(0);}

# headlines
sub start_head1 {$_[0]->_start_head(1)}
sub end_head1   {$_[0]->emit_par(-4);}

sub start_head2 {$_[0]->_start_head(2)}
sub end_head2   {$_[0]->emit_par(-3);}

sub start_head3 {$_[0]->_start_head(3)}
sub end_head3   {$_[0]->emit_par(-2);}

sub start_head4 {$_[0]->_start_head(4)}
sub end_head4   {$_[0]->emit_par(-1);}

# internal helper method
sub _start_head
 {
  # store current headline level
  $_[0]{headlineLevel}=$_[1];

  # start headline, precede it by empty lines to avoid inclusion confusion
  $_[0]{paragraph}=join('', "\n\n", '=' x $_[1]);
 }


sub start_over_number  {push(@{$_[0]{listType}}, '');}
sub end_over_number    {pop(@{$_[0]{listType}});}

# list elements: bullet list elements ...
sub start_item_bullet
 {
  # begin bullet point
  $_[0]{paragraph}='* ';
 }

sub end_item_bullet   {$_[0]->emit_par(0);}

# ... numbered list elements ...
sub start_item_number
 {
  # flag that we are within a numbered list (might possibly need to be stacked
  # for nested list levels)
  $_[0]{nlist}=1;

  # begin the list point (in case of a continued list, mark this case)
  $_[0]{paragraph}=($_[0]{listType}[-1] and $_[0]{listType}[-1] eq '#') ? '## ' : '# ';

  # add a definition of the special variable used, unless done before
  $_[0]{_pod2ppEmptyVarDefined}=1, $_[0]{paragraph}="\n\n\$__pod2pp__empty__=\n\n$_[0]{paragraph}" unless $_[0]{_pod2ppEmptyVarDefined};

  # store list type
  $_[0]{listType}[-1]='#';
 }

sub end_item_number
 { 
  # in POD, numbered points might begin with a verbatim block directly, which
  # would produce syntactically incorrect PerlPoint without care
  $_[0]{paragraph}.=$_[0]{_safeStartString} if $_[0]{nlist}==1;

  # now flush as usual
  $_[0]->emit_par(0);

  # reset flag
  $_[0]{nlist}=0;
 }

# ... and text elements - make them subchapters (makes them anchors implicitly,
# which matches POD's behaviour)
sub start_item_text
 {
  $_[0]{paragraph}='=' x ($_[0]{headlineLevel}+1);
 }

sub end_item_text     {$_[0]->emit_par(-2);}

# tag support - possibly we need to add S<>, but I am not sure
sub start_B {$_[0]{paragraph}.='\B<';}
sub start_C {$_[0]{paragraph}.='\C<';}
sub start_F {$_[0]{paragraph}.='\C<';}
sub start_I {$_[0]{paragraph}.='\I<';}
sub start_X {$_[0]{paragraph}.='\X{mode=index_only}<';}

sub start_L
 {
  # get attributes
  my ($me, $attribs)=@_;

  # do we support the link type?
  if ($attribs->{type} eq 'url')
    {
     # get target and guard special characters
     (my $target=$attribs->{to})=~s/([=\"])/\\$1/g;

     # prepare the link
     $_[0]{paragraph}.=qq(\\L{url="$target"}<);

     # mark that the link type is supported
     push(@{$me->{lstack}}, 1);
    }
  elsif ($attribs->{type} eq 'pod' and not defined $attribs->{to} and $attribs->{section})
    {
     # get target and guard special characters
     (my $target=$attribs->{section})=~s/([=\"])/\\$1/g;

     # prepare the link
     $_[0]{paragraph}.=qq(\\REF{type=linked occasion=1 name="$target"}<);

     # mark that the link type is supported
     push(@{$me->{lstack}}, 1);
    }
  else
    {
     # currently unsupported link - mark this
     push(@{$me->{lstack}}, 0);
    }
 }

sub end_L  {$_[0]{paragraph}.='>' if pop(@{$_[0]{lstack}});}


# all tags are completed by a ">"
sub endTag  {$_[0]{paragraph}.='>';}

*end_B=\&endTag;
*end_C=\&endTag;
*end_F=\&endTag;
*end_I=\&endTag;
*end_X=\&endTag;


sub start_for
 {
  # flag that we are in a target section
  $_[0]{perlpoint}=1;
 }

sub end_for
 {
  # flag that the target section is complete
  $_[0]{perlpoint}=0;
 }


# present what we collected (paragraph flush, used for most paragraph types)
sub emit_par
 {
  # get object
  my $me=$_[0];

  # character translation copied from Pod::Simple::Text ...
  $me->{paragraph}=~tr{\xAD}{}d if Pod::Simple::ASCII;

  # add a newline, perform further translation
  my $out=$me->{paragraph}.="\n";
  $out=~tr{\xA0}{ } if Pod::Simple::ASCII;

  # flush
  print {$me->{output_fh}} $out, "\n";

  # reset internal buffer
  $me->{paragraph}='';
 }


# verbatim paragraphs: we only need to transform them into "here documents"
sub start_Verbatim
 {
  # start "here document" (EOVPPB=end of verbatim PerlPoint block)
  $_[0]{paragraph}="<<___EOVPPB__\n\n";

  # flag that we are within a verbatim paragraph
  $_[0]{verbatimFlag}=1;
 }

sub end_Verbatim
 {
  # get object
  my $me=shift;

  # flag that the verbatim paragraph is complete
  $me->{verbatimFlag}=0;

  # character translation copied from Pod::Simple::Text ...
  if(Pod::Simple::ASCII)
    {
     $me->{paragraph}=~tr{\xA0}{ };
     $me->{paragraph}=~tr{\xAD}{}d;
    }

  # flush
  print {$me->{output_fh}} '', $me->{paragraph}, "\n\n___EOVPPB__\n\n";

  # reset internal buffer
  $me->{paragraph}='';
}


# flag successful loading
1;




# = POD TRAILER SECTION =================================================================

=pod

=head1 NOTES


=head2 Nested lists

List nesting is I<not> transformed by this version. This means that the list points
are translated, but without taking care of possibly nested levels.


=head2 Text list entries

POD knows text lists, which are made hyperlink anchors implicitly. To reflect this
best, C<Pod::PerlPoint> transforms them into I<subchapters>.


=head2 Hyperlink support

The C<L> tag has several special meanings in POD, see L<perlpodspec>. Especially you
can link into other POD documents, even by section. Contrary to this, other POD sources
are unknown when a translation into PerlPoint is processed.

So currently C<Pod::Perlpoint> only supports two types of hypelinks:

=over 4

=item Hyperlinks to external addresses

Example:

 L<http://use.perl.org>

Such a link is transformed using PerlPoints C<\L> tag.

  \L{url="http://use.perl.org"}<http://use.perl.org>

=item Links to other sections of the same document

Example:

 L</Section>

Such a link us transformed using PerlPoints C<\REF> tag. In case the POD author
used an invalid link, the generated links is made optional.

  \REF{type=linked occasion=1 name="Section"}<"Section">



=head2 PerlPoint parser version and variable $__pod2pp__empty__

Unless C<configure> is called with C<parser40> set to a true value, a PerlPoint variable
C<$__pod2pp__empty__> is used to start text paragraphs with, to avoid
conflicts caused by startup characters that are special to PerlPoint, but just text in POD.

It is assumed that this variable is not used elsewhere. The generated PerlPoint unsets
it to make sure it is really empty.

PerlPoint parsers 0.40 and above support I<dotted text paragraphs> to safe generated texts.
Please call C<configure> with C<parser40> set to a true value before you process your sources
by C<parse_file()> etc.

Please upgrade to C<PerlPoint::Package> 0.40 or better, if possible.


=head2 POD index Tag

The POD index tag C<X> is supported and translated into its PerlPoint equivalent, C<\X>.


=head2 Embedded PerlPoint

PerlPoint embedded into the POD source is automatically processed when using the
C<=for perlpoint> or C<=begin perlpoint>/C<=end perlpoint> syntax.

  A I<POD> text.

  =for perlpoint
  A \I<PerlPoint> text!

  This is B<POD> again.

  =begin perlpoint

  Now for a \B<PerlPoint> example:

   $r=\I<10+20>;

  And a table:

  @|
  column 1 | column 2
  cell 1   | cell 2
  cell 3   | cell 4

  =end perlpoint



=head1 Credits

This module is strongly based on Pod::Simple::Text. Thanks to its author
Sean M. Burke.

=head1 SEE ALSO

=over 4

=item B<Pod::Simple>

The module that made it easy to write C<Pod::PerlPoint> on base of it.

=item B<Bundle::PerlPoint>

A bundle of packages to deal with PerlPoint documents.

=item B<pod2pp>

A POD to PerlPoint translator, distributed and installed with this module.

=item B<pp2pod>

A PerlPoint to POD translator that comes with C<PerlPoint::Package>.


=back


=head1 SUPPORT

A PerlPoint mailing list is set up to discuss usage, ideas,
bugs, suggestions and translator development. To subscribe,
please send an empty message to perlpoint-subscribe@perl.org.

If you prefer, you can contact me via perl@jochen-stenzel.de
as well.


=head1 AUTHOR

Copyright (c) Jochen Stenzel (perl@jochen-stenzel.de), 2002.
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

