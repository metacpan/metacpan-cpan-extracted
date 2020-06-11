package PICA::Data;
use v5.14.1;

our $VERSION = '1.08';

use Exporter 'import';
our @EXPORT_OK = qw(pica_parser pica_writer pica_path pica_xml_struct
    pica_match pica_values pica_value pica_fields pica_holdings pica_items
    pica_guess);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

our $ILN_PATH = PICA::Path->new('101@a');
our $EPN_PATH = PICA::Path->new('203@/..0');

use Carp qw(croak);
use Scalar::Util qw(reftype blessed);
use List::Util qw(first any);
use IO::Handle;
use PICA::Path;

sub pica_match {
    my ($record, $path, %args) = @_;

    $path = eval {PICA::Path->new($path)} unless ref $path;
    return unless ref $path;

    return $path->match_record($record, %args);
}

sub pica_values {
    my ($record, $path) = @_;

    $path = eval {PICA::Path->new($path)} unless ref $path;
    return unless ref $path;

    return $path->record_subfields($record);
}

sub pica_fields {
    my $record = shift;
    $record = $record->{record} if reftype $record eq 'HASH';

    my @pathes = map {
        ref $_ ? $_ : eval {PICA::Path->new($_)}
    } @_;

    return [
        grep {
            my $cur = $_;
            any {$_->match_field($cur)} @pathes
        } @$record
    ];
}

sub pica_value {
    my ($record, $path) = @_;

    $record = $record->{record} if reftype $record eq 'HASH';
    $path   = eval {PICA::Path->new($path)} unless ref $path;
    return unless defined $path;

    foreach my $field (@$record) {
        next unless $path->match_field($field);
        my @values = $path->match_subfields($field);
        return $values[0] if @values;
    }

    return;
}

sub pica_items {
    my ($record) = @_;

    my $blessed = blessed($record);
    $record = $record->{record} if reftype $record eq 'HASH';
    my (@items, $current, $occurrence);

    foreach my $field (@$record) {
        if ($field->[0] =~ /^2/) {

            if (($occurrence // '') ne $field->[1]) {
                if ($current) {
                    push @items, $current;
                    $current = undef;
                }
                $occurrence = $field->[1];
            }

            $current //= {record => []};

            push @{$current->{record}}, [@$field];
            if ($field->[0] eq '203@') {
                ($current->{_id}) = $EPN_PATH->match_subfields($field);
            }
        }
        elsif ($current) {
            push @items, $current;
            $current    = undef;
            $occurrence = undef;
        }
    }

    push @items, $current if $current;

    if ($blessed) {
        bless $_, $blessed for @items;
    }

    return \@items;
}

sub pica_holdings {
    my ($record) = @_;

    my $blessed = blessed($record);
    $record = $record->{record} if reftype $record eq 'HASH';
    my (@holdings, $iln);
    my $field_buffer = [];

    foreach my $field (@$record) {
        my $tag = substr $field->[0], 0, 1;
        if ($tag eq '0') {
            next;
        }
        elsif ($tag eq '1') {
            if ($field->[0] eq '101@') {
                my ($id) = $ILN_PATH->match_subfields($field);
                if (defined $iln && ($id // '') ne $iln) {
                    push @holdings, {record => $field_buffer, _id => $iln};
                }
                $field_buffer = [[@$field]];
                $iln          = $id;
                next;
            }
        }
        push @$field_buffer, [@$field];
    }

    if (@$field_buffer) {
        push @holdings, {record => $field_buffer, _id => $iln};
    }

    if ($blessed) {
        bless $_, $blessed for @holdings;
    }

    return \@holdings;
}

*fields   = *pica_fields;
*holdings = *pica_holdings;
*items    = *pica_items;
*match    = *pica_match;
*value    = *pica_value;
*values   = *pica_values;

use PICA::Parser::XML;
use PICA::Parser::Plus;
use PICA::Parser::Plain;
use PICA::Parser::Binary;
use PICA::Parser::JSON;
use PICA::Writer::XML;
use PICA::Writer::Plus;
use PICA::Writer::Plain;
use PICA::Writer::Binary;
use PICA::Writer::PPXML;
use PICA::Writer::JSON;

sub pica_parser {
    _pica_module('PICA::Parser', @_);
}

sub pica_writer {
    _pica_module('PICA::Writer', @_);
}

sub pica_path {
    PICA::Path->new(@_);
}

sub pica_guess {
    my ($pica) = @_;

    my $format = '';
    my %count  = (
        ''       => 0,
        'Plain'  => ($pica =~ tr/$//),
        'Plus'   => ($pica =~ tr/\x{0A}//),
        'Binary' => ($pica =~ tr/\x{1D}//),
        'XML'    => ($pica =~ tr/<//),
        'JSON'   => ($pica =~ tr/[{[]//),
    );
    $count{$_} > $count{$format} and $format = $_ for grep {$_} keys %count;

    $format = 'PPXML' if $format eq 'XML' and $pica =~ qr{xmlns/ppxml-1\.0};

    $format ? "PICA::Parser::$format" : undef;
}

sub _pica_module {
    my $base = shift;
    my $type = lc(shift) // '';

    if ($type =~ /^(pica)?plus$/) {
        "${base}::Plus"->new(@_);
    }
    elsif ($type eq 'binary') {
        "${base}::Binary"->new(@_);
    }
    elsif ($type =~ /^(pica)?plain$/) {
        "${base}::Plain"->new(@_);
    }
    elsif ($type =~ /^(pica)?xml$/) {
        "${base}::XML"->new(@_);
    }
    elsif ($type =~ /^(pica)?ppxml$/) {
        "${base}::PPXML"->new(@_);
    }
    elsif ($type =~ /^(nd)?json$/) {
        "${base}::JSON"->new(@_);
    }
    else {
        croak "unknown PICA parser type: $type";
    }
}

sub write {
    my $pica   = shift;
    my $writer = $_[0];
    unless (blessed $writer) {
        $writer = pica_writer(@_ ? @_ : 'plain');
    }
    $writer->write($pica);
}

sub string {
    my ($pica, $type, %options) = @_;
    my $string = "";
    $type ||= 'plain';
    $options{fh} = \$string;
    $options{start} //= 0;
    pica_writer($type => %options)->write($pica);
    return $string;
}

sub TO_JSON {
    my $record = shift;
    $record = $record->{record} if reftype $record eq 'HASH';
    return [@$record];
}

sub pica_xml_struct {
    my ($xml, %options) = @_;
    my $record;

    foreach my $f (@{$xml->[2]}) {
        next unless $f->[0] eq 'datafield';
        push @$record,
            [
            map ({$f->[1]->{$_}} qw(tag occurrence)),
            map ({$_->[1]->{code} => $_->[2]->[0]} @{$f->[2]})
            ];
    }

    my ($id) = map {$_->[-1]} grep {$_->[0] =~ '003@'} @$record;
    $record = {_id => $id, record => $record};
    bless $record, 'PICA::Data' if !!$options{bless};
    return $record;
}

1;
__END__

=head1 NAME

PICA::Data - PICA record processing

=begin markdown 

[![Unix build Status](https://travis-ci.org/gbv/PICA-Data.png)](https://travis-ci.org/gbv/PICA-Data)
[![Windows build status](https://ci.appveyor.com/api/projects/status/5qjak74x7mjy7ne6?svg=true)](https://ci.appveyor.com/project/nichtich/pica-data)
[![Coverage Status](https://coveralls.io/repos/gbv/PICA-Data/badge.svg)](https://coveralls.io/r/gbv/PICA-Data)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/PICA-Data.png)](http://cpants.cpanauthors.org/dist/PICA-Data)

=end markdown

=encoding UTF-8

=head1 SYNOPSIS

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

=head1 DESCRIPTION

PICA::Data provides methods, classes, functions, and L<picadata|a command line
application> to process L<PICA+ records|http://format.gbv.de/pica> in Perl.

PICA+ is the internal data format of the Local Library System (LBS) and the
Central Library System (CBS) of OCLC, formerly PICA. Similar library formats
are the MAchine Readable Cataloging format (MARC) and the Maschinelles
Austauschformat fuer Bibliotheken (MAB). In addition to PICA+ in CBS there is
the cataloging format Pica3 which can losslessly be convert to PICA+ and vice
versa.

Records in PICA::Data are encoded either as array of arrays, the inner arrays
representing PICA fields, or as an object with two keys, C<_id> and C<record>,
the latter holding the record as array of arrays, and the former holding the
record identifier, stored in field C<003@>, subfield C<0>. For instance a
minimal record with just one field (having tag C<003@> and no occurrence):

    {
      _id    => '12345X',
      record => [
        [ '003@', undef, '0' => '12345X' ]
      ]
    }

or in short form:

    [ [ '003@', undef, '0' => '12345X' ] ]

PICA path expressions (see L<PICA::Path>) can be used to facilitate processing
PICA+ records and L<PICA::Schema> can be used to validate PICA+ records with
L<Avram Schemas|https://format.gbv.de/schema/avram/specification>.

=head1 FUNCTIONS

The following functions can be exported on request (use export tag C<:all> to
get all of them):

=head2 pica_parser( $type [, @options] )

Create a PICA parsers object (see L<PICA::Parser::Base>). Case of the type is
ignored and additional parameters are passed to the parser's constructor:

=over

=item 

L<PICA::Parser::Binary> for type C<binary> (binary PICA+)

=item 

L<PICA::Parser::Plain> for type C<plain> or C<picaplain> (human-readable PICA+)

=item 

L<PICA::Parser::Plus> for type C<plus> or C<picaplus> (normalized PICA+)

=item

L<PICA::Parser::JSON> for type C<json> (PICA JSON)

=item 

L<PICA::Parser::XML> for type C<xml> or C<picaxml> (PICA-XML)

=item 

L<PICA::Parser::PPXML> for type C<ppxml> (PicaPlus-XML)

=back

=head2 pica_guess( $data )

Guess PICA serialization format from input data. Returns name of the
corresponding parser class or C<undef>.

=head2 pica_xml_struct( $xml, %options )

Convert PICA-XML, expressed in L<XML::Struct> structure into an (optionally
blessed) PICA record structure.

=head2 pica_writer( $type [, @options] )

Create a PICA writer object (see L<PICA::Writer::Base>) in the same way as
C<pica_parser> with one of

=over

=item 

L<PICA::Writer::Binary> for type C<binary> (binary PICA)

=item 

L<PICA::Writer::Generic> for type C<generic> (PICA with self defined data separators)

=item 

L<PICA::Writer::Plain> for type C<plain> or C<picaplain> (human-readable PICA+)

=item 

L<PICA::Writer::Plus> for type C<plus> or C<picaplus> (normalized PICA+)

=item

L<PICA::Writer::JSON> for type C<json> (PICA JSON)

=item 

L<PICA::Writer::XML> for type C<xml> or C<picaxml> (PICA-XML)

=item 

L<PICA::Writer::PPXML> for type C<ppxml> (PicaPlus-XML)

=back

=head2 pica_path( $path )

Equivalent to L<PICA::Path>-E<gt>new($path).

=head2 pica_match( $record, $path, %options )

Equivalent to L<PICA::Path>-E<gt>match_record($path, %options).

Extract the subfield values from a PICA record based on a PICA path
expression and options (see L<PICA::Path>). Also available as accessor 
C<match($path, %options)>.

=head2 pica_value( $record, $path )

Extract the first subfield values from a PICA record based on a PICA path
expression. Also available as accessor C<value($path)>.

=head2 pica_values( $record, $path )

Extract a list of subfield values from a PICA record based on a PICA path
expression. The following are virtually equivalent:

    pica_values($record, $path);
    $path->record_subfields($record);
    $record->values($path); # if $record is blessed

=head2 pica_fields( $record, $path[, $path...] )

Returns a PICA record (or empty array reference) limited to fields specified inione ore more PICA path expression. The following are virtually equivalent:

    pica_fields($record, $path);
    $path->record_fields($record);
    $record->fields($path); # if $record is blessed

=head2 pica_holdings( $record )

Returns a list (as array reference) of local holding records. Also available as
accessor C<holdings>.

=head2 pica_items( $record )

Returns a list (as array reference) of item records. Also available as
accessor C<items>.

=head1 ACCESSORS

All accessors of C<PICA::Data> are also available as L</FUNCTIONS>, prefixed
with C<pica_> (see L</SYNOPSIS>).

=head2 match( $path, %options )

Extract a list of subfield values from a PICA record based on a L<PICA::Path>
expression and options.

=head2 values( $path )

Extract a list of subfield values from a PICA record based on a L<PICA::Path>
expression.

=head2 value( $path )

Same as C<values> but only returns the first value.

=head2 fields( $path[, $path...] )

Returns a PICA record limited to fields specified in a L<PICA::Path>
expression.  Always returns an array reference.

=head2 holdings

Returns a list (as array reference) of local holding records (level 1 and 2),
where the C<_id> of each record contains the ILN (subfield C<101@a>).

=head2 items

Returns a list (as array reference) of item records (level 1),
where the C<_id> of each record contains the EPN (subfield C<203@/**0>).

=head1 METHODS

=head2 write( [ $type [, @options] ] | $writer )

Write PICA record with given L<PICA::Writer::Base|PICA::Writer::> or
L<PICA::Writer::Plain> by default. This method is a shortcut for blessed
record objects:

    pica_writer( xml => $file )->write( $record );
    $record->write( xml => $file ); # equivalent if $record is blessed 

=head2 string( [ $type ] )

Serialize PICA record in a given format (C<plain> by default).

=head1 CONTRIBUTORS

Johann Rolschewski, C<< <jorol@cpan.org> >>

Jakob Voß C<< <voss@gbv.de> >>

Carsten Klee C<< <klee@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2014- Johann Rolschewski and Jakob Voss

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

=over

=item

L<picadata> command line script to parse, serialize, count, and validate
PICA+ data.

=item 

Use L<Catmandu::PICA> for more elaborated processing of PICA records with the
L<Catmandu> toolkit.

=item

L<PICA::Record> implemented an alternative framework for processing PICA+
records (B<deprecated!>).

=back

=cut
