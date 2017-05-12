=head1 NAME

SVG::Metadata - Perl module to capture metadata info about an SVG file

=head1 SYNOPSIS

 use SVG::Metadata;

 my $svgmeta = new SVG::Metadata;

 $svgmeta->parse($filename)
     or die "Could not parse $filename: " . $svgmeta->errormsg();
 $svgmeta2->parse($filename2)
     or die "Could not parse $filename: " . $svgmeta->errormsg();

 # Do the files have the same metadata (author, title, license)?
 if (! $svgmeta->compare($svgmeta2) ) {
    print "$filename is different than $filename2\n";
 }

 if ($svgmeta->title() eq '') {
     $svgmeta->title('Unknown');
 }

 if ($svgmeta->author() eq '') {
     $svgmeta->author('Unknown');
 }

 if ($svgmeta->license() eq '') {
     $svgmeta->license('Unknown');
 }

 if (! $svgmeta->keywords()) {
     $svgmeta->addKeyword('unsorted');
 } elsif ($svgmeta->hasKeyword('unsorted') && $svgmeta->keywords()>1) {
     $svgmeta->removeKeyword('unsorted');
 }

 print $svgmeta->to_text();

=head1 DESCRIPTION

This module provides a way of extracting, browsing and using RDF
metadata embedded in an SVG file.

The SVG spec itself does not provide any particular mechanisms for
handling metadata, but instead relies on embedded, namespaced RDF
sections, as per XML philosophy.  Unfortunately, many SVG tools don't
support the concept of RDF metadata; indeed many don't support the idea
of embedded XML "islands" at all.  Some will even ignore and drop the
rdf data entirely when encountered.

The motivation for this module is twofold.  First, it provides a
mechanism for accessing this metadata from the SVG files.  Second, it
provides a means of validating SVG files to detect if they have the
metadata.

The motivation for this script is primarily for the Open Clip Art
Library (http://www.openclipart.org), as a way of filtering out
submissions that lack metadata from being included in the official
distributions.  A secondary motivation is to serve as a testing tool for
SVG editors like Inkscape (http://www.inkscape.org).

=head1 FUNCTIONS

=cut

package SVG::Metadata;

use 5.006;
use strict;
use warnings;
use XML::Twig;
use HTML::Entities;

# use Data::Dumper; # DEBUG

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = ();

our $VERSION = '0.28';


use fields qw(
              _title
              _description
              _subject
              _publisher
              _publisher_url
              _creator
              _creator_url
              _owner
              _owner_url
              _license
              _license_date
              _keywords
              _language
              _about_url
              _date
              _retain_xml
              _strict_validation
              _try_harder
              _ERRORMSG
              _RETAINED_XML
              _RETAINED_DECLARATION
              );
use vars qw( %FIELDS $AUTOLOAD );


=head2 new()

Creates a new SVG::Metadata object.  Optionally, can pass in arguments
'title', 'author', 'license', etc..

 my $svgmeta = new SVG::Metadata;
 my $svgmeta = new SVG::Metadata(title=>'My title', author=>'Me', license=>'Public Domain');

=cut

sub new {
    my $class = shift;
    my %args  = @_;

    my $self = bless [\%FIELDS], $class;

    while (my ($field, $value) = each %args) {
        $self->{"_$field"} = $value
            if (exists $FIELDS{"_$field"});
    }
    $self->{_creator}         ||= $args{author} || '';
    $self->{_language}        ||= 'en';
    $self->{_ERRORMSG}          = '';
    $self->{_strict_validation} = 0;

    return $self;
}

# This automatically generates all the accessor functions for %FIELDS
sub AUTOLOAD {
    my $self = shift;
    my $attr = $AUTOLOAD;
    $attr =~ s/.*:://;
    return unless $attr =~ /[^A-Z]/; # skip DESTROY and all-cap methods
    die "Invalid attribute method: ->$attr()\n" unless exists $FIELDS{"_$attr"};
    $self->{"_$attr"} = shift if @_;
    return $self->{"_$attr"};
}

=head2 author()

Alias for creator()

=cut
sub author {
    my $self = shift;
    return $self->creator(@_);
}

=head2 keywords_to_rdf()

Generates an rdf:Bag based on the data structure of keywords.
This can then be used to populate the subject section of the metadata.
I.e.:

    $svgobj->subject($svg->keywords_to_rdf());

See:
  http://www.w3.org/TR/rdf-schema/#ch_bag
  http://www.w3.org/TR/rdf-syntax-grammar/#section-Syntax-list-element
  http://dublincore.org/documents/2002/05/15/dcq-rdf-xml/#sec2

=cut
sub keywords_to_rdf {
    my $self = shift;

    my $text = '';
    foreach my $keyword ($self->keywords()) {
        $keyword = $self->esc_ents($keyword);
        $text .= qq(            <rdf:li>$keyword</rdf:li>\n);
    }

    if ($text ne '') {
        return qq(          <rdf:Bag>\n$text          </rdf:Bag>);
    } else {
        return '';
    }
}


=head2 errormsg()

Returns the last encountered error message.  Most of the error messages
are encountered during file parsing.

    print $svgmeta->errormsg();

=cut

sub errormsg {
    my $self = shift;
    return $self->{_ERRORMSG} || '';
}


=head2 parse($filename)

Extracts RDF metadata out of an existing SVG file.

    $svgmeta->parse($filename) || die "Error: " . $svgmeta->errormsg();

This routine looks for a field in the rdf:RDF section of the document
named 'ns:Work' and then attempts to load the following keys from it:
'dc:title', 'dc:rights'->'ns:Agent', and 'ns:license'.  If any are
missing, it

The $filename parameter can be a filename, or a text string containing
the XML to parse, or an open 'IO::Handle', or a URL.

Returns false if there was a problem parsing the file, and sets an
error message appropriately.  The conditions under which it will return
false are as follows:

   * No 'filename' parameter given.
   * Filename does not exist.
   * Document is not parseable XML.
   * No rdf:RDF element was found in the document, and the try harder
     option was not set.
   * The rdf:RDF element did not have a ns:Work sub-element, and the
     try_harder option was not set.
   * Strict validation mode was turned on, and the document didn't
     strictly comply with one or more of its extra criteria.

=cut

sub parse {
    my ($self, $filename, %optn) = @_;
    my $retaindecl;

    # For backward-compatibility, support retain_xml as an option here:
    if ($optn{retain_xml})        { $self->retain_xml($optn{retain_xml}); }

    if (! defined($filename)) {
        $self->{_ERRORMSG} = "No filename or text argument defined for parsing";
        return;
    }

    my $twig = XML::Twig->new( map_xmlns => {
                                'http://www.w3.org/2000/svg' => "svg", # W3C's SVG namespace
                                'http://www.w3.org/1999/02/22-rdf-syntax-ns#' => "rdf", # W3C's metadata namespace
                                'http://purl.org/dc/elements/1.1/' => "dc", # Dublin Core metadata namespace
                                'http://web.resource.org/cc/' => "cc",      # a license description namespace
                                },
                               pretty_print => 'indented',
                               comments     => 'keep',
                               pi           => 'keep',
                               keep_original_prefix => 1, # prevents superfluous svg:element prefixing.
                             );

    if ($filename =~ m/\n.*\n/ || (ref $filename eq 'IO::Handle')) {
        # Hmm, if it has newlines, it is likely to be a string instead of a filename
        eval { $twig->parse($filename); };
        if ($@) { $self->{_ERRORMSG} = "XML::Twig died; this may mean invalid XML."; return; }
        if ($self->{_retain_xml}) {
          ($retaindecl) = $filename =~ /(.*?)(<svg|<!-- |$)/is; # an inexact science
        }
    } elsif ($filename =~ /^http/ or $filename =~ /^ftp/) {
        eval { $twig->parseurl($filename); };
        if ($@) { $self->{_ERRORMSG} = "XML::Twig died; this may mean invalid XML."; return; }
        if ($self->{_retain_xml}) {
          open XML, '<', $filename; local $/ = '<svg';
          my $content = <XML>; close XML;
          ($retaindecl) = $content =~ /(.*?)(<svg|<!-- |$)/is; # an inexact science
        }
    } elsif (! -e $filename) {
        $self->{_ERRORMSG} = "Filename '$filename' does not exist"; return;
    } else {
        eval { $twig->parsefile($filename); };
        if ($@) { $self->{_ERRORMSG} = "XML::Twig died; this may mean invalid XML."; return; }
        if ($self->{_retain_xml}) {
          open SVGIN, '<', $filename;
          local $/ = '<svg'; my $raw = <SVGIN>; close SVGIN;
          ($retaindecl) = $raw =~ /(.*?)(<svg|<!-- |$)/is; # an inexact science
        }
    }

    if ($@) {
        $self->{_ERRORMSG} = "Error parsing file:  $@";
        return;
    }

    if (not ref $twig) {
        $self->{_ERRORMSG} = "XML::Twig did not return a valid XML object";
        return;
    }
    # If we get this far, we should return a valid object if try_harder is set.

    my $rdf;
    my $metadata = $twig->root()->first_descendant('metadata') # preferred
                || $twig->root()->first_descendant('svg:metadata');  # deprecated
    if (ref $metadata) {
        # This is the preferred way, as the rfd SHOULD be within a metadata element.
        $rdf = $metadata->first_descendant('rdf:RDF') || # preferred
               $metadata->first_descendant('RDF') ||     # mildly deprecated
               $metadata->first_descendant('rdf');       # mildly deprecated
    } else {
        # But in non-strict mode we try a little harder:
        $rdf = $twig->root()->first_descendant('rdf:RDF') || # deprecated
               $twig->root()->first_descendant('RDF')     || # very deprecated
               $twig->root()->first_descendant('rdf');       # very deprecated
    }
    if (not ref $rdf) {
      $self->{_ERRORMSG} = "No 'RDF' element found in " .
        ((defined $metadata) ? "metadata element" : "document") . ".";
      return unless $self->{_try_harder};
      $rdf = $twig->root();
    } elsif ($self->{_strict_validation} and not ref $metadata) {
      $self->{_ERRORMSG} = "'RDF' element not contained in a <metadata></metadata> block";
      return unless $self->{_try_harder}; # undefined behavior, may change
    }

    my $work = $rdf->first_descendant('cc:Work') || # preferred
               $rdf->first_descendant('Work');      # also okay, I think
    if (! defined($work)) {
        $self->{_ERRORMSG} = "No 'Work' element found in the 'RDF' element";
        return unless $self->{_try_harder};
        $work = $rdf;
    }

    my $getagent = sub {
      my ($elt) = shift; return unless ref $elt;
      return $elt->first_descendant('cc:Agent') # preferred
         ||  $elt->first_descendant('Agent')    # also okay, I think
         ||  $elt; # and we treat the Agent wrapper as optional
    };
    my $getthingandurl = sub {
      my ($thing, $elt, $thingdefault, $urldefault) = @_;
      $thingdefault ||= ''; $urldefault ||= '';
      $self->{'_'.$thing} = $thingdefault;
      $self->{'_'.$thing.'_url'} = $urldefault;

      if (ref $elt) {
          my $agent = $getagent->($elt);
          my $title = $agent->first_descendant('dc:title') # preferred
                   || $agent->first_descendant('title');   # also okay, I think
          my $about = $agent->att('rdf:about') # preferred
                   || $agent->att('about');    # deprecated
          $self->{'_'.$thing}        = (ref $title) ? $title->text() : $thingdefault;
          $self->{'_'.$thing.'_url'} = ($about)     ? $about         : $urldefault;
        }
    };

    $getthingandurl->('publisher', $work->first_descendant('dc:publisher'),
                      # With defaults:
                      'Open Clip Art Library', 'http://www.openclipart.org/');
    $getthingandurl->('creator', $work->first_descendant('dc:creator'));
    $getthingandurl->('owner', $work->first_descendant('dc:rights'));

    $self->{_title}         = _get_content($work->first_descendant('dc:title')) || '';
    $self->{_description}   = _get_content($work->first_descendant('dc:description')) || '';
    my $license = $work->first_descendant('cc:license');
    if (ref $license) {
      $self->{_license}      = _get_content($license->first_descendant('rdf:resource'))
                               || $license->att('rdf:resource') || '';
      $self->{_license_date} = _get_content($license->first_descendant('dc:date')) || '';
    }
    $self->{_language}      = _get_content($work->first_descendant('dc:language')) || 'en';
    $self->{_about_url}     = $work->att('rdf:about') || '';
    $self->{_date}          = _get_content($work->first_descendant('dc:date')) || '';

    # If only one of creator or owner is defined, default the other to match:
    $self->{_creator}       ||= $self->{_owner};
    $self->{_creator_url}   ||= $self->{_owner_url};
    $self->{_owner}         ||= $self->{_creator};
    $self->{_owner_url}     ||= $self->{_creator_url};

    if ($self->{_retain_xml}) {
      $self->{_RETAINED_XML} = \$twig; # Keep the actual SVG around.  (to_svg is worthless without this.)
      $self->{_RETAINED_DECLARATION} = $retaindecl || ''; # and the XML declaration (and possibly also the doctype)
    }

    my $subject = $work->first_descendant('dc:subject');
    if (ref $subject) {
      my @keyword = $subject->descendants('rdf:li');
      # rdf:li elements are strongly preferred, and they should be wrapped in rdf:Bag
      # But if that returns nothing, we try harder:
      if (not @keyword) {
        push @keyword, grep { $_ }               # (Throw out empty keywords.)
                         split /(?:(?![-])\W)*/, # (Split on non-word chars *except* hyphen)
                           $subject->text();     # But this is a last resort, very deprecated.
      }
      my @keywordtext = map { $_->text() } @keyword;
      $self->{_subject} = +{ map { $_ => 1 } @keywordtext }; # We *could* also map a split here...
    }
    if (not keys %{$self->{_subject}}) {
      $self->{_subject} = { unsorted => 1 };
    } elsif (keys %{$self->{_subject}} > 1 and exists $self->{_subject}->{unsorted}) {
      delete ($self->{_subject}->{unsorted});
    }
    $self->{_keywords} = $self->{_subject}; # to_rdf() rebuilds _subject from _keywords
    undef $self->{_subject}; # The POD for subject() says we do this.

    return $self; # references are always true in boolean context
}

# XML::Twig::simplify has a bug where it only accepts "forcecontent", but
# the option to do that function is actually recognized as "force_content".
# As a result, we have to test to see if we're at a HASH node or a scalar.
sub _get_content {
    my ($content)=@_;

    if (UNIVERSAL::isa($content,"HASH")
        && exists($content->{'content'})) {
        return $content->{'content'};
      } elsif (ref $content) {
        return $content->text();
      } else {
        return $content;
    }
}

=head2 title()

Gets or sets the title.

    $svgmeta->title('My Title');
    print $svgmeta->title();

=head2 description()

Gets or sets the description

=head2 subject()

Gets or sets the subject.  Note that the parse() routine pulls the
keywords out of the subject and places them in the keywords
collection, so subject() will normally return undef.  If you assign to
subject() it will override the internal keywords() mechanism, but this
may later be discarded again in favor of the keywords, if to_rdf() is
called, either directly or indirectly via to_svg().

=head2 publisher()

Gets or sets the publisher name.  E.g., 'Open Clip Art Library'

=head2 publisher_url()

Gets or sets the web URL for the publisher.  E.g., 'http://www.openclipart.org'

=head2 creator()

Gets or sets the creator.

    $svgmeta->creator('Bris Geek');
    print $svgmeta->creator();

=head2 creator_url()

Gets or sets the URL for the creator.

=head2 author()

Alias for creator() - does the same thing

    $svgmeta->author('Bris Geek');
    print $svgmeta->author();

=head2 owner()

Gets or sets the owner.

    $svgmeta->owner('Bris Geek');
    print $svgmeta->owner();

=head2 owner_url()

Gets or sets the owner URL for the item

=head2 license()

Gets or sets the license.

    $svgmeta->license('Public Domain');
    print $svgmeta->license();

=head2 license_date()

Gets or sets the date that the item was licensed

=head2 language()

Gets or sets the language for the metadata.  This should be in the
two-letter lettercodes, such as 'en', etc.

=head2 retain_xml()

Gets or sets the XML retention option, which (if true) will cause any
subsequent call to parse() to retain the XML.  You have to turn this
on if you want to_svg() to work later.

=head2 strict_validation()

Gets or sets the strict validation option, which (if true) will cause
subsequent calls to parse() to be pickier about how things are
structured and possibly set an error and return undef when it
otherwise would succeed.

=head2 try_harder()

Gets or sets the try harder option option, which causes subsequent
calls to parse() to try to return a valid Metadata object even if it
can't find any metadata at all.  The resulting object may contain
mostly empty fields.

Parse will still fail and return undef if the input file does not
exist or cannot be parsed as XML, but otherwise it will attempt to
return an object.

If you set both this option and the strict validation option at the
same time, the Undefined Behavior Fairy will come and zap you with a
frap ray blaster and take away your cookie.

=head2 keywords()

Gets or sets an array of keywords.  Keywords are a categorization
mechanism, and can be used, for example, to sort the files topically.

=cut

sub keywords {
    my $self = shift;
    if (@_) {
        $self->addKeyword(@_);
    }
    return undef unless defined($self->{_keywords});

    # warn Dumper(+{ _keywords => $self->{_keywords}}); # DEBUG

    return keys %{$self->{_keywords}};
}


=head2 addKeyword($kw1 [, $kw2 ...])

Adds one or more a new keywords.  Note that the keywords are stored
internally as a set, so only one copy of a given keyword will be stored.

    $svgmeta->addKeyword('Fruits and Vegetables');
    $svgmeta->addKeyword('Fruit','Vegetable','Animal','Mineral');

=cut

sub addKeyword {
    my $self = shift;
    foreach my $new_keyword (@_) {
        $self->{_keywords}->{$new_keyword} = 1;
    }
}


=head2 removeKeyword($kw)

Removes a given keyword

    $svgmeta->removeKeyword('Fruits and Vegetables');

Return value:  The keyword removed.

=cut

sub removeKeyword {
    my $self = shift;
    my $keyword = shift || return;

    return delete $self->{_keywords}->{$keyword};
}


=head2 hasKeyword($kw)

Returns true if the metadata includes the given keyword

=cut

sub hasKeyword {
    my $self = shift;
    my $keyword = shift || return 0;

    return 0 unless defined($self->{_keywords});

    return (defined($self->{_keywords}->{$keyword}));
}

=head2 compare($meta2)

Compares this metadata to another metadata for equality.

Two SVG file metadata objects are considered equivalent if they
have exactly the same author, title, and license.  Keywords can
vary, as can the SVG file itself.

=cut

sub compare {
    my $self = shift;
    my $meta = shift;

    return ( $meta->author() eq $self->author() &&
             $meta->title() eq $self->title() &&
             $meta->license() eq $self->license()
             );
}


=head2 to_text()

Creates a plain text representation of the metadata, suitable for
debuggery, emails, etc.  Example output:

 Title:    SVG Road Signs
 Author:   John Cliff
 License:  http://web.resource.org/cc/PublicDomain
 Keywords: unsorted

Return value is a string containing the title, author, license, and
keywords, each value on a separate line.  The text always ends with
a newline character.

=cut

sub to_text {
    my $self = shift;

    my $text = '';
    $text .= 'Title:    ' . ($self->title()||'') . "\n";
    $text .= 'Author:   ' . ($self->author()||'') . "\n";
    $text .= 'License:  ' . ($self->license()||'') . "\n";
    $text .= 'Keywords: ';
    $text .= join("\n          ", $self->keywords());
    $text .= "\n";

    return $text;
}

=head2 esc_ents($text)

Escapes '<', '>', and '&' and single and double quote
characters to avoid causing rdf to become invalid.

=cut

sub esc_ents {
    my $self = shift;
    my $text = shift;
    return $text unless $text;

    return encode_entities($text, qq(<>&"'));
}

=head2 to_rdf()

Generates an RDF snippet to describe the item.  This includes the
author, title, license, etc.  The text always ends with a newline
character.

=cut

sub to_rdf {
    my $self = shift;

    my $about_url     = $self->esc_ents($self->about_url())       || '';
    my $title         = $self->esc_ents($self->title())           || '';
    my $creator       = $self->esc_ents($self->creator())         || '';
    my $creator_url   = $self->esc_ents($self->creator_url())     || '';
    my $owner         = $self->esc_ents($self->owner())           || '';
    my $owner_url     = $self->esc_ents($self->owner_url())       || '';
    my $date          = $self->esc_ents($self->date())            || '';
    my $license       = $self->esc_ents($self->license())         || '';
    my $license_date  = $self->esc_ents($self->license_date())    || '';
    my $description   = $self->esc_ents($self->description())     || '';
    my $subject       = $self->keywords_to_rdf()                  || '';
    my $publisher     = $self->esc_ents($self->publisher())       || '';
    my $publisher_url = $self->esc_ents($self->publisher_url())   || '';
    my $language      = $self->esc_ents($self->language())        || 'en';

    my $license_rdf   = '';
    if ($license eq 'Public Domain'
        or $license eq 'http://web.resource.org/cc/PublicDomain') {
        $license = "http://web.resource.org/cc/PublicDomain";
        $license_rdf = qq(
      <License rdf:about="$license">
         <permits rdf:resource="http://web.resource.org/cc/Reproduction" />
         <permits rdf:resource="http://web.resource.org/cc/Distribution" />
         <permits rdf:resource="http://web.resource.org/cc/DerivativeWorks" />
      </License>
);
    } elsif ($license eq 'http://creativecommons.org/licenses/by-nc-nd/2.0/') {
        $license_rdf = qq(
     <License rdf:about="http://creativecommons.org/licenses/by-nc-nd/2.0/">
          <permits rdf:resource="http://web.resource.org/cc/Reproduction" />
          <permits rdf:resource="http://web.resource.org/cc/Distribution" />
          <requires rdf:resource="http://web.resource.org/cc/Notice" />
          <requires rdf:resource="http://web.resource.org/cc/Attribution" />
          <prohibits rdf:resource="http://web.resource.org/cc/CommercialUse" />
     </License>
);
    } elsif ($license eq 'http://creativecommons.org/licenses/by/2.0/') {
        $license_rdf = qq(
     <License rdf:about="http://creativecommons.org/licenses/by/2.0/">
          <permits rdf:resource="http://web.resource.org/cc/Reproduction" />
          <permits rdf:resource="http://web.resource.org/cc/Distribution" />
          <requires rdf:resource="http://web.resource.org/cc/Notice" />
          <requires rdf:resource="http://web.resource.org/cc/Attribution" />
          <permits rdf:resource="http://web.resource.org/cc/DerivativeWorks" />
     </License>
);
    } elsif ($license eq 'http://creativecommons.org/licenses/by-nc/2.0/') {
        $license_rdf = qq(
     <License rdf:about="http://creativecommons.org/licenses/by-nc/2.0/">
          <permits rdf:resource="http://web.resource.org/cc/Reproduction" />
          <permits rdf:resource="http://web.resource.org/cc/Distribution" />
          <requires rdf:resource="http://web.resource.org/cc/Notice" />
          <requires rdf:resource="http://web.resource.org/cc/Attribution" />
          <prohibits rdf:resource="http://web.resource.org/cc/CommercialUse" />
          <permits rdf:resource="http://web.resource.org/cc/DerivativeWorks" />
     </License>
);
    } elsif ($license eq 'http://creativecommons.org/licenses/by-nd/2.0/') {
        $license_rdf = qq(
     <License rdf:about="http://creativecommons.org/licenses/by-nd/2.0/">
          <permits rdf:resource="http://web.resource.org/cc/Reproduction" />
          <permits rdf:resource="http://web.resource.org/cc/Distribution" />
          <requires rdf:resource="http://web.resource.org/cc/Notice" />
          <requires rdf:resource="http://web.resource.org/cc/Attribution" />
     </License>
);
    } elsif ($license eq 'http://creativecommons.org/licenses/by-nc-nd/2.0/') {
        $license_rdf = qq(
     <License rdf:about="http://creativecommons.org/licenses/by-nc-nd/2.0/">
          <permits rdf:resource="http://web.resource.org/cc/Reproduction" />
          <permits rdf:resource="http://web.resource.org/cc/Distribution" />
          <requires rdf:resource="http://web.resource.org/cc/Notice" />
          <requires rdf:resource="http://web.resource.org/cc/Attribution" />
          <prohibits rdf:resource="http://web.resource.org/cc/CommercialUse" />
     </License>
);
    } elsif ($license eq 'http://creativecommons.org/licenses/by-nc-sa/2.0/') {
        $license_rdf = qq(
     <License rdf:about="http://creativecommons.org/licenses/by-nc-sa/2.0/">
          <permits rdf:resource="http://web.resource.org/cc/Reproduction" />
          <permits rdf:resource="http://web.resource.org/cc/Distribution" />
          <requires rdf:resource="http://web.resource.org/cc/Notice" />
          <requires rdf:resource="http://web.resource.org/cc/Attribution" />
          <prohibits rdf:resource="http://web.resource.org/cc/CommercialUse" />
          <permits rdf:resource="http://web.resource.org/cc/DerivativeWorks" />
          <requires rdf:resource="http://web.resource.org/cc/ShareAlike" />
     </License>
);
    } elsif ($license eq 'http://creativecommons.org/licenses/by-sa/2.0/') {
        $license_rdf = qq(
     <License rdf:about="http://creativecommons.org/licenses/by-sa/2.0/">
          <permits rdf:resource="http://web.resource.org/cc/Reproduction" />
          <permits rdf:resource="http://web.resource.org/cc/Distribution" />
          <requires rdf:resource="http://web.resource.org/cc/Notice" />
          <requires rdf:resource="http://web.resource.org/cc/Attribution" />
          <permits rdf:resource="http://web.resource.org/cc/DerivativeWorks" />
          <requires rdf:resource="http://web.resource.org/cc/ShareAlike" />
     </License>
);
    }

    my $pub_data = ($publisher_url ? ' rdf:about="'.$publisher_url.'"' : '');
    my $creator_data = ($creator_url ? ' rdf:about="'.$creator_url.'"' : '');
    my $owner_data = ($owner_url ? ' rdf:about="'.$owner_url.'"' : '');
    return qq(
  <metadata>
    <rdf:RDF
     xmlns="http://web.resource.org/cc/"
     xmlns:dc="http://purl.org/dc/elements/1.1/"
     xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
      <Work rdf:about="$about_url">
        <dc:title>$title</dc:title>
        <dc:description>$description</dc:description>
        <dc:subject>
$subject
        </dc:subject>
        <dc:publisher>
           <Agent$pub_data>
             <dc:title>$publisher</dc:title>
           </Agent>
         </dc:publisher>
         <dc:creator>
           <Agent$creator_data>
             <dc:title>$creator</dc:title>
           </Agent>
        </dc:creator>
         <dc:rights>
           <Agent$owner_data>
             <dc:title>$owner</dc:title>
           </Agent>
        </dc:rights>
        <dc:date>$date</dc:date>
        <dc:format>image/svg+xml</dc:format>
        <dc:type rdf:resource="http://purl.org/dc/dcmitype/StillImage" />
        <license rdf:resource="$license" />
        <dc:language>$language</dc:language>
      </Work>
$license_rdf
    </rdf:RDF>
  </metadata>
);

}

=head2 to_svg()

Returns the SVG with the updated metadata embedded.  This can only be
done if parse() was called with the retain_xml option.  Note that the
code's layout can change a little, especially in terms of whitespace,
but the semantics SHOULD be the same, except for the updated metadata.

=cut

sub to_svg {
  my ($self) = shift;
  if (not $self->{_RETAINED_XML}) {
    $self->{_ERRORMSG} = "Cannot do to_svg because the XML was not retained.  Pass a true value for the retain_xml option to parse to retain the XML, and check the return value of parse to make sure it succeeded.";
    return undef;
  }

  my $xml = ${$self->{_RETAINED_XML}};
  my $metadata = XML::Twig->new(
                                map_xmlns => {
                                              'http://web.resource.org/cc/' => "cc",
                                              'http://www.w3.org/1999/02/22-rdf-syntax-ns#' => "rdf",
                                              'http://purl.org/dc/elements/1.1/' => "dc",
                                             },
                                pretty_print => 'indented',
                               );
  $metadata->parse($self->to_rdf());
  for ($xml->descendants(qr'metadata'),
       $xml->descendants(qr'svg:metadata'),
       # $xml->descendants(qr'rdf:RDF'), # These too?  I'm not sure.   Leaving them for now.
      ) {
    # Out with the old...
    $_->delete() if defined $_;
  }
  # In with the new...
  $metadata->root()->copy();
  $metadata->root()->paste( first_child => $xml->root());
  return $self->{_RETAINED_DECLARATION} . $xml->root()->sprint();
}

1;
__END__

=head1 PREREQUISITES

C<XML::Twig>

=head1 AUTHOR

Bryce Harrington <bryce@bryceharrington.org>

=head1 COPYRIGHT

Copyright (C) 2004 Bryce Harrington.
All Rights Reserved.

This script is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<XML::Twig>

=cut
