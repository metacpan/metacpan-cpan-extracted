package Rinchi::Fortran::Preprocessor;

use 5.008001;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Rinchi::Fortran::Preprocessor ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Rinchi::Fortran::Preprocessor', $VERSION);

our %Handler_Setters = (
                    Start => \&SetStartElementHandler,
                    End   => \&SetEndElementHandler,
                    Char  => \&SetCharacterDataHandler,
                    Proc  => \&SetProcessingInstructionHandler,
                    Comment => \&SetCommentHandler,
                    CdataStart => \&SetStartCdataHandler,
                    CdataEnd   => \&SetEndCdataHandler,
                    XMLDecl => \&SetXMLDeclHandler
                    );
my %tagToKeyword = (
  'abstract' => 'ABSTRACT',
  'abstract_interface' => 'ABSTRACT INTERFACE',
  'action' => 'ACTION',
  'advance' => 'ADVANCE',
  'access' => 'ACCESS',
  'allocatable' => 'ALLOCATABLE',
  'allocate' => 'ALLOCATE',
  'assign' => 'ASSIGN',
  'associate' => 'ASSOCIATE',
  'asynchronous' => 'ASYNCHRONOUS',
  'backspace' => 'BACKSPACE',
  'bind' => 'BIND',
  'blank' => 'BLANK',
  'block' => 'BLOCK',
  'block_data' => 'BLOCK DATA',
  'call' => 'CALL',
  'case' => 'CASE',
  'character' => 'CHARACTER',
  'class' => 'CLASS',
  'class_default' => 'CLASS DEFAULT',
  'class_is' => 'CLASS IS',
  'close' => 'CLOSE',
  'common' => 'COMMON',
  'complex' => 'COMPLEX',
  'contains' => 'CONTAINS',
  'contiguous' => 'CONTIGUOUS',
  'continue' => 'CONTINUE',
  'cycle' => 'CYCLE',
  'data' => 'DATA',
  'deallocate' => 'DEALLOCATE',
  'default' => 'DEFAULT',
  'deferred' => 'DEFERRED',
  'dimension' => 'DIMENSION',
  'direct' => 'DIRECT',
  'do' => 'DO',
  'double' => 'DOUBLE',
  'double complex' => 'DOUBLE COMPLEX',
  'double precision' => 'DOUBLE PRECISION',
  'elemental' => 'ELEMENTAL',
  'else' => 'ELSE',
  'else_if' => 'ELSE IF',
  'else_where' => 'ELSE WHERE',
  'end' => 'END',
  'encoding' => 'ENCODING',
  'end_associate' => 'END ASSOCIATE',
  'end_block' => 'END BLOCK',
  'end_block data' => 'END BLOCK DATA',
  'end_do' => 'END DO',
  'end_enum' => 'END ENUM',
  'end_file' => 'END FILE',
  'end_forall' => 'END FORALL',
  'end_function' => 'END FUNCTION',
  'end_if' => 'END IF',
  'end_interface' => 'END INTERFACE',
  'end_module' => 'END MODULE',
  'end_procedure' => 'END PROCEDURE',
  'end_program' => 'END PROGRAM',
  'end_select' => 'END SELECT',
  'end_submodule' => 'END SUBMODULE',
  'end_subroutine' => 'END SUBROUTINE',
  'end_type' => 'END TYPE',
  'end_where' => 'END WHERE',
  'entry' => 'ENTRY',
  'eor' => 'EOR',
  'equivalence' => 'EQUIVALENCE',
  'err' => 'ERR',
  'errmsg' => 'ERRMSG',
  'exist' => 'EXIST',
  'exit' => 'EXIT',
  'extends' => 'EXTENDS',
  'extensible' => 'EXTENSIBLE',
  'external' => 'EXTERNAL',
  'false' => 'FALSE',
  'file' => 'FILE',
  'final' => 'FINAL',
  'flush' => 'FLUSH',
  'fmt' => 'FMT',
  'forall' => 'FORALL',
  'form' => 'FORM',
  'format' => 'FORMAT',
  'formatted' => 'FORMATTED',
  'function' => 'FUNCTION',
  'generic' => 'GENERIC',
  'goto' => 'GOTO',
  'if' => 'IF',
  'implicit' => 'IMPLICIT',
  'implicit_none' => 'IMPLICIT NONE',
  'import' => 'IMPORT',
  'impure' => 'IMPURE',
  'in' => 'IN',
  'in_out' => 'IN OUT',
  'include' => 'INCLUDE',
  'inquire' => 'INQUIRE',
  'integer' => 'INTEGER',
  'intent' => 'INTENT',
  'interface' => 'INTERFACE',
  'intrinsic' => 'INTRINSIC',
  'iostat' => 'IOSTAT',
  'iomsg' => 'IOMSG',
  'kind' => 'KIND',
  'let' => 'LET',
  'logical' => 'LOGICAL',
  'module' => 'MODULE',
  'mold' => 'MOLD',
  'name' => 'NAME',
  'named' => 'NAMED',
  'namelist' => 'NAMELIST',
  'nextrec' => 'NEXTREC',
  'non_intrinsic' => 'NON INTRINSIC',
  'non_overridable' => 'NON OVERRIDABLE',
  'nonkind' => 'NONKIND',
  'none' => 'NONE',
  'nopass' => 'NOPASS',
  'nullify' => 'NULLIFY',
  'number' => 'NUMBER',
  'open' => 'OPEN',
  'opened' => 'OPENED',
  'operator' => 'OPERATOR',
  'optional' => 'OPTIONAL',
  'out' => 'OUT',
  'pad' => 'PAD',
  'parameter' => 'PARAMETER',
  'pass' => 'PASS',
  'pause' => 'PAUSE',
  'pointer' => 'POINTER',
  'position' => 'POSITION',
  'precision' => 'PRECISION',
  'print' => 'PRINT',
  'private' => 'PRIVATE',
  'procedure' => 'PROCEDURE',
  'program' => 'PROGRAM',
  'protected' => 'PROTECTED',
  'public' => 'PUBLIC',
  'pure' => 'PURE',
  'read' => 'READ',
  'read_formatted' => 'READ FORMATTED',
  'read_unformatted' => 'READ UNFORMATTED',
  'read_write' => 'READ WRITE',
  'real' => 'REAL',
  'rec' => 'REC',
  'recl' => 'RECL',
  'return' => 'RETURN',
  'rewind' => 'REWIND',
  'round' => 'ROUND',
  'save' => 'SAVE',
  'select_case' => 'SELECT CASE',
  'select_type' => 'SELECT TYPE',
  'sequence' => 'SEQUENCE',
  'sequential' => 'SEQUENTIAL',
  'sign' => 'SIGN',
  'size' => 'SIZE',
  'source' => 'SOURCE',
  'status' => 'STATUS',
  'stop' => 'STOP',
  'subroutine' => 'SUBROUTINE',
  'target' => 'TARGET',
  'then' => 'THEN',
  'true' => 'TRUE',
  'type' => 'TYPE',
  'unformatted' => 'UNFORMATTED',
  'unit' => 'UNIT',
  'use' => 'USE',
  'value' => 'VALUE',
  'volatile' => 'VOLATILE',
  'where' => 'WHERE',
  'write' => 'WRITE',
  'write_formatted' => 'WRITE FORMATTED',
  'write_unformatted' => 'WRITE UNFORMATTED',
);

my %delimiters = (
  'paren' => ['(', ')'],
  'slash_delim' => ['/', '/'],
  'bracket' => ['[', ']'],
  'paren_slash' => ['(/', '/)'],
);

my %punctuators = (
  'comma' => ',',
  'eq' => '=',
  'colon' => ':',
  'dbl_colon' => '::',
  'eos' => ';',
  'member' =>'%',
  'plus' =>'+',
  'minus' =>'-',
  'ast' =>'*',
  'div' =>'/',
  'power' =>'**',
  'lt' =>'<',
  'gt' =>'>',
);

my $closed;

=head1 NAME

Rinchi::Fortran::Preprocessor - An Fortran to XML preprocessor extension for 
preprocessing Fortran files producing XML SAX parser events for the tokens 
scanned.

=head1 SYNOPSIS

 use Rinchi::Fortran::Preprocessor;

 my @args = (
   'test.pl',
   '-I/usr/include',
   '-Uccc',
 );

 my $closed = 0;

 my $fpp = new Rinchi::Fortran::Preprocessor;
 $fpp->setHandlers('Start'      => \&startElementHandler,
                   'End'        => \&endElementHandler,
                   'Char'       => \&characterDataHandler,
                   'Proc'       => \&processingInstructionHandler,
                   'Comment'    => \&commentHandler,
                   'CdataStart' => \&startCdataHandler,
                   'CdataEnd'   => \&endCdataHandler,
                   'XMLDecl'    => \&xmlDeclHandler,
                   );

 $fpp->process_file('test_src/include_test_1.h',\@args);

 sub startElementHandler() {
   my ($tag, $hasChild, %attrs) = @_;
   print "<$tag";
   foreach my $attr (sort keys %attrs) {
     my $val = $attrs{$attr};
     $val =~ s/&/&amp;/g;
     $val =~ s/</&lt;/g;
     $val =~ s/>/&gt;/g;
     $val =~ s/\"/&quot;/g;
     $val =~ s/\'/&apos;/g;
     print " $attr=\"$val\"";
   }
   if ($hasChild == 0) {
     print " />";
     $closed = 1;
   } else {
     print ">";
     $closed = 0;
   }
 }

 sub endElementHandler() {
   my ($tag) = @_;
   if ($closed == 0) {
     print "</$tag>\n";
   } else {
     $closed = 0;
   }
 }

 sub characterDataHandler() {
   my ($cdata) = @_;
   print $cdata;
 }

 sub processingInstructionHandler() {
   my ($target,$data) = @_;
   print "<?$target $data?>\n";
 }

 sub commentHandler() {
   my ($string) = @_;
   print "<!-- $string -->\n";
 }

 sub startCdataHandler() {
   print "<![CDATA[";
 }

 sub endCdataHandler() {
    print "]]>";
 }

 sub xmlDeclHandler() {
   my ($version, $encoding, $standalone) = @_;
   print "<?xml version=\"$version\" encoding=\"$encoding\" standalone=\"$standalone\"?>\n";
 }

=head1 DESCRIPTION

This module provides an interface to a Fortran preprocessor.

=head2 EXPORT

None by default.

=head1 METHODS

=over 4

=item new

Constructor for Fortran::Preprocessor. Options are TBD.

=cut

sub new {
  my ($class, %args) = @_;
  my $self = bless \%args, $class;
  $args{'_State_'} = 0;
  $args{'Context'} = [];
  $args{'ErrorMessage'} ||= '';
  $args{'_Setters'} = \%Handler_Setters;
#  $args{Parser} = ParserCreate($self, $args{ProtocolEncoding},
#                               $args{Namespaces});
  $self;
}

=item setHandlers(TYPE, HANDLER [, TYPE, HANDLER [...]])

This method registers handlers for the various events.

Setting a handler to something that evaluates to false unsets that
handler.

This method returns a list of type, handler pairs corresponding to the
input. The handlers returned are the ones that were in effect before the
call to setHandlers.

The recognized events and the parameters passed to the corresponding
handlers are:

=over 4

=item * Start             (tagname, hasChild [, attrName, attrValue [,...]])

  my ($tag, $hasChild, %attrs) = @_;
  print "<$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print ">\n";

This event is generated when an XML start tag is recognized. Parameter tagname 
is the name of the XML element that is opened with the start tag. Parameter 
hasChild indicates the presence of contained nodes. The attrName 
and attrValue pairs are generated for each attribute in the start tag.

=item * End               (tagname)

  my ($tag) = @_;
  print "</$tag>\n";

This event is generated when an XML end tag is recognized. Note that
an XML empty tag (<tagname/>) generates both a start and an end event.

=item * Char              (String)

  my ($cdata) = @_;
  print $cdata;

This event is generated when non-markup is recognized. The non-markup
sequence of characters is in String. A single non-markup sequence of
characters may generate multiple calls to this handler. Whatever the
encoding of the string in the original document, this is given to the
handler in UTF-8.

=item * Proc              (target, data)

  my ($target,$data) = @_;
  print "<?$target $data?>\n";

This event is generated when a processing instruction is created. Processing 
instructions are used to convey locations and error messages.

=item * Comment           (String)

  my ($string) = @_;
  print "<!-- $string -->\n";

This event is generated when a comment is recognized.

=item * CdataStart        ()

  print "<![CDATA[";

This is called at the start of a CDATA section.

=item * CdataEnd          ()

   print "]]>";

This is called at the end of a CDATA section.

=item * XMLDecl           (Version, Encoding, Standalone)

This handler is called for XML declarations. Version is a string containing
the version. Encoding is either undefined or contains an encoding string.
Standalone is either undefined, or true or false. Undefined indicates
that no standalone parameter was given in the XML declaration. True or
false indicates "yes" or "no" respectively.

=back

=cut

sub setHandlers {
  my ($self, @handler_pairs) = @_;

  croak("Uneven number of arguments to setHandlers method")
    if (int(@handler_pairs) & 1);

  my @ret;

  while (@handler_pairs) {
    my $type = shift @handler_pairs;
    my $handler = shift @handler_pairs;
   croak "Handler for $type not a Code ref"
     unless (! defined($handler) or ! $handler or ref($handler) eq 'CODE');

    my $hndl = $self->{_Setters}->{$type};

    unless (defined($hndl)) {
      my @types = sort keys %{$self->{_Setters}};
      croak("Unknown handler type: $type\n Valid types: @types");
    }

    &$hndl($handler);
#    push (@ret, $type, $old);
  }

#  return @ret;
}

=item sub process_file($path, [\@args])

 $fpp->process_file('some_file.fpp' ,\@args);

Where $path is the path to the file to be parsed and $args is an optional 
reference to an array of arguments.

Parse the given file after passing the arguments if given.  Event handlers 
should be set using the setHandlers method before this call is made.  
Arguments are given similar to command line arguments and are defined as follows:

General options:
  -d, --depend=file           Specify dependency output file.
  -D, --define=identifier     Define an object macro.
  -U, --use=code              Specify a use on code.
  -I, --incldir=directory     Specify a directory to search for include.
  -C, --comment               Output comments.
  -P, --locate                Output locations.
  -e, --exclude               Drop excluded lines.
  -m, --modtime               Inherit mod time.
  --debug                     Output parser debugging info.
  --treebug                   Output tree debugging info.

Help options:
  -?, --help                  Show this help message
  --usage                     Display brief usage message

=cut

sub process_file($$) {
  my ($self, $path, $args) = @_;
  if (defined($args) and ref($args) eq 'ARRAY') {
    ProcessFileArg($path,$args);
  } else {
    ProcessFile($path);
  }
}

=item keyword_for_tag($tagName)

  my $keyword = $fpp->keyword_for_tag($tag);

or

  my $keyword = Rinchi::Fortran::Preprocessor->keyword_for_tag($tag);

=cut

sub keyword_for_tag($) {
  my $class_or_self = shift @_;
  my $tag = shift @_;

  return $tagToKeyword{$tag} if (exists($tagToKeyword{$tag}));
  return undef;

}

=item delimiter_for_open_tag($tagName)

  my $delim = $fpp->delimiter_for_open_tag($tag);

or

  my $delim = Rinchi::Fortran::Preprocessor->delimiter_for_open_tag($tag);


=cut

sub delimiter_for_open_tag($) {
  my $class_or_self = shift @_;
  my $tag = shift @_;

  return $delimiters{$tag}->[0] if (exists($delimiters{$tag}));
  return undef;

}

=item delimiter_for_close_tag($tagName)

  my $delim = $fpp->delimiter_for_close_tag($tag);

or

  my $delim = Rinchi::Fortran::Preprocessor->delimiter_for_close_tag($tag);


=cut

sub delimiter_for_close_tag($) {
  my $class_or_self = shift @_;
  my $tag = shift @_;

  return $delimiters{$tag}->[1] if (exists($delimiters{$tag}));
  return undef;

}

=item op_or_punc_for_tag($tagName)

  my $op_punc = $fpp->op_or_punc_for_tag($tag);

or

  my $op_punc = Rinchi::Fortran::Preprocessor->op_or_punc_for_tag($tag);

=cut

sub op_or_punc_for_tag($) {
  my $class_or_self = shift @_;
  my $tag = shift @_;

  return $punctuators{$tag} if (exists($punctuators{$tag}));
  return undef;

}

=item startElementHandler()

Default start Element handler.

=cut

sub startElementHandler() {
  my ($tag, $hasChild, %attrs) = @_;

  print "<$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  if ($hasChild == 0) {
    print " />";
    $closed = 1;
#    if($new_line{$tag} & 1) {
#      print "\n";
#    }
  } else {
    print ">";
    $closed = 0;
#    if($new_line{$tag} & 2) {
#      print "\n";
#    }
  }
}

=item endElementHandler()

Default end Element handler.

=cut

sub endElementHandler() {
  my ($tag) = @_;
  if ($closed == 0) {
    print "</$tag>";
  } else {
    $closed = 0;
  }
}

=item characterDataHandler()

Default Character Data handler.

=cut

sub characterDataHandler() {
  my ($cdata) = @_;
  print $cdata;
}

=item processingInstructionHandler()

Default Processing Instruction handler.

=cut

sub processingInstructionHandler() {
  my ($target,$data) = @_;
  print "\n<?$target $data?>\n";
}

=item commentHandler()

Default Comment handler.

=cut

sub commentHandler() {
  my ($string) = @_;
  print "<!-- $string -->\n";
}

=item startCdataHandler()

Default start CDATA handler.

=cut

sub startCdataHandler() {
  print "<![CDATA[";
}

=item endCdataHandler()

Default end CDATA handler.

=cut

sub endCdataHandler() {
   print "]]>";
}

=item xmlDeclHandler()

Default XML Declaration handler.

=cut

sub xmlDeclHandler() {
  my ($version, $encoding, $standalone) = @_;
  print "<?xml version=\"$version\" encoding=\"$encoding\" standalone=\"$standalone\"?>\n";
}

=item sub xml_outpute($path, [\@args])

 $fpp->xml_output('some_file.fpp' ,\@args);

Where $path is the path to the file to be parsed and $args is an optional 
reference to an array of arguments.

Parse the given file after passing the arguments if given. Print the XML output 
to standard output.  

=cut

sub xml_output($$) {
  my ($self, $path, $args) = @_;

  my $fpp = new Rinchi::Fortran::Preprocessor;
  $fpp->setHandlers('Start'      => \&startElementHandler,
                  'End'        => \&endElementHandler,
                  'Char'       => \&characterDataHandler,
                  'Proc'       => \&processingInstructionHandler,
                  'Comment'    => \&commentHandler,
                  'CdataStart' => \&startCdataHandler,
                  'CdataEnd'   => \&endCdataHandler,
                  'XMLDecl'    => \&xmlDeclHandler,
                  );

  if (defined($args) and ref($args) eq 'ARRAY') {
    $fpp->process_file($path,$args);
  } else {
    $fpp->process_file($path);
  }

}

# source_out handlers

sub _startElementHandler() {
  my ($tag, $hasChild, %attrs) = @_;

  my $keyword = Rinchi::Fortran::Preprocessor->keyword_for_tag($tag);
  if (defined($keyword)) {
    print "$keyword";
    return;
  } elsif ($tag eq 'identifier') {
    print $attrs{'identifier'};
    return;
  } elsif ($tag eq 'white_space') {
    print $attrs{'value'};
    return;
  } elsif ($tag eq 'float_lit') {
    print $attrs{'value'};
    return;
  } elsif ($tag eq 'char_lit') {
    print "'$attrs{'value'}'";
    return;
  } elsif ($tag eq 'comment') {
    print '! ';
    return;
  } else {
    my $delim = Rinchi::Fortran::Preprocessor->delimiter_for_open_tag($tag);
    if (defined($delim)) {
      print "$delim";
      return;
    } else {
      my $op_punc = Rinchi::Fortran::Preprocessor->op_or_punc_for_tag($tag);
      if (defined($op_punc)) {
        print "$op_punc";
        return;
      }
    }
  }
}

sub _endElementHandler() {
  my ($tag) = @_;

  my $delim = Rinchi::Fortran::Preprocessor->delimiter_for_close_tag($tag);
  if (defined($delim)) {
    print "$delim";
  }
}

sub _characterDataHandler() {
  my ($cdata) = @_;
  print $cdata;
}

sub _processingInstructionHandler() {
  my ($target,$data) = @_;
  print "\n";
}

sub _commentHandler() {
  my ($string) = @_;
}

sub _startCdataHandler() {
}

sub _endCdataHandler() {
}

sub _xmlDeclHandler() {
  my ($version, $encoding, $standalone) = @_;
}

=item sub new_source($path, [\@args])

 $fpp->new_source('some_file.fpp' ,\@args);

Where $path is the path to the file to be parsed and $args is an optional 
reference to an array of arguments.

Parse the given file after passing the arguments if given. Print the new source 
to standard output.  

=cut

sub new_source($$) {
  my ($self, $path, $args) = @_;

  my $fpp = new Rinchi::Fortran::Preprocessor;
  $fpp->setHandlers('Start'      => \&_startElementHandler,
                  'End'        => \&_endElementHandler,
                  'Char'       => \&_characterDataHandler,
                  'Proc'       => \&_processingInstructionHandler,
                  'Comment'    => \&_commentHandler,
                  'CdataStart' => \&_startCdataHandler,
                  'CdataEnd'   => \&_endCdataHandler,
                  'XMLDecl'    => \&_xmlDeclHandler,
                  );

  if (defined($args) and ref($args) eq 'ARRAY') {
    $fpp->process_file($path,$args);
  } else {
    $fpp->process_file($path);
  }

}

# Preloaded methods go here.

1;
__END__

=item Macro Expansion:

This Perl extension has been tested to meet the requirements set forth in 
ISO/IEC 14882:2003(E) with the exception of preservation of white in some 
cases. This is not really a result of the macro expansion, but the elimination 
of most white space as unnecessary in the XML output.

=item XML Elements produced:

The following is a partial list of the elements produced.  See the DTD for the complete details.

=over 4

 translation_unit
 predefined_macro
 object_macro
 command_line
 include_directory
 use_on_code
 preprocessing_file
 identifier
 replaced_identifier

=back

=item Locations:

Locations are reported as processing instructions as shown in the following 
example, which indicates line 352 of file /usr/include/features.h.

<?location "/usr/include/features.h" 352?>

=item Use on code:

This preprocessor includes an extension designed to facilitate the maintenance 
of multiple configurations in a single file, use on code. To apply use on 
codes, defined a code for each configuration as shown in the following example:

=over 4

 lin  Linux
 gnu  GNU/Linux
 unx  Unix
 wno  Windows

=back

Each source line that is not applicable to all configuration can then be tagged using the following method:

=over 4

 int result;  // Always

 result = soundApproach(); //{lin,gnu} // For Linux or GNU/Linux
 result = okApproach(); //{unx}  // For Unix
 result = problematic(); //{wno}  // For Windows

 return result;  // Always

=back

Configurations are selected by supplying the desired use on codes in the 
argument list passed to the process_file method.  For example "-Ulin" would 
select all common lines and all those tagged with lin.  Since use on codes are 
examined before any other parsing takes place, preprocessing instructions may 
be tagged.  Multiple -U arguments result in "or"ing the results.

=head1 SEE ALSO

XML::Parser

=head1 AUTHOR

Brian M. Ames, E<lt>bames@apk.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Brian M. Ames

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
