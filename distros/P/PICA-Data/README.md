# NAME

PICA::Data - PICA record processing

[![Unix build Status](https://travis-ci.org/gbv/PICA-Data.png)](https://travis-ci.org/gbv/PICA-Data)
[![Windows build status](https://ci.appveyor.com/api/projects/status/5qjak74x7mjy7ne6?svg=true)](https://ci.appveyor.com/project/nichtich/pica-data)
[![Coverage Status](https://coveralls.io/repos/gbv/PICA-Data/badge.svg)](https://coveralls.io/r/gbv/PICA-Data)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/PICA-Data.png)](http://cpants.cpanauthors.org/dist/PICA-Data)

# SYNOPSIS

      use PICA::Data ':all';
      $parser = pica_parser( xml => 'picadata.xml' );
      $writer = pica_writer( plain => \*STDOUT );
     
      use PICA::Parser::XML;
      use PICA::Writer::Plain;
      $parser = PICA::Parser::XML->new( @options );
      $writer = PICA::Writer::Plain->new( @options );

      use PICA::Schema;
      $schema = PICA::Schema->new();

      # parse records
      while ( my $record = $parser->next ) {
          
          # function accessors
          my $ppn      = pica_value($record, '003@0');
          my $ppn      = pica_match($record, '045Ue', split => 1, nested_array => 1);
          my $holdings = pica_holdings($record);
          my $items    = pica_items($record);
          ...

          # object accessors (if parser option 'bless' enabled)
          my $ppn      = $record->{_id};
          my $ppn      = $record->value('003@0');
          my $ddc      = $record->match('045Ue', split => 1, nested_array => 1);
          my $holdings = $record->holdings;
          my $items    = $record->items;
          ...

          # write record
          $writer->write($record);
          
          # write record via method (if blessed)
          $record->write($writer);
          $record->write( xml => @options );
          $record->write; # default "plain" writer

          # stringify record
          my $plain = $record->string;
          my $xml = $record->string('xml');

          # validate record
          my $errors = $schema->check($record);
      }
    
      # parse single record from string
      my $record = pica_parser('plain', \"...")->next;

      # guess parser from input string
      my $parser = pica_guess($string)->new(\$string);

# DESCRIPTION

PICA::Data provides methods, classes, functions, and [picadata](https://metacpan.org/pod/a%20command%20line%0Aapplication) to process [PICA+ records](http://format.gbv.de/pica) in Perl.

PICA+ is the internal data format of the Local Library System (LBS) and the
Central Library System (CBS) of OCLC, formerly PICA. Similar library formats
are the MAchine Readable Cataloging format (MARC) and the Maschinelles
Austauschformat fuer Bibliotheken (MAB). In addition to PICA+ in CBS there is
the cataloging format Pica3 which can losslessly be convert to PICA+ and vice
versa.

Records in PICA::Data are encoded either as array of arrays, the inner arrays
representing PICA fields, or as an object with two keys, `_id` and `record`,
the latter holding the record as array of arrays, and the former holding the
record identifier, stored in field `003@`, subfield `0`. For instance a
minimal record with just one field (having tag `003@` and no occurrence):

    {
      _id    => '12345X',
      record => [
        [ '003@', undef, '0' => '12345X' ]
      ]
    }

or in short form:

    [ [ '003@', undef, '0' => '12345X' ] ]

PICA path expressions (see [PICA::Path](https://metacpan.org/pod/PICA%3A%3APath)) can be used to facilitate processing
PICA+ records and [PICA::Schema](https://metacpan.org/pod/PICA%3A%3ASchema) can be used to validate PICA+ records with
[Avram Schemas](https://format.gbv.de/schema/avram/specification).

# FUNCTIONS

The following functions can be exported on request (use export tag `:all` to
get all of them):

## pica\_parser( $type \[, @options\] )

Create a PICA parsers object (see [PICA::Parser::Base](https://metacpan.org/pod/PICA%3A%3AParser%3A%3ABase)). Case of the type is
ignored and additional parameters are passed to the parser's constructor:

- [PICA::Parser::Binary](https://metacpan.org/pod/PICA%3A%3AParser%3A%3ABinary) for type `binary` (binary PICA+)
- [PICA::Parser::Plain](https://metacpan.org/pod/PICA%3A%3AParser%3A%3APlain) for type `plain` or `picaplain` (human-readable PICA+)
- [PICA::Parser::Plus](https://metacpan.org/pod/PICA%3A%3AParser%3A%3APlus) for type `plus` or `picaplus` (normalized PICA+)
- [PICA::Parser::JSON](https://metacpan.org/pod/PICA%3A%3AParser%3A%3AJSON) for type `json` (PICA JSON)
- [PICA::Parser::XML](https://metacpan.org/pod/PICA%3A%3AParser%3A%3AXML) for type `xml` or `picaxml` (PICA-XML)
- [PICA::Parser::PPXML](https://metacpan.org/pod/PICA%3A%3AParser%3A%3APPXML) for type `ppxml` (PicaPlus-XML)

## pica\_guess( $data )

Guess PICA serialization format from input data. Returns name of the
corresponding parser class or `undef`.

## pica\_xml\_struct( $xml, %options )

Convert PICA-XML, expressed in [XML::Struct](https://metacpan.org/pod/XML%3A%3AStruct) structure into an (optionally
blessed) PICA record structure.

## pica\_writer( $type \[, @options\] )

Create a PICA writer object (see [PICA::Writer::Base](https://metacpan.org/pod/PICA%3A%3AWriter%3A%3ABase)) in the same way as
`pica_parser` with one of

- [PICA::Writer::Binary](https://metacpan.org/pod/PICA%3A%3AWriter%3A%3ABinary) for type `binary` (binary PICA)
- [PICA::Writer::Generic](https://metacpan.org/pod/PICA%3A%3AWriter%3A%3AGeneric) for type `generic` (PICA with self defined data separators)
- [PICA::Writer::Plain](https://metacpan.org/pod/PICA%3A%3AWriter%3A%3APlain) for type `plain` or `picaplain` (human-readable PICA+)
- [PICA::Writer::Plus](https://metacpan.org/pod/PICA%3A%3AWriter%3A%3APlus) for type `plus` or `picaplus` (normalized PICA+)
- [PICA::Writer::JSON](https://metacpan.org/pod/PICA%3A%3AWriter%3A%3AJSON) for type `json` (PICA JSON)
- [PICA::Writer::XML](https://metacpan.org/pod/PICA%3A%3AWriter%3A%3AXML) for type `xml` or `picaxml` (PICA-XML)
- [PICA::Writer::PPXML](https://metacpan.org/pod/PICA%3A%3AWriter%3A%3APPXML) for type `ppxml` (PicaPlus-XML)

## pica\_path( $path )

Equivalent to [PICA::Path](https://metacpan.org/pod/PICA%3A%3APath)->new($path).

## pica\_match( $record, $path, %options )

Equivalent to [PICA::Path](https://metacpan.org/pod/PICA%3A%3APath)->match\_record($path, %options).

Extract the subfield values from a PICA record based on a PICA path
expression and options (see [PICA::Path](https://metacpan.org/pod/PICA%3A%3APath)). Also available as accessor 
`match($path, %options)`.

## pica\_value( $record, $path )

Extract the first subfield values from a PICA record based on a PICA path
expression. Also available as accessor `value($path)`.

## pica\_values( $record, $path )

Extract a list of subfield values from a PICA record based on a PICA path
expression. The following are virtually equivalent:

    pica_values($record, $path);
    $path->record_subfields($record);
    $record->values($path); # if $record is blessed

## pica\_fields( $record, $path\[, $path...\] )

Returns a PICA record (or empty array reference) limited to fields specified inione ore more PICA path expression. The following are virtually equivalent:

    pica_fields($record, $path);
    $path->record_fields($record);
    $record->fields($path); # if $record is blessed

## pica\_holdings( $record )

Returns a list (as array reference) of local holding records. Also available as
accessor `holdings`.

## pica\_items( $record )

Returns a list (as array reference) of item records. Also available as
accessor `items`.

# ACCESSORS

All accessors of `PICA::Data` are also available as ["FUNCTIONS"](#functions), prefixed
with `pica_` (see ["SYNOPSIS"](#synopsis)).

## match( $path, %options )

Extract a list of subfield values from a PICA record based on a [PICA::Path](https://metacpan.org/pod/PICA%3A%3APath)
expression and options.

## values( $path )

Extract a list of subfield values from a PICA record based on a [PICA::Path](https://metacpan.org/pod/PICA%3A%3APath)
expression.

## value( $path )

Same as `values` but only returns the first value.

## fields( $path\[, $path...\] )

Returns a PICA record limited to fields specified in a [PICA::Path](https://metacpan.org/pod/PICA%3A%3APath)
expression.  Always returns an array reference.

## holdings

Returns a list (as array reference) of local holding records (level 1 and 2),
where the `_id` of each record contains the ILN (subfield `101@a`).

## items

Returns a list (as array reference) of item records (level 1),
where the `_id` of each record contains the EPN (subfield `203@/**0`).

# METHODS

## write( \[ $type \[, @options\] \] | $writer )

Write PICA record with given [PICA::Writer::Base](https://metacpan.org/pod/PICA%3A%3AWriter%3A%3A) or
[PICA::Writer::Plain](https://metacpan.org/pod/PICA%3A%3AWriter%3A%3APlain) by default. This method is a shortcut for blessed
record objects:

    pica_writer( xml => $file )->write( $record );
    $record->write( xml => $file ); # equivalent if $record is blessed 

## string( \[ $type \] )

Serialize PICA record in a given format (`plain` by default).

# CONTRIBUTORS

Johann Rolschewski, `<jorol@cpan.org>`

Jakob Voß `<voss@gbv.de>`

Carsten Klee `<klee@cpan.org>`

# COPYRIGHT AND LICENSE

Copyright 2014- Johann Rolschewski and Jakob Voss

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

# SEE ALSO

- [picadata](https://metacpan.org/pod/picadata) command line script to parse, serialize, count, and validate
PICA+ data.
- Use [Catmandu::PICA](https://metacpan.org/pod/Catmandu%3A%3APICA) for more elaborated processing of PICA records with the
[Catmandu](https://metacpan.org/pod/Catmandu) toolkit.
- [PICA::Record](https://metacpan.org/pod/PICA%3A%3ARecord) implemented an alternative framework for processing PICA+
records (**deprecated!**).
