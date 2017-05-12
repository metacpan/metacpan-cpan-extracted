package Rinchi::DOM;

use 5.008001;
use strict;
use warnings;
use XML::DOM;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Rinchi::DOM ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

=head1 NAME

Rinchi::DOM - DOM Interface.

=head1 SYNOPSIS

 use Rinchi::DOM;
 use Rinchi::Fortran::Preprocessor;

 my @args = (
   'test.pl',
   '-I/usr/include',
   '-Uccc',
 );

 my $closed = 0;

 my $rd = new Rinchi::DOM;
 my $fpp = new Rinchi::Fortran::Preprocessor;

 my $document = $rd->process_to_DOM($fpp, 'test_src/bisect.f90',\@args);


=head1 DESCRIPTION

This module provides XML::DOM suuport for Rinchi preprocessors.

=head2 EXPORT

None by default.

=head1 METHODS

=over 4

=item new

Constructor for Rinchi::DOM.

=cut

use vars qw( $_RD_document
	     $_RD_cur_node
	     $_RD_cdata_value
	     $_RD_in_cdata
	   );

=item new

Constructor for Rinchi::DOM.

=cut

sub new {
  my ($class, %args) = @_;
  my $self = bless \%args, $class;

  $self;
}

sub _startElementHandler() {
  my ($tagName, $hasChild, %attrs) = @_;
  
  my $elem = $_RD_document->createElement($tagName);
  foreach my $name (sort keys %attrs) {
    $elem->setAttribute($name, $attrs{$name});
  }
  $_RD_cur_node->appendChild($elem);
  $_RD_cur_node = $elem;
}

sub _endElementHandler() {
  my ($tagName) = @_;

  $_RD_cur_node = $_RD_cur_node->getParentNode();
}

sub _characterDataHandler() {
  my ($cdata) = @_;

  if($_RD_in_cdata) {
    $_RD_cdata_value .= $cdata;
  } else {
    my $text = $_RD_document->createTextNode($cdata);
    $_RD_cur_node->appendChild($text);
  }
}

sub _processingInstructionHandler() {
  my ($target,$data) = @_;

  my $pi = $_RD_document->createProcessingInstruction($target, $data);
  $_RD_cur_node->appendChild($pi);
}

sub _commentHandler() {
  my ($string) = @_;

  my $comment = $_RD_document->createComment($string);
  $_RD_cur_node->appendChild($comment);
}

sub _startCdataHandler() {

  $_RD_cdata_value = "";
  $_RD_in_cdata = 1;
}

sub _endCdataHandler() {

  my $cdata = $_RD_document->createCDATASection($_RD_cdata_value);
  $_RD_cur_node->appendChild($cdata);
  $_RD_in_cdata = 0;
}

sub _xmlDeclHandler() {
  my ($version, $encoding, $standalone) = @_;

  my $xmldecl = $_RD_document->createXMLDecl($version, $encoding, $standalone);
  $_RD_document->setXMLDecl($xmldecl);
}

=item sub process_to_DOM($processor, $path, [\@args])

 my $document = $rdom->process_to_DOM($processor, 'some_file.fpp' ,\@args);

Where $processor is as preprocessor such as Rinchi::CPlusPlus::Proprocessor or 
Rinchi::Fortran::Proprocessor, $path is the path to the file to be parsed and 
$args is an optional reference to an array of arguments.

Parse the given file after passing the arguments if given. Print the new source 
to standard output.  

=cut

sub process_to_DOM($$$) {
  my ($self, $pp, $path, $args) = @_;

  $_RD_document = XML::DOM::Document->new();
  $_RD_cur_node = $_RD_document;

  $pp->setHandlers('Start'      => \&_startElementHandler,
                   'End'        => \&_endElementHandler,
                   'Char'       => \&_characterDataHandler,
                   'Proc'       => \&_processingInstructionHandler,
                   'Comment'    => \&_commentHandler,
                   'CdataStart' => \&_startCdataHandler,
                   'CdataEnd'   => \&_endCdataHandler,
                   'XMLDecl'    => \&_xmlDeclHandler,
                  );

  if (defined($args) and ref($args) eq 'ARRAY') {
    $pp->process_file($path,$args);
  } else {
    $pp->process_file($path);
  }

  return $_RD_document;
}

# Preloaded methods go here.

1;
__END__

=head1 SEE ALSO

XML::DOM
Rinchi::CPlusPlus::Preprocessor
Rinchi::Fortran::Preprocessor

=head1 AUTHOR

Brian M. Ames, E<lt>bames@apk.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Brian M. Ames

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
