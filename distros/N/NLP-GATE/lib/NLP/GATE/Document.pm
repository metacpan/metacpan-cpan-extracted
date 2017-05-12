package NLP::GATE::Document;

use warnings;
use strict;
use Carp;

use XML::Writer;
use XML::LibXML;

use NLP::GATE::Annotation;
use NLP::GATE::AnnotationSet;

=head1 NAME

NLP::GATE::Document - Class for manipulating GATE-like documents

=head1 VERSION

Version 0.6

=cut

our $VERSION = '0.6';

=head1 SYNOPSIS

  use NLP::GATE::Document;
  my $doc = NLP::GATE::Document->new();
  $doc->setText($text);
  $doc->setFeature($name,"featvalue");
  $doc->setFeatureType($name,$type);
  $annset = $doc->getAnnotationSet($setname);
  $doc->setAnnotationSet($set,$setname);
  $feature = $doc->getFeature($name);
  $type = $doc->getFeatureType($name);
  $xml = $doc->toXML();
  $doc->fromXMLFile($filename);
  $doc->fromXML($string);

=head1 DESCRIPTION

This is a simple class representing a document with annotations and
features similar to how documents are represented in GATE.
The class can produce a string representation of the document that
is in XML format and should be readable by GATE.

All setter functions return the original Document object.

=head1 METHODS

=head2 new()

Create a new document. Currently only can be used without parameters
and will always create a new empty document.

=cut

sub new {
  my $class = shift;
  my $self = bless {
    text => "",
    annotationsets => {},
    features => {},
    featuretypes => {},
    }, ref($class) || $class;
  $self->{annotationsets}->{""} = NLP::GATE::AnnotationSet->new();
  return $self;
}

=head2 setText($text)

Set the text of the document. Note that annotations will remain unchanged
unless you explicitly remove them (see setAnnotation) and might point to
non-existing or incorrect text after the text is changed.

=cut

sub setText {
  my $self = shift;
  my $text = shift;
  $self->{text} = $text;
  return $self;
}

=head2 appendText($theText)

Append text to the current text content of the document.
In scalar context, returns the document object.
In array context, returns the from and to offsets of the
newly added text. This can be used to add annotations
for that text snipped more easily.

=cut

sub appendText {
  my $self = shift;
  my $text = shift;
  my $from = length($self->{text});
  my $to = $from + length($text);
  $self->{text} .= $text;
  if(wantarray) {
    return ($from,$to);
  } else {
    return $self;
  }
}

=head2 getText()

Get the plain text of the document.

=cut

sub getText {
  my $self = shift;
  return $self->{text} || "";
}

=head2 getTextForAnnotation($annotation)

Get the text spanned by the given annotation

TODO: no sanity checks yet!

=cut
sub getTextForAnnotation {
  my $self = shift;
  my $ann = shift;
  return substr($self->{text},$ann->getFrom(),$ann->getTo()-$ann->getFrom());
}

=head2 getAnnotationSet ($name)

Return the annotation set with that name. Return undef
if no set with such a name is found.

This is more straightforward than the original Java implementation in GATE:
passing an empty string or undef as $name will return the default
annotation set.

=cut
sub getAnnotationSet {
  my $self = shift;
  my $setname = shift || "";
  return $self->{annotationsets}->{$setname};
}


=head2 getAnnotationSetNames

Return a list of known annotation set names. This will include an entry that is the empty string
that stands for the default annotation set.

=cut
sub getAnnotationSetNames {
  my $self = shift;
  return keys %{$self->{annotationsets}};
}

=head2 setAnnotationSet ($set[,$name])

Store the annotation set object with the document under the given
annotation set name. If the name is the empty string or undef, the
default annotation set is stored or replaced.
Any existing annotation set with that name will be destroyed (unless the
object to replace it is the original set object).

=cut
sub setAnnotationSet {
  my $self = shift;
  my $set = shift;
  my $name = shift || "";
  croak "Expected a NLP::GATE::AnnotationSet for setAnnotationSet, got ",(ref $set) unless(ref $set eq "NLP::GATE::AnnotationSet");
  $self->{annotationsets}->{$name} = $set;
  return $self;
}

=head2 setFeature($name,$value)

Add or replace the document feature of the given name with the new
value.
Make sure you at least add the usual GATE standard features to a document:

   setFeature('gate.SourceURL','created from String');

=cut

sub setFeature {
  my $self = shift;
  my $name = shift;
  my $value = shift;
  $self->{features}->{$name} = $value;
  return $self;
}

=head2 getFeature($name)

Return the value of the document feature with that name.

=cut

sub getFeature {
  my $self = shift;
  my $name = shift;
  return $self->{features}->{$name};
}

=head2 setFeatureType($name,$type)

Set the Java type for the feature.

=cut

sub setFeatureType {
  my $self = shift;
  my $name = shift;
  my $type = shift;
  $self->{featuretypes}->{$name} = $type;
  return $self;
}

=head2 getFeatureType($name)

Return the Java type for a feature. If the type has never been set,
the default is java.lang.String.

=cut

sub getFeatureType {
  my $self = shift;
  my $name = shift;
  return $self->{featuretypes}->{$name} || "java.lang.String";
}


=head2 fromXMLFile($filename)

Read a GATE document from an XML file.
All content of the current object, including features, annotations and
text is discarded.

=cut

sub fromXMLFile {
  my $self = shift;
  my $filepath = shift;
  my $parser = XML::LibXML->new();
  _setParserOptions($parser);
  my $doc = undef;
  ## the parse_file method outputs a very strange error message when the file is
  ## not found - therefore we catch all errors and add a little note just to make
  ## sure the user checks this possible cause.
  eval {
    $doc = $parser->parse_file( $filepath );
  };
  if ($@) {
    croak "Got the following error when trying to parse $filepath: $@\n(Make sure the file exists!)";
  }
  _parseXML($self,$doc);
  return $self;
}

=head2 fromXML($string)

Read a GATE document from a string that contains a GATE document into the
current object. All previous content of the object is discarded.
The XML string has to be encoded in UTF8 for now.

=cut

sub fromXML {
  my $self = shift;
  my $xml = shift;
  my $parser = XML::LibXML->new();
  _setParserOptions($parser);
  my $doc = $parser->parse_string($xml);
  _parseXML($self,$doc);
  return $self;
}


sub _setParserOptions {
  my $parser = shift;
  $parser->validation(0);
  $parser->recover(0);
  $parser->expand_entities(1);
  $parser->keep_blanks(1);
  $parser->pedantic_parser(1);
  $parser->line_numbers(1);
  $parser->load_ext_dtd(0);
  $parser->complete_attributes(0);
  $parser->expand_xinclude(0);
  $parser->no_network(1);
}

sub _parseXML {
  my $self = shift;
  my $doc = shift;
  my $root = $doc->getDocumentElement();
  ## process the document features
  my $i = 0;
  for my $feature ($doc->findnodes("/GateDocument/GateDocumentFeatures/Feature")) {
    my @n = $feature->findnodes("Name");
    my @v = $feature->findnodes("Value");
    #my @t = $feature->findnodes('Value/@className');
    if(@n && @v) {
      unless(scalar @n == 1) {
        croak "Strange document format: not exactly one Name element for document feature!";
      }
      unless(scalar @v == 1) {
        croak "Strange document format: not exactly one Value element for document feature!";
      }
      my $fname = $n[0]->textContent();
      $self->{features}->{$fname} = $v[0]->textContent();
      $self->{featuretypes}->{$fname} = $v[0]->getAttribute("className");
    }
  }
  ## process the document text and create a map of node ids to text offsets
  my %nodemap = ();
  my $offset = 0;
  my $text = "";
  for my $el ($doc->findnodes("/GateDocument/TextWithNodes")) {
    foreach my $c ($el->childNodes()) {
      if($c->nodeType() == 1) {  # element node
        ## get the attribute id
        my $nodeid = _getAttr($c,"id");
        $nodemap{$nodeid} = $offset;
      } elsif($c->nodeType() == 3 || $c->nodeType() == 4) {
        ## 3: text
        ## 4: cdata
        my $t = $c->textContent();
        $offset += length($t);
        $text .= $t;
      } else {
        croak "Invalid node type encountered: ",$c->nodeType(),"\n";
      }
    }
  }
  $self->{text} = $text;
  ## process the annotation features, replacing node ids with offset information
  for my $annset ($doc->findnodes("/GateDocument/AnnotationSet")) {
    ## figure out the name, then create a new annotation set
    my $name = _getAttr($annset,"Name","");
    my $myannset = NLP::GATE::AnnotationSet->new();

    ## find all the annotations in that annotation set
    for my $ann ($annset->findnodes("Annotation")) {
      # get attributes Id, Type, StartNode, EndNode
      my $annId = _getAttr($ann,"Id");
      my $annType = _getAttr($ann,"Type");
      my $annStartNode = _getAttr($ann,"StartNode");
      my $annEndNode = _getAttr($ann,"EndNode");
      my $from = $nodemap{$annStartNode};
      my $to   = $nodemap{$annEndNode};
      my $myann = NLP::GATE::Annotation->new($annType,$from,$to);
      for my $feature ($ann->findnodes("Feature")) {
        my @n = $feature->findnodes("Name");
        my @v = $feature->findnodes("Value");
        my @t = $feature->findnodes('Value/@className');
        if(@n && @v) {
          unless(scalar @n == 1) {
            croak "Strange document format: not exactly one Name element for document feature!";
          }
          unless(scalar @v == 1) {
            croak "Strange document format: not exactly one Value element for document feature!";
          }
          my $fname = $n[0]->textContent();
          $myann->setFeature($fname,$v[0]->textContent());
          $myann->setFeatureType($fname,$v[0]->getAttribute("className"));
        }
      } # for feature
      $myannset->add($myann);
    } # for ann
    $self->{annotationsets}->{$name} = $myannset;
  } # for annset

}

sub _getAttr {
  ## TODO: use node->getAttribute(name) instead!
  my $el = shift;
  my $attrname = shift;
  my $default = shift;
  my $val = $el->getAttribute($attrname);
  if(defined($val)) {
    return $val;
  } elsif(defined($default)) {
    return $default;
  } else {
    croak "Attribute $attrname not found in element ",$el->toString()," and no default";
  }
}



=head2 toXML()

Create an actual XML representation that can be used by GATE from the internal
representation of the document.

=cut

sub toXML {
  my $self = shift;
  my $ret = "";
  my $xml = new XML::Writer(OUTPUT => \$ret, ENCODING => "utf-8");
  $xml->xmlDecl();
  $xml->startTag("GateDocument");
  $ret .= "\n";
  $xml->comment("The document's features");
  $ret .= "\n";
  $xml->startTag("GateDocumentFeatures");
  $ret .= "\n";
  _outputFeatures($xml,$self->{features},$self->{featuretypes},\$ret);
  $xml->endTag("GateDocumentFeatures");
  $ret .= "\n";
  $xml->comment("The document content area with serialized nodes");
  $ret .= "\n";
  $xml->startTag("TextWithNodes");
  # $ret .= "\n";
  my @offsets = $self->_getOffsets();
  my $lastoffset = 0;
  foreach my $offset ( @offsets ) {
    # is there any text between the last node and this one?
    if($lastoffset < $offset) {
      $xml->characters($self->_getText($lastoffset,$offset));
      $lastoffset = $offset;
    }
    $xml->emptyTag("Node",'id' => $offset);
  }
  ## if there is text after the last node, output it too
  if($lastoffset < length($self->{text})) {
    $xml->characters($self->_getText($lastoffset,length($self->{text})));
  }
  $xml->endTag("TextWithNodes");
  $ret .= "\n";
  # the default annotation set is always there

  # use a unique id for all annotations over all sets
  my $annid = 0;
  $xml->comment("The default annotation set");
  $ret .= "\n";
  $xml->startTag("AnnotationSet");
  $ret .= "\n";
  foreach my $ann ( @{$self->{annotationsets}->{""}->_getArrayRef()} ) {
    $xml->startTag("Annotation",
      'Id' => $annid,
      'Type' => $ann->getType(),
      'StartNode' => $ann->getFrom(),
      'EndNode' => $ann->getTo()
      );
    $ret .= "\n";
    _outputFeatures($xml,$ann->_getFeatures(),$ann->_getFeatureTypes(),\$ret);
    $xml->endTag("Annotation");
    $ret .= "\n";
    $annid++;
  }
  $xml->endTag("AnnotationSet");
  $ret .= "\n";
  # optionally, there might be additional named annotation sets
  # these use AnnotationSet with Name="name" attributes
  foreach my $annsetname ( keys %{$self->{annotationsets}} ) {
    next if $annsetname eq "";  # we already have processed the default set
    my $annset = $self->{annotationsets}->{$annsetname};
    $xml->startTag("AnnotationSet", 'Name' => $annsetname);
    $ret .= "\n";
    foreach my $ann ( @{$annset->_getArrayRef()} ) {
      $xml->startTag("Annotation",
        'Id' => $annid,
        'Type' => $ann->getType(),
        'StartNode' => $ann->getFrom(),
        'EndNode' => $ann->getTo()
        );
      $ret .= "\n";
      _outputFeatures($xml,$ann->_getFeatures(),$ann->_getFeatureTypes,\$ret);
      $xml->endTag("Annotation");
      $ret .= "\n";
      $annid++;
    }
    $xml->endTag("AnnotationSet");
    $ret .= "\n";
  }
  $xml->endTag("GateDocument");
  $xml->end();
  return $ret;
}

sub _outputFeatures {
  my $xml = shift;
  my $featurehashref = shift;
  my $featuretypes = shift;
  my $ret = shift;
  $ret = ${$ret};
  foreach my $feature ( keys %{$featurehashref} ) {
    $xml->startTag("Feature");
    $ret .= "\n";
    $xml->startTag("Name",'className' => 'java.lang.String');
    $xml->characters($feature);
    $xml->endTag("Name");
    $xml->startTag("Value",'className' => $featuretypes->{$feature} || "java.lang.String");
    $xml->characters($featurehashref->{$feature});
    $xml->endTag("Value");
    $xml->endTag("Feature");
    $ret .= "\n";
  }
}

## this will generate an array with offsets for all from and
## to offsets needed for the annotations.
sub _getOffsets {
  my $self = shift;
  my %offsets = ();
  # for each annotation set
  foreach my $annset ( keys %{$self->{annotationsets}} ) {
    # for each annotation
    #print STDERR "Annset: $annset\n";
    foreach my $ann ( @{$self->{annotationsets}->{$annset}->_getArrayRef()} ) {
      # add the from and two offsets to the offset hash
      $offsets{$ann->getFrom()} = 1;
      $offsets{$ann->getTo()} = 1;
    }
  }
  # convert the offset hash to an array of offsets
  my @offsets = keys %offsets;
  # sort by offset
  @offsets = sort {$a <=> $b} @offsets;
  # return the array of offsets
  #print "OFFSETS: ",join(",",@offsets),"\n";
  return @offsets;
}

## get the text starting at offset from and going to the character before
## offset to
sub _getText {
  my $self = shift;
  my $from = shift;
  my $to = shift;
  return substr($self->{text},$from,$to-$from);
}
=head1 AUTHOR

Johann Petrak, C<< <firstname.lastname-at-jpetrak-dot-com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-gate-document at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=NLP::GATE>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc NLP::GATE

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/~JOHANNP/NLP-GATE/>

=item * CPAN Ratings

L<http://cpanratings.perl.org/rate/?distribution=NLP-GATE>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=NLP-GATE>

=item * Search CPAN

L<http://search.cpan.org/~johannp/NLP-GATE/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Johann Petrak, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of NLP::GATE::Document
