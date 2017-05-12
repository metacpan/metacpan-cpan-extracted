package PICA::XMLParser;
{
  $PICA::XMLParser::VERSION = '0.585';
}
#ABSTRACT: Parse PICA+ XML
use strict;

use base qw(XML::SAX::Base Exporter);
use Carp qw(croak);
our @EXPORT_OK = qw(parsefile parsedata);

require PICA::Field;


use PICA::Field;
use PICA::Record;
use XML::SAX::ParserFactory 1.01;
use Carp qw(croak);


sub new {
    my ($class, %params) = @_;
    $class = ref $class || $class;

    my $self = {
        record => {},
        fields => {},

        read_records => [],

        tag => "",
        occurrence => "",
        subfield_code => "",
        subfield_value => "",

        limit  => ($params{Limit} || 0) * 1,
        offset  => ($params{Offset} || 0) * 1,

        # Handlers
        field_handler  => $params{Field} ? $params{Field} : undef,
        record_handler => $params{Record} ? $params{Record} : undef,
        collection_handler => $params{Collection} ? $params{Collection} : undef,

        proceed => $params{Proceed} ? $params{Proceed} : 0,

        read_counter => 0,
    };
    bless $self, $class;
    return $self;
}


sub parsedata {
    my $self = shift;

    if ( ref($self) eq "PICA::XMLParser" ) { # called as a method
      my $data = shift;

      if ( ! $self->{proceed} ) {
          $self->{read_counter} = 0;
          $self->{read_records} = [];
      }

      if( UNIVERSAL::isa( $data, 'PICA::Record' ) ) {
        foreach ( $data->fields ) {
            # TODO: we could improve performance here
            # TODO: merge this into PICA::Parser
            $self->_parseline( $_->string );
        }
      }

      my $parser = XML::SAX::ParserFactory->new(
        RequiredFeatures => { 'http://xml.org/sax/features/namespaces' => 1 }
      )->parser( Handler => $self );

      if (ref($data) eq 'ARRAY') {
          $data = join('',@{$data})
      } elsif (ref($data) eq 'CODE') {
          my $code = $data;
          $data = "";
          my $chunk = &$code();
          while(defined $chunk) {
              $data .= $chunk;
              $chunk = &$code();
          }
      }

      $parser->parse_string($data);

      $self;

    } else { # called as function
        my $data = ($self eq 'PICA::XMLParser') ? shift : $self;
        croak("Missing argument to parsedata") unless defined $data;
        PICA::XMLParser->new( @_ )->parsedata( $data );
    }
}


sub parsefile {
    my $self = shift;

    if ( ref($self) eq "PICA::XMLParser" ) { # called as a method
        my $file = shift;

        if ( ! $self->{proceed} ) {
            $self->{read_counter} = 0;
            $self->{read_records} = [];
        }

        $self->{filename} = $file if ref(\$file) eq 'SCALAR';

        my $parser = XML::SAX::ParserFactory->new(
          RequiredFeatures => { 'http://xml.org/sax/features/namespaces' => 1 }
        )->parser( Handler => $self );

        if (ref($file) eq 'GLOB' or eval { $file->isa("IO::Handle") }) {
            $parser->parse_file($file);
        } else {
            $parser->parse_uri($file);
        }

        $self;

    } else { # called as a function       
        my $file = ($self eq 'PICA::XMLParser') ? shift : $self;
        croak("Missing argument to parsefile") unless defined $file;
        PICA::XMLParser->new( @_ )->parsefile( $file );
    }
}


sub records {
   my $self = shift; 
   return @{ $self->{read_records} };
}


sub counter {
   my $self = shift; 
   return $self->{read_counter};
}


sub finished {
    my $self = shift; 
    return $self->{limit} && $self->counter() >= $self->{limit};
}


sub start_document {
    my ($self, $doc) = @_;

    $self->{subfield_code} = "";
    $self->{tag} = "";
    $self->{occurrence} = "";
    $self->{record} = ();
}


sub end_document {
    my ($self, $doc) = @_;
}


sub start_element {
    my ($self, $el) = @_;
    my $name = $el->{LocalName};
    my %attrs = map { $_->{LocalName} => $_->{Value} } values %{ $el->{Attributes} };

    my $ns = $el->{NamespaceURI};
    $name = '{'.$ns.'}:'.$name if $ns and $ns ne $PICA::Record::XMLNAMESPACE;

    if ($name eq "subfield") {

        my $code = $attrs{"code"};
        if (defined $code) {
            if ($code =~ $PICA::Field::SUBFIELD_CODE_REGEXP) {
                $self->{subfield_code} = $code;
                $self->{subfield_value} = "";
            } else {
               croak "Invalid subfield code '$code'"; # . $self->_getPosition($parser));
            }
        } else {
            croak "Missing attribute 'code'"; # . $self->_getPosition($parser));
        }
    } elsif ($name eq "field" or $name eq "datafield") {
        my $tag = $attrs{tag};
        if (defined $tag) {
            if (!($tag =~ $PICA::Field::FIELD_TAG_REGEXP)) {
                croak "Invalid field tag '$tag'"; # . $self->_getPosition($parser));
            }
        } else {
            croak "Missing attribute 'tag'"; # . $self->_getPosition($parser));
        }
        my $occurrence = $attrs{occurrence};
        if ($occurrence && !($occurrence =~ $PICA::Field::FIELD_OCCURRENCE_REGEXP)) {
            croak "Invalid occurrence '$occurrence'"; # . $self->_getPosition($parser));
        }

        $self->{tag} = $tag;
        $self->{occurrence} = $occurrence ? $occurrence : undef;
        $self->{subfields} = ();

    } elsif ($name eq "record") {
        $self->{fields} = [];
    } elsif ($name eq "collection") {
        $self->{records} = [];
    } else {
        croak "Unknown element '$name'"; # . $self->_getPosition($parser));
    }
}


sub end_element {
    my ($self, $el) = @_;
    my $name = $el->{LocalName};
    # TODO: $el->{NamespaceURI}

    if ($name eq "subfield") {
        push (@{$self->{subfields}}, ($self->{subfield_code}, $self->{subfield_value}));
    } elsif ($name eq "field" or $name eq "datafield") {

#        return if $self->{tag} eq ''; # ignore

#        croak ("Field " . $self->{tag} . " is empty" . $self->_getPosition($parser)) unless $self->{subfields};
        croak ("Field " . $self->{tag} . " is empty") unless $self->{subfields};

        my $field = bless {
            _tag => $self->{tag},
            _occurrence => $self->{occurrence},
            _subfields => [@{$self->{subfields}}]
        }, 'PICA::Field'; # TODO: use constructor instead

        if ($self->{field_handler}) {
            $field = $self->{field_handler}( $field );
        }

        if (UNIVERSAL::isa($field,"PICA::Field")) {
            push (@{$self->{fields}}, $field);
        }
    } elsif ($name eq "record") {
        return if $self->finished();

        $self->{read_counter}++;

        if (! ($self->{offset} && $self->{read_counter} < $self->{offset}) ) {
            my $record =  PICA::Record->new( @{$self->{fields}} );

            if ($self->{record_handler}) {
                $record = $self->{record_handler}( $record );
            }
            if ($record) {
                push @{ $self->{read_records} }, $record;
            }
        }

    } elsif ($name eq "collection") {
        $self->{collection_handler}( $self->records() )
            if $self->{collection_handler};
    } else {
        croak("Unknown element '$name'"); # . $self->_getPosition($parser));
    }
}


sub characters {
    my ($self, $string) = @_;
    ($string) = values %$string;

    # all character data outside of subfield content will be ignored without warning
    if (defined $self->{subfield_code}) {
        $string =~ s/[\n\r]+/ /g; # remove newlines
        $self->{subfield_value} .= $string;
    }
}


sub _getPosition {
    my ($self, $parser) = @_;

    if ($self->{filename}) {
        return " in " . $self->{filename} . ", line " . $parser->current_line();
    } else {
        return " in line " . $parser->current_line();
    }
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

PICA::XMLParser - Parse PICA+ XML

=head1 VERSION

version 0.585

=head1 SYNOPSIS

  my $rcount = 1;
  my $parser = PICA::XMLParser->new( 
      Field => \&field_handler,
      Record => \&record_handler
  );
  $parser->parsefile($filename);

  # equivalent:
  PICA::Parser->parsefile($filename,
      Field => \&field_handler,
      Record => \&record_handler,
      Format => 'xml'  
  );

  sub field_handler {
      my $field = shift;
      print $field->string;
      # no need to save the field so do not return it
  }

  sub record_handler {
      print "$rcount\n"; $rcount++;
  }

=head1 DESCRIPTION

This module contains a parser to parse PICA+ XML. Up to now
PICA+ XML is not fully standarized yet so this parser may 
slightly change in the future.

This module can read multiple collections per file or data 
stream but only the records of the current collection are
saved and returned with the <records> method. Use the 
C<Collection> handler to parse files with multiple collections.

=head1 PUBLIC METHODS

=head2 new ( [ %params ] )

Creates a new Parser. See L<PICA::Parser> for a description of 
parameters to define handlers (Field and Record). In addition
this parser supports the C<Collection> handler that is called
on a C<collection> end tag.

=head2 parsedata

Parses data from a string, array reference or function. 
Data from arrays and functions will be read and buffered 
before parsing. Do not directly call this method without 
a C<PICA::XMLParser> object that was created with C<new()>.

=head2 parsefile ( $filename | $handle )

Parses data from a file or filehandle or L<IO::Handle>.

=head2 records ( )

Get an array of the read records (if they have been stored)

=head2 counter ( )

Get the number of read records so far. Please note that the number
of records as returned by the C<records> method may be lower because
you may have filtered out some records.

=head2 finished ( ) 

Return whether the parser will not parse any more records. This
is the case if the number of read records is larger then the limit.

=head1 PRIVATE HANDLERS

Do not directly call this methods.

=head2 start_document

Called at the beginning.

=head2 end_document

Called at the end. Does nothing so far.

=head2 start_element

Called for each start tag.

=head2 end_element

Called for each end tag.

=head2 characters

Called for character data.

=head2 _getPosition

Get the current position (file name and line number). This method is deprecated.

=head1 AUTHOR

Jakob Voß <voss@gbv.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Verbundzentrale Goettingen (VZG) and Jakob Voss.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
