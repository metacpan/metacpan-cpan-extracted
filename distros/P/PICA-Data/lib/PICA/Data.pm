package PICA::Data;
use v5.14.1;

our $VERSION = '2.09';

use Exporter 'import';
our @EXPORT_OK
    = qw(pica_data pica_parser pica_writer pica_path pica_xml_struct
    pica_match pica_values pica_value pica_fields pica_subfields
    pica_title pica_holdings pica_items pica_field
    pica_split pica_annotation pica_sort pica_guess clean_pica pica_string pica_id
    pica_sort_subfields parse_subfield_schedule
    pica_diff pica_patch pica_empty);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

our $ILN_PATH = PICA::Path->new('101@a');
our $EPN_PATH = PICA::Path->new('203@/*$0');

use Carp         qw(croak);
use Scalar::Util qw(reftype blessed);
use Encode       qw(decode);
use List::Util   qw(first any);
use IO::Handle;
use PICA::Path qw(pica_field_matcher);
use Hash::MultiValue;

use sort 'stable';

sub new {
    my ($class, $data) = @_;

    if (defined $data) {
        my $parser = pica_guess($data)
            or croak "Could not guess PICA serialization format";
        return $parser->new(\$data)->next;
    }
    else {
        return bless {record => []}, 'PICA::Data';
    }
}

sub pica_data {
    PICA::Data->new(@_);
}

sub pica_field {
    PICA::Data::Field->new(@_);
}

sub pica_match {
    my ($record, $path, %args) = @_;

    $path = eval {PICA::Path->new($path)} unless ref $path;
    return                                unless ref $path;

    return $path->match_record($record, %args);
}

sub pica_values {
    my ($record, $path) = @_;

    $path = eval {PICA::Path->new($path)} unless ref $path;
    return                                unless ref $path;

    return $path->record_subfields($record);
}

sub pica_fields {
    my $record = shift;
    croak "missing record. Did you mean pica_field instead of pica_fields?"
        unless ref $record;

    $record = $record->{record} if reftype $record eq 'HASH';

    return [@$record] unless @_;

    my $matcher = eval {pica_field_matcher(@_)};
    return [] unless $matcher;

    return [grep {$matcher->($_)} @$record];
}

sub pica_append {
    my $fields = reftype $_[0] eq 'HASH' ? shift->{record} : shift;
    push @$fields, pica_field(@_);
}

sub pica_remove {
    my $fields  = reftype $_[0] eq 'HASH' ? shift->{record} : shift;
    my $matcher = pica_field_matcher(@_);

    # modify in_place
    splice @$fields, 0, @$fields, grep {!$matcher->($_)} @$fields;
}

sub pica_update {
    my $fields = reftype $_[0] eq 'HASH' ? shift->{record} : shift;
    if (@_ == 2) {
        my $path    = PICA::Path->new(shift);
        my $sfregex = $path->{subfield} or croak "missing subfields";
        my $value   = shift // '';

        for (my $i = 0; $i < @$fields; $i++) {
            if ($path->match_field($fields->[$i])) {
                my $f = $fields->[$i];
                if ($value ne '') {

                    # replace subfield value
                    my $append = $path->subfields =~ /^[A-Za-z0-9]$/;
                    for (my $j = 2; $j < @$f; $j += 2) {
                        if ($f->[$j] =~ $sfregex) {
                            $f->[$j + 1] = $value;
                            $append = 0;
                        }
                    }
                    push @$f, $path->subfields, $value if $append;
                }
                else {
                    # remove subfield

                    my @sf;
                    for (my $j = 2; $j < @$f; $j += 2) {
                        push @sf, $f->[$j], $f->[$j + 1]
                            if $f->[$j] !~ $sfregex;
                    }
                    my $sfnum = @$f % 2 ? @$f - 3 : @$f - 2;
                    if (@sf && @sf < $sfnum) {
                        splice @$f, 2, $sfnum, @sf;
                    }
                    else {
                        # field is empty, so remove it
                        splice @$fields, $i--, 1;
                    }
                }
            }
        }
    }
    elsif (@_) {
        my $value = pica_field(@_);
        my $path  = PICA::Path->new($value->[0] . '/' . ($value->[1] // '0'));
        for (my $i = 0; $i < @$fields; $i++) {
            if ($path->match_field($fields->[$i])) {
                $fields->[$i] = $value;
            }
        }
    }
}

sub pica_subfields {
    my @sf;
    for (@{pica_fields(@_)}) {
        my $l = @$_ % 2 ? $#$_ - 1 : $#$_;
        push @sf, @{$_}[2 .. $l];
    }
    return Hash::MultiValue->new(@sf);
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
    my $holdings = pica_holdings(@_);

    my @items;
    foreach (@$holdings) {
        my @fields = grep {$_->[0] =~ /^2/} @{$_->{record}};

        while (@fields) {
            my (@record, $epn);
            my $occ = 1 * $fields[0]->[1];
            while (@fields && 1 * $fields[0]->[1] == $occ) {
                if ($fields[0]->[0] eq '203@') {
                    ($epn) = $EPN_PATH->match_subfields($fields[0]);
                }
                push @record, shift @fields;
            }
            push @items, bless {record => \@record, _id => $epn},
                'PICA::Data';
        }
    }

    return \@items;
}

sub pica_sort {
    my ($record) = $_[0];

    my $sorted = pica_title($record);

    for my $holding (@{pica_holdings($record)}) {
        push @{$sorted->{record}}, @{$holding->{record}},;
    }

    return $sorted;
}

sub sort_fields {
    sort {sprintf("%s/%02d", @$a) cmp sprintf("%s/%02d", @$b)} @{$_[0]};
}

sub cmp_level2 {
    my ($occA, $occB) = map {1 * $_->[1]} @_;
    return $occA == $occB ? $_[0]->[0] cmp $_[1]->[0] : $occA <=> $occB;
}

sub pica_title {
    my ($fields) = @_;

    my $record = {record => [sort_fields(pica_fields($_[0], "0.../*"))]};

    my $ppn = pica_value($record, '003@0');
    $record->{_id} = $ppn if defined $ppn;

    return bless $record, 'PICA::Data';
}

sub pica_holdings {

    # ignore level 0 fields
    my @fields = grep {$_->[0] =~ /^[12]/}
        @{reftype $_[0] eq 'HASH' ? $_[0]->{record} : $_[0]};

    my @holdings;

    # level 2 fields without preceding level 1
    if (@fields) {
        my @item;
        while (@fields && $fields[0]->[0] =~ /^2/) {
            push @item, shift @fields;
        }
        if (@item) {
            push @holdings, {record => [sort {cmp_level2($a, $b)} @item]};
        }
    }

    while (@fields) {
        my $iln;
        my (@level1, @level2);

        # consecutive level 1 fields (possibly split by multiple 101@)
        while (@fields && $fields[0]->[0] =~ /^1/) {
            my $field = shift @fields;

            if ($field->[0] eq '101@') {
                if (defined $iln) {
                    push @holdings,
                        {record => [sort_fields(\@level1)], _id => $iln};
                    @level1 = ();
                }
                ($iln) = $ILN_PATH->match_subfields($field);
            }

            push @level1, $field;
        }

        #@level1 = sort_fields(\@level1) if @level1;

        while (@fields && $fields[0]->[0] =~ /^2/) {
            push @level2, shift @fields;
        }

        push @holdings,
            {
            record =>
                [sort_fields(\@level1), sort {cmp_level2($a, $b)} @level2],
            _id => $iln
            };
    }

    bless $_, 'PICA::Data' for @holdings;

    return \@holdings;
}

sub pica_split {
    my ($record, $level) = @_;

    my @records;
    @records = pica_title($record) unless $level > 0;
    return @records if $level eq '0';

    my @ppn = @{pica_fields($record, '003@')};

    for my $hold (@{pica_holdings($record)}) {
        if ($level eq '1') {
            unshift @{$hold->{record}}, @ppn;
            push @records, $hold;
        }
        else {
            my $items = pica_items($hold);
            if ($level eq '2') {
                my @iln = @{pica_fields($hold, '101@')};
                for my $item (@$items) {
                    unshift @{$item->{record}}, @ppn, @iln;
                    push @records, $item;
                }
            }
            else {
                # limit holding record to level1 fields
                $hold->{record}
                    = [grep {substr($_->[0], 0, 1) eq 1} @{$hold->{record}}];
                push @records, $hold, @$items;
            }
        }
    }

    return grep {@{pica_fields($_)} > 0} @records;
}

sub pica_string {
    my ($pica, $type, %options) = @_;
    my $string = "";
    $type ||= 'plain';
    $options{fh} = \$string;
    $options{start} //= 0;
    pica_writer($type => %options)->write($pica)->end;
    return decode('UTF-8', $string);
}

sub pica_id {
    return $_[0]->{_id} if reftype $_[0] eq 'HASH';
}

sub pica_empty {
    my $fields = reftype $_[0] eq 'HASH' ? $_[0]->{record} : $_[0];
    return !@$fields;
}

sub pica_annotation {
    return PICA::Data::Field::annotation(@_);
}

*parse_subfield_schedule = *PICA::Schema::parse_subfield_schedule;

sub pica_sort_subfields {
    my ($field, $schedule) = @_;
    $schedule = parse_subfield_schedule($schedule) unless ref $schedule;

    my @spec = grep {exists $_->{order}} map {
        {%{$schedule->{$_}}, code => $_}
    } keys %$schedule;

    my $sf = pica_subfields([$field]);
    splice @$field, 2;

    for my $sfdef (sort {$a->{order} cmp $b->{order}} @spec) {
        my $code   = $sfdef->{code};
        my @values = $sf->get_all($code);
        next unless @values;

        if ($sfdef->{repeatable}) {
            push @$field, $code, $_ for @values;
        }
        else {
            push @$field, $code, $values[0];
        }
    }

    return @$field > 2 ? $field : undef;
}

*fields    = *pica_fields;
*subfields = *pica_subfields;
*title     = *pica_title;
*holdings  = *pica_holdings;
*items     = *pica_items;
*sort      = *pica_sort;
*split     = *pica_split;
*match     = *pica_match;
*value     = *pica_value;
*values    = *pica_values;
*string    = *pica_string;
*id        = *pica_id;
*empty     = *pica_empty;
*diff      = *pica_diff  = *PICA::Patch::pica_diff;
*patch     = *pica_patch = *PICA::Patch::pica_patch;
*append    = *pica_append;
*remove    = *pica_remove;
*update    = *pica_update;

use PICA::Data::Field;
use PICA::Patch;
use PICA::Parser::XML;
use PICA::Parser::Plus;
use PICA::Parser::Plain;
use PICA::Parser::Binary;
use PICA::Parser::PPXML;
use PICA::Parser::PIXML;
use PICA::Parser::JSON;
use PICA::Writer::XML;
use PICA::Writer::Plus;
use PICA::Writer::Plain;
use PICA::Writer::Import;
use PICA::Writer::Binary;
use PICA::Writer::PPXML;
use PICA::Writer::PIXML;
use PICA::Writer::JSON;
use PICA::Writer::Generic;

sub pica_parser {
    _pica_module('PICA::Parser', @_);
}

sub pica_writer {
    if (lc $_[0] eq 'generic') {
        shift;
        return PICA::Writer::Generic->new(@_);
    }
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
        'Binary' => ($pica =~ tr/\x{1F}//),
        'XML'    => ($pica =~ tr/<//),
        'JSON'   => ($pica =~ tr/[{[]//),
        'NL'     => ($pica =~ tr/[\r\n]//),
        'IS3'    => ($pica =~ tr/\x{1D}//),
    );
    $count{$_} > $count{$format} and $format = $_
        for qw(Plain Binary XML JSON);

    if ($format eq 'Binary') {
        $format = 'Plus' if $count{NL} > $count{IS3};
    }
    elsif ($format eq 'XML') {
        $format = 'PPXML' if $pica =~ qr{xmlns/ppxml-1\.0};
    }

    $format ? "PICA::Parser::$format" : undef;
}

sub _pica_module {
    my $base = shift;
    my $type = lc(shift) // '';

    if ($type =~ /^(pica)?plus|norm(alized)$/) {
        "${base}::Plus"->new(@_);
    }
    elsif ($type eq 'binary') {
        "${base}::Binary"->new(@_);
    }
    elsif ($type =~ /^(pica)?plain$/) {
        "${base}::Plain"->new(@_);
    }
    elsif ($type eq 'import') {
        "${base}::Import"->new(@_);
    }
    elsif ($type =~ /^(pica)?xml$/) {
        "${base}::XML"->new(@_);
    }
    elsif ($type =~ /^(pica)?ppxml$/) {
        "${base}::PPXML"->new(@_);
    }
    elsif ($type =~ /^pixml$/) {
        "${base}::PIXML"->new(@_);
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
    $writer = pica_writer(@_ ? @_ : 'plain') unless blessed $writer;
    $writer->write($pica);
}

sub TO_JSON {
    my $record = shift;
    $record = $record->{record} if reftype $record eq 'HASH';
    return [map {blessed $_ ? $_->TO_JSON : $_} @$record];
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
    return bless {_id => $id, record => $record}, 'PICA::Data';
}

1;
__END__

=head1 NAME

PICA::Data - PICA record processing

=begin markdown 

[![Linux build status](https://github.com/gbv/PICA-Data/actions/workflows/linux.yml/badge.svg)](https://github.com/gbv/PICA-Data/actions/workflows/linux.yml)
[![Linux build status](https://github.com/gbv/PICA-Data/actions/workflows/linux.yml/badge.svg)](https://github.com/gbv/PICA-Data/actions/workflows/linux.yml)
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

        # object accessors
        my $ppn      = $record->id;
        my $ppn      = $record->value('003@0');
        my $ppn      = $record->subfields('003@')->{0};
        my $ddc      = $record->match('045Ue', split => 1, nested_array => 1);
        my $holdings = $record->holdings;
        my $items    = $record->items;
        ...

        # write record
        $writer->write($record);
        
        # write methods
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

PICA::Data provides methods, classes, functions, and L<a command line
application|picadata> to process L<PICA+ records|http://format.gbv.de/pica>.

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

=head2 pica_data( [ $data ] )

Return a new PICA::Data object from any guessable serialization form (or die).

=head2 pica_field( $tag, [$occ,] [ @subfields ] )

Return a new PICA+ field as blessed L<PICA::Data::Field> array reference (or
die).

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

=item

L<PICA::Parser::PIXML> for type C<pixml> (PICA FOLIO Import XML)

=back

=head2 pica_guess( $data )

Guess PICA serialization format from input data. Returns name of the
corresponding parser class or C<undef>.

=head2 pica_xml_struct( $xml, %options )

Convert PICA-XML, expressed in L<XML::Struct> structure into a PICA::Data object.

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

L<PICA::Writer::Import> for type C<import> (PICA Import format)

=item 

L<PICA::Writer::Plus> for type C<plus> or C<picaplus> (normalized PICA+)

=item

L<PICA::Writer::JSON> for type C<json> (PICA JSON)

=item 

L<PICA::Writer::XML> for type C<xml> or C<picaxml> (PICA-XML)

=item

L<PICA::Writer::PPXML> for type C<ppxml> (PicaPlus-XML)

=item

L<PICA::Writer::PIXML> for type C<pixml> (PICA FOLIO Import XML)

=back

=head2 pica_string( $record [, $type [, @options] ] )

Stringify a record with given writer (C<plain> as default) and options.

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
    $record->values($path);

=head2 pica_fields( $record[, $path...] )

Returns a PICA record (or empty array reference) limited to fields optionally
specified by PICA path expressions. The following are virtually equivalent:

    pica_fields($record, $path);
    $path->record_fields($record);
    $record->fields($path);

=head2 pica_subfields( $record[, $path...] )

Returns a L<Hash::MultiValue> of all subfields of fields optionally specified
by PICA path expressions. Also available as accessor C<subfields>.

=head2 pica_title( $record )

Returns the record limited to level 0 fields ("title record") in sorted order.

=head2 pica_holdings( $record )

Returns a list (as array reference) of local holding records, sorted by ILN.
Level2 fields are included in sorted order. The ILN (if given) is available as
C<_id>. Also available as accessor C<holdings>.

=head2 pica_items( $record )

Returns a list (as array reference) of item records. The EPN (if given) is
available as C<_id> Also available as accessor C<items>.

=head2 pica_split( $record [, $level ])

Returns the record splitted into individual records for each level. Optionally
limits result to given level, including identifiers (PPN/ILN) of higher levels.

=head2 pica_sort( $record )

Returns a copy of the record with sorted fields (first level 1 fields, then
level 2 fields not belonging to a level 1, then level 1, each followed by level
2 sorted by EPN). Also available as accessor C<sort>. 

=head2 pica_sort_subfields( $field, $schedule )

Sorts and filters subfields of a PICA field (given as array reference) with an
L<subfield schedule|https://format.gbv.de/schema/avram/specification#subfield-schedule>.
The schedule can also be given as string of subfield codes, parsed with
L<parse_subfield_schedule|PICA::Schema/parse_subfield_schedule>: repeatable
subfields must be marked with C<*> or C<+>, otherwise or only the first
subfield of this code is preserved. Undefined and missing subfields are ignored
as well as subfield without information about its order. Returns the modified
field, unless it is empty.

=head2 pica_annotation( $field [, $annotation ] )

Get or set a PICA field annotation. Use C<undef> to remove annotation.

=head2 pica_diff( $before, $after )

Return the difference between two records as annotated record. Also available
as method C<diff>. See L<PICA::Patch> for details.

=head2 pica_patch( $record, $diff )

Return a new record by application of a difference given as annotated PICA.
Also available as method C<patch>. See L<PICA::Patch> for details.

=head2 pica_append( $record, $tag, [$occurrence,] @subfields )

Append a new field to the end of the record.

=head2 pica_update( $record, ... )

Change an existing field. This method can be used like method C<append> or with
two arguments (path and value) to replace, add or remove a subfield value.

=head2 pica_remove( $record, $path [, $path..] )

Remove all fields matching given PICA Path expressions. Subfields and positions
in the path are ignored.

=head2 pica_split( $level )

Reduce and split record to given level except for identifiers PPN/ILN. Returns
a list of records.

=head1 ACCESSORS

All accessors of C<PICA::Data> are also available as L</FUNCTIONS>, prefixed
with C<pica_> (see L</SYNOPSIS>).

=head2 match( $path, %options )

Extract the subfield values from a PICA record based on a L<PICA::Path>
expression and options (see method C<match> of PICA::Path).

=head2 values( $path )

Extract a list of subfield values from a PICA record based on a L<PICA::Path>
expression.

=head2 value( $path )

Same as C<values> but only returns the first value.

=head2 fields( [$path...] )

Returns a PICA record limited to fields specified in a L<PICA::Path>
expression.  Always returns an array reference.

=head2 subfields( [$path...] )

Returns a L<Hash::MultiValue> of all subfields of fields optionally specified
by PICA path expressions.

=head2 holdings

Returns a list (as array reference) of local holding records (level 1 and 2),
where the id of each record contains the ILN (subfield C<101@a>).

=head2 items

Returns a list (as array reference) of item records (level 1),
where the id of each record contains the EPN (subfield C<203@/**0>).

=head2 id

Returns the record id, if given.

=head2 empty

Tell whether the record is empty (no fields).

=head2 split($level)

Reduce and split the record into title record (level=0), holding records
(level=1) or copy/item records (level=2). PPN and ILN are included for level 1
and 2 respectively.

=head1 METHODS

=head2 write( [ $type [, @options] ] | $writer )

Write PICA record with given L<PICA::Writer::...|PICA::Writer::Base> or
L<PICA::Writer::Plain> by default. This are equivalent:

    pica_writer( xml => $file )->write( $record );
    $record->write( xml => $file );

=head2 string( [ $type ] )

Serialize PICA record in a given format (C<plain> by default). This method can
also be used as function C<pica_string>.

=head2 append( $tag, [$occurrence,] @subfields )

Add a field to the end of the record. An occurrence can be specified as part of
the tag or as second argument. Subfields with empty value are ignored, so the
following are equivalent:

    $record->append('037A/01', a => 'hello', b => 'world', x => undef, y => '');
    $record->append('037A', 1, a => 'hello', b => 'world');

To simplify migration from L<PICA::Record> the field may also be given as
instance of L<PICA::Field> but this feature may be removed in a future version.

=head2 remove( $path [, $path..] )

Remove all fields matching given PICA Path expressions. Subfields and positions
are ignored so far.

=head2 update( ... )

Can be used like method C<append> but replaces an existing field. Alternatively
changes selected subfields if called with two arguments:

    $record->update('012X$a', 1); # set or add subfield $a to 1, keep other subfields

Setting a subfield value to the empty string or C<undef> removes the subfield.

=head2 diff( $record )

Calculate the difference of the record to another record.

=head2 patch( $diff )

Calculate a new record by application of an annotated PICA record. Annotations
C<+> and C<-> denote fields to be added or removed. Fields with blank
annotations are check to exist in the original record.

The records should not contain multiple records of level 1 and/or level 2.

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
