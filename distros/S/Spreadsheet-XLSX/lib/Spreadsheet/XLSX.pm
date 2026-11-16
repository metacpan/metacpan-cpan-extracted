package Spreadsheet::XLSX;

use 5.006000;
use strict;
use warnings;

use base 'Spreadsheet::ParseExcel::Workbook';

our $VERSION = '0.21';

our $MAX_MEMBER_SIZE = 64 * 1024 * 1024;
our $MAX_TOTAL_SIZE  = 256 * 1024 * 1024;
our $MAX_MEMBERS     = 10000;

use Archive::Zip;
use Spreadsheet::ParseExcel;
use Spreadsheet::XLSX::Fmt2007;

################################################################################

sub new {
    my ($class, $filename, $converter) = @_;

    my %shared_info;    # shared_strings, styles, style_info, rels, converter
    $shared_info{converter} = $converter;
    
    my $self = bless Spreadsheet::ParseExcel::Workbook->new(), $class;

    my $zip                     = __load_zip($filename);

    $shared_info{phonetics} = {};
    $shared_info{shared_strings}= __load_shared_strings($zip, $shared_info{converter}, $shared_info{phonetics});
    my ($styles, $style_info)   = __load_styles($zip);
    $shared_info{styles}        = $styles;
    $shared_info{style_info}    = $style_info;
    $shared_info{rels}          = __load_rels($zip);

    $self->_load_workbook($zip, \%shared_info);

    return $self;
}

sub _load_workbook {
    my ($self, $zip, $shared_info) = @_;

    my $member_workbook = $zip->memberNamed('xl/workbook.xml') or die("xl/workbook.xml not found in this zip\n");
    $self->{SheetCount} = 0;
    $self->{FmtClass}   = Spreadsheet::XLSX::Fmt2007->new;
    $self->{Flg1904}    = 0;
    my $workbook_xml = __xml_contents($member_workbook);
    if ($workbook_xml =~ /date1904="1"/) {
        $self->{Flg1904} = 1;
    }

    foreach ($workbook_xml =~ /\<(.*?)\/?\>/g) {

        my ($tag, $attributes) = /^(\w+)\s+(.*)$/s;
        next unless defined($tag) && $tag eq 'sheet';

        my $sheet = {
            MaxRow => 0,
            MaxCol => 0,
            MinRow => 1000000,
            MinCol => 1000000,
        };

        foreach ($attributes =~ /(\S+=".*?")/gsm) {

            my ($k, $v) = split /=?"/;    #"

            if ($k eq 'name') {
                $sheet->{Name} = __decode_xml_text($v);
                $sheet->{Name} = $shared_info->{converter}->convert($sheet->{Name}) if defined $shared_info->{converter};
                die "XLSX worksheet name conversion failed: the converter returned undef\n"
                    unless defined $sheet->{Name};
            } elsif ($k eq 'r:id') {

                $sheet->{_RelationshipId} = $v;
                my $relation = $shared_info->{rels}->{$v};
                $sheet->{path} = $relation->{Target} if $relation;

            }

        }

        my $wsheet = Spreadsheet::ParseExcel::Worksheet->new(%$sheet);
        $self->{Worksheet}[$self->{SheetCount}] = $wsheet;
        $self->{SheetCount} += 1;

    }


    foreach my $sheet (@{$self->{Worksheet}}) {

        my $id = $sheet->{_RelationshipId};
        my $context = "worksheet '" . __diagnostic_text($sheet->{Name})
            . "', relationship '" . __diagnostic_text($id) . "'";
        my $relation = defined($id) ? $shared_info->{rels}->{$id} : undef;
        die "Missing XLSX relationship for $context in xl/_rels/workbook.xml.rels\n"
            unless $relation;
        die "External XLSX target '" . __diagnostic_text($relation->{Target})
            . "' is not supported for $context\n"
            if defined($relation->{TargetMode}) && $relation->{TargetMode} eq 'External';
        # Keep the chartsheet placeholder without interpreting chart XML as cells.
        next if defined($relation->{Type}) && $relation->{Type} =~ m{/chartsheet\z};
        my $part = __resolve_part_target('xl/workbook.xml', $relation->{Target}, $context);
        my $member_sheet = $zip->memberNamed($part)
            or die "XLSX target '" . __diagnostic_text($relation->{Target})
                . "' for $context resolves to missing ZIP member '$part'\n";

        my ($row, $col);

        my $parsing_v_tag = 0;
        my $s    = 0;
        my $s2   = 0;
        my $sty  = 0;
        my $inline = 0;
        my $parsing_inline = 0;
        my $inline_xml = '';
        my @column_styles;
        my $row_style;
        my $sheet_xml = __xml_contents($member_sheet);
        foreach ($sheet_xml =~ /(\<.*?\/?\>|.*?(?=\<))/gs) {
            if (/^<col(?:\s|\/?>)/) {
                my %attributes = /\b(min|max|style)="([^"]*)"/g;
                if (defined $attributes{style}) {
                    my ($min, $max) = @attributes{qw(min max)};
                    die "Invalid XLSX column style range in '" . $member_sheet->fileName() . "'\n"
                        unless defined($min) && defined($max)
                            && $min =~ /\A[0-9]+\z/ && $max =~ /\A[0-9]+\z/
                            && $min >= 1 && $min <= $max && $max <= 16384;
                    die "Invalid XLSX column style index\n"
                        unless $attributes{style} =~ /\A[0-9]+\z/;
                    $column_styles[$_ - 1] = $attributes{style} for $min .. $max;
                }
                next;
            } elsif (/^<row(?:\s|\/?>)/) {
                my %attributes = /\b(s|customFormat)="([^"]*)"/g;
                $row_style = undef;
                if (defined($attributes{s}) && defined($attributes{customFormat})
                    && $attributes{customFormat} =~ /\A(?:1|true)\z/) {
                    die "Invalid XLSX row style index\n" unless $attributes{s} =~ /\A[0-9]+\z/;
                    $row_style = $attributes{s};
                }
                $row_style = undef if /\/>$/;
                next;
            } elsif (/^<\/row\s*>/) {
                $row_style = undef;
                next;
            }
            if (/^<c(?:\s|\/?>)/) {

                my ($reference) = /\sr="([^"]*)"/;
                ($row, $col) = __decode_cell_name($reference,
                    "worksheet '" . __diagnostic_text($sheet->{Name}) . "' (" . $member_sheet->fileName() . ")");

                $s   = m/t=\"s\"/      ? 1  : 0;
                $s2  = m/t=\"str\"/    ? 1  : 0;
                my ($cell_style) = /\bs="([0-9]+)"/;
                $sty = defined($cell_style) ? $cell_style
                    : defined($row_style) ? $row_style
                    : defined($column_styles[$col]) ? $column_styles[$col] : 0;

                $inline = /\bt="inlineStr"/ ? 1 : 0;
                $parsing_v_tag = 0;
                $parsing_inline = 0;
                $inline_xml = '';
                next;
            }

            if ($inline) {
                if (/^<is(?:\s[^<>]*?)?\s*\/?>$/) {
                    $inline_xml = '';
                    $parsing_inline = !/\/>$/;
                    next if $parsing_inline;
                } elsif ($parsing_inline) {
                    if (/^<\/is\s*>$/) {
                        $parsing_inline = 0;
                    } else {
                        $inline_xml .= $_;
                        next;
                    }
                } else {
                    next;
                }
            } else {
                if (/^<v(?:\s[^<>]*?)?>$/) {
                    $parsing_v_tag = !/\/>$/;
                    next;
                } elsif (/^<\/v>/) {
                    $parsing_v_tag = 0;
                    next;
                }
                next unless length($_) && $parsing_v_tag;
            }

            {
                my ($v, $phonetics);
                if ($inline) {
                    ($v, $phonetics) = __parse_string($inline_xml, $shared_info->{converter});
                } else {
                    $v = $s ? $shared_info->{shared_strings}->[$_] : $_;
                    $phonetics = $shared_info->{phonetics}->{$_} if $s;
                }

                if (defined($v) && $v eq "</c>") {
                    $v = "";
                }
                my $type      = "Text";
                my $thisstyle = "";

                if (not($s) && not($s2) && not($inline)) {
                    $type = "Numeric";

                    if (defined $sty && defined $shared_info->{styles}->[$sty]) {
                        $thisstyle = $shared_info->{style_info}->{$shared_info->{styles}->[$sty]};
                        # Literal text and escaped characters are not date tokens.
                        my $date_format = Spreadsheet::XLSX::Utility2007::unescape_HTML($thisstyle);
                        # Keep token boundaries when removing literal separators.
                        $date_format =~ s/"[^"]*"|\\.|_.|\*./ /g;
                        if ($date_format =~ /\b(?:m{1,5}|d{1,4}|y{2,4}|h{1,2}|s{1,2}|(?i:am\/pm|a\/p))\b/) {
                            $type = "Date";
                        }
                    }
                }


                $sheet->{MaxRow} = $row if $sheet->{MaxRow} < $row;
                $sheet->{MaxCol} = $col if $sheet->{MaxCol} < $col;
                $sheet->{MinRow} = $row if $sheet->{MinRow} > $row;
                $sheet->{MinCol} = $col if $sheet->{MinCol} > $col;

                if ($type eq "Numeric" && defined($v) && $v =~ /(.*)E\-(.*)/gsm) {
                    $v = $1 / (10**$2);    # this handles scientific notation for very small numbers
                }

                my $cell = Spreadsheet::ParseExcel::Cell->new(
                    Val    => $v,
                    Format => $thisstyle,
                    Type   => $type
                );

                if ($phonetics) {
                    $cell->{RPh} = [map { { %$_ } } @{$phonetics->{RPh}}]
                        if exists $phonetics->{RPh};
                    $cell->{PhoneticPr} = { %{$phonetics->{PhoneticPr}} }
                        if exists $phonetics->{PhoneticPr};
                }

                $cell->{_Value} = $self->{FmtClass}->ValFmt($cell, $self);
                if ($type eq "Date") {
                    if ($v < 1) {    #then this is Excel time field
                        $cell->{Type} = "Text";
                        $cell->{Val}  = $cell->{_Value};
                    }
                }
                $sheet->{Cells}[$row][$col] = $cell;
            }
        }

        $sheet->{MinRow} = 0 if $sheet->{MinRow} > $sheet->{MaxRow};
        $sheet->{MinCol} = 0 if $sheet->{MinCol} > $sheet->{MaxCol};

    }

    return $self;
}

# Validate before numeric conversion or using a reference as an array index.
# XLSX worksheets have at most 1,048,576 rows and 16,384 columns (XFD).

sub __decode_cell_name {
    my ($reference, $context) = @_;
    my $details = defined($reference) ? "'" . __diagnostic_text($reference) . "'" : '(missing r attribute)';
    $details .= " in $context" if defined $context;
    die "Invalid XLSX cell reference $details; expected an A1-style address from A1 to XFD1048576, not a defined name\n"
        unless defined($reference)
        && $reference =~ /\A([A-Z]{1,3})([1-9][0-9]{0,6})\z/;
    my ($letters, $digits) = ($1, $2);
    die "XLSX cell row exceeds worksheet limit: $details; maximum row is 1048576\n" if $digits > 1048576;

    my $col = 0;
    $col = $col * 26 + ord($_) - ord('A') + 1 for split //, $letters;
    die "XLSX cell column exceeds worksheet limit: $details; maximum column is XFD\n" if $col > 16384;

    return ($digits - 1, $col - 1);
}


sub __load_shared_strings {
    my ($zip, $converter, $phonetics) = @_;
    $phonetics = {} unless defined $phonetics;

    my $member_shared_strings = $zip->memberNamed('xl/sharedStrings.xml');

    my @shared_strings = ();

    if ($member_shared_strings) {

        my $mstr = __xml_contents($member_shared_strings);
        $mstr =~ s/<t\/>/<t><\/t>/gsm;    # this handles an empty t tag in the xml <t/>
        foreach my $si ($mstr =~ /<si.*?>(.*?)<\/si/gsm) {
            my ($text, $metadata) = __parse_string($si, $converter);
            $phonetics->{scalar @shared_strings} = $metadata if keys %$metadata;
            push @shared_strings, $text;
        }
    }

    return \@shared_strings;
}


# Shared strings (si) and inline strings (is) have the same text structure.
sub __parse_string {
    my ($xml, $converter) = @_;
    my %metadata;
    my @runs;
    foreach my $run ($xml =~ /(<rPh\b[^>]*>.*?<\/rPh\s*>)/gs) {
        my ($attributes, $text) = $run =~ /<rPh\b([^>]*)>(.*?)<\/rPh\s*>/s;
        push @runs, {
            %{__phonetic_attributes($attributes, qw(sb eb))},
            Val => __shared_string_text($text, $converter),
        };
    }
    $metadata{RPh} = \@runs if @runs;
    if ($xml =~ /<phoneticPr\b([^>]*)>/s) {
        $metadata{PhoneticPr} = __phonetic_attributes($1, qw(fontId type alignment));
    }
    # Phonetic runs contain their own t elements, not display text.
    $xml =~ s{<rPh\b[^>]*/>|<rPh\b[^>]*>.*?</rPh\s*>}{}gs;
    $xml =~ s{<t\b[^>]*/>}{<t></t>}gs;
    return (__shared_string_text($xml, $converter), \%metadata);
}

sub __shared_string_text {
    my ($xml, $converter) = @_;
    my $str = '';
    foreach my $text ($xml =~ /<t\b[^>]*>(.*?)<\/t\s*>/gs) {
        # Decode each XML fragment exactly once, before character conversion.
        # Decoding after concatenation would also reinterpret literal entities
        # assembled across rich-text runs.
        $text = __decode_xml_text($text);
        $text = $converter->convert($text) if defined $converter;
        die "XLSX text conversion failed: the converter returned undef\n"
            unless defined $text;
        $str .= $text;
    }
    return $str;
}

sub __decode_xml_text {
    my ($text) = @_;
    $text =~ s/&((?:amp|lt|gt|quot|apos)|\#[0-9]+|\#x[0-9A-Fa-f]+);/__xml_entity($1)/ge;
    return $text;
}

sub __xml_entity {
    my ($entity) = @_;
    return '&' if $entity eq 'amp';
    return '<' if $entity eq 'lt';
    return '>' if $entity eq 'gt';
    return '"' if $entity eq 'quot';
    return "'" if $entity eq 'apos';

    my $digits = substr($entity, 1);
    my $hex = $digits =~ s/\Ax//;
    $digits =~ s/\A0+//;
    $digits = '0' unless length $digits;
    my $error = "Invalid XML character reference '&" . __diagnostic_text($entity) . ";' in XLSX string\n";
    die $error if length($digits) > ($hex ? 6 : 7);
    my $code = $hex ? hex($digits) : 0 + $digits;
    die $error unless $code == 9 || $code == 10 || $code == 13
        || ($code >= 0x20 && $code <= 0xd7ff)
        || ($code >= 0xe000 && $code <= 0xfffd)
        || ($code >= 0x10000 && $code <= 0x10ffff);

    # ZIP XML and the optional converter use UTF-8 bytes, not Perl characters.
    # Keep numeric references consistent with literal UTF-8 text, without
    # adding an encoding-library dependency or changing the minimum Perl.
    return pack('C', $code) if $code < 0x80;
    return pack('C*', 0xc0 | ($code >> 6), 0x80 | ($code & 0x3f)) if $code < 0x800;
    return pack('C*', 0xe0 | ($code >> 12), 0x80 | (($code >> 6) & 0x3f),
        0x80 | ($code & 0x3f)) if $code < 0x10000;
    return pack('C*', 0xf0 | ($code >> 18), 0x80 | (($code >> 12) & 0x3f),
        0x80 | (($code >> 6) & 0x3f), 0x80 | ($code & 0x3f));
}

sub __phonetic_attributes {
    my ($xml, @fields) = @_;
    my %wanted = map { $_ => 1 } @fields;
    my %attributes;
    while ($xml =~ /([A-Za-z][A-Za-z0-9]*)\s*=\s*(?:"([^"]*)"|'([^']*)')/g) {
        my ($key, $value) = ($1, defined($2) ? $2 : $3);
        $attributes{ucfirst($key)} = $value if $wanted{$key};
    }
    return \%attributes;
}

sub __load_styles {
    my ($zip) = @_;

    my $member_styles = $zip->memberNamed('xl/styles.xml');

    my @styles = ();
    my %style_info = ();

    if ($member_styles) {
        my $formatter = Spreadsheet::XLSX::Fmt2007->new();
        my $styles_xml = __xml_contents($member_styles);

        # IDs from both format declarations and style references are data,
        # never regular-expression syntax.
        foreach my $id ($styles_xml =~ /\bnumFmtId="([^"]*)"/g) {
            die "Invalid XLSX number format ID\n" unless $id =~ /\A[0-9]+\z/;
        }

        foreach my $t ($styles_xml =~ /xf\ numFmtId="([^"]*)"(?!.*\/cellStyleXfs)/gsm) {    #"
            push @styles, $t;
        }

        foreach my $t1 (@styles) {
            # A repeated format ID still refers to the same explicit format.
            # List context avoids reusing $1 from an earlier successful match.
            my ($formatCode) = $styles_xml =~ /numFmtId="\Q$t1\E" formatCode="([^"]*)/;
            if (!defined($formatCode) || $formatCode eq '') {
                # Retain the existing General fallback for ID 0. Other
                # built-in IDs use the formatter's existing definition table.
                $formatCode = $t1 == 0 ? '' : ($formatter->FmtStringDef($t1, {}) || '');
            }
            $style_info{$t1} = $formatCode;
        }

    }
    return (\@styles, \%style_info);
}


sub __load_rels {
    my ($zip) = @_;

    my $member_rels = $zip->memberNamed('xl/_rels/workbook.xml.rels') or die("xl/_rels/workbook.xml.rels not found in this zip\n");

    my %rels = ();

    my $rels_xml = __xml_contents($member_rels);
    foreach ($rels_xml =~ /\<Relationship\s+(.*?)\/?\>/gs) {

        my %attributes = /\b(Id|Target|TargetMode|Type)="([^"]*)"/g;
	    if (defined $attributes{Id}) {
            $rels{$attributes{Id}} = \%attributes;
        }

    }

    return \%rels;
}

sub __resolve_part_target {
    my ($source, $target, $context) = @_;
    my $shown = defined($target) ? "'" . __diagnostic_text($target) . "'" : '(missing Target attribute)';
    die "Invalid XLSX package target $shown for $context\n"
        unless defined($target) && length($target)
            && $target !~ m{\A(?:[A-Za-z][A-Za-z0-9+.-]*:|//)|[\\?#]};
    $source =~ s{[^/]*\z}{};
    my @parts = $target =~ m{\A/} ? () : grep { length } split '/', $source;
    for my $segment (split '/', $target) {
        next if $segment eq '' || $segment eq '.';
        if ($segment eq '..') {
            die "XLSX package target $shown for $context escapes the package root\n" unless @parts;
            pop @parts;
        } else {
            push @parts, $segment;
        }
    }
    die "Invalid XLSX package target $shown for $context: no ZIP member path\n" unless @parts;
    return join '/', @parts;
}

sub __load_zip {
    my ($filename) = @_;

    my $zip = Archive::Zip->new();

    if (ref $filename) {
        $zip->readFromFileHandle($filename) == Archive::Zip::AZ_OK or die("Cannot open data as Zip archive");
    } else {
        $zip->read($filename) == Archive::Zip::AZ_OK or die("Cannot open $filename as Zip archive");
    }
    
    my @members = $zip->members();
    die "XLSX ZIP entry count exceeds limit\n" if @members > $MAX_MEMBERS;
    my $total = 0;
    foreach my $member (@members) {
        my $size = $member->uncompressedSize();
        die "XLSX ZIP member size exceeds limit\n" if $size > $MAX_MEMBER_SIZE;
        $total += $size;
        die "XLSX ZIP total size exceeds limit\n" if $total > $MAX_TOTAL_SIZE;
    }

    return $zip;
}

sub __diagnostic_text {
    my ($text) = @_;
    $text = '' unless defined $text;
    $text = substr($text, 0, 80) . '...' if length($text) > 80;
    $text =~ s/[\x00-\x1f\x7f]/?/g;
    return $text;
}

# Recognize only the markup needed for diagnostics. This is deliberately not
# a validating XML parser: it does not check nesting, entities or namespaces.
sub __xml_contents {
    my ($member) = @_;
    my $xml = __member_contents($member);
    my $name = __diagnostic_text($member->fileName());
    my %data_elements = map { $_ => 1 } qw(
        workbook sheets sheet worksheet sheetData row c v f is
        sst si r t rPh phoneticPr styleSheet numFmts numFmt cellStyleXfs cellXfs xf
        Relationships Relationship
    );
    pos($xml) = 0;
    while (pos($xml) < length($xml)) {
        next if $xml =~ /\G[^<]+/gc;
        my $offset = pos($xml);
        if (substr($xml, $offset, 4) eq '<!--') {
            next if $xml =~ /\G<!--.*?-->/gcs;
            die "Cannot parse XLSX XML member '$name': unterminated XML comment at byte $offset\n";
        }
        if (substr($xml, $offset, 9) eq '<![CDATA[') {
            next if $xml =~ /\G<!\[CDATA\[.*?\]\]>/gcs;
            die "Cannot parse XLSX XML member '$name': unterminated CDATA section at byte $offset\n";
        }
        if (substr($xml, $offset, 2) eq '<?') {
            next if $xml =~ /\G<\?.*?\?>/gcs;
            die "Cannot parse XLSX XML member '$name': unterminated processing instruction at byte $offset\n";
        }
        die "Cannot parse XLSX XML member '$name': DOCTYPE declarations are not supported\n"
            if $xml =~ /\G<!DOCTYPE\b/gc;
        $xml =~ /\G(<(?:[^<>"']|"[^"<]*"|'[^'<]*')*>)/gcs
            or die "Cannot parse XLSX XML member '$name': unterminated or malformed XML tag at byte $offset\n";
        my $tag = $1;
        my ($closing, $element, $attributes) = $tag =~ /\A<(\/?)([A-Za-z_][A-Za-z0-9_.:-]*)(.*?)>\z/s;
        die "Cannot parse XLSX XML member '$name': malformed XML tag at byte $offset\n"
            unless defined $element;
        my $valid = $closing ? $attributes =~ /\A\s*\z/
            : $attributes =~ /\A(?:\s+[A-Za-z_][A-Za-z0-9_.:-]*\s*=\s*(?:"[^"<]*"|'[^'<]*'))*\s*\/?\z/s;
        die "Cannot parse XLSX XML member '$name': malformed attributes in element '$element' at byte $offset\n"
            unless $valid;
        die "Unsupported namespace-prefixed element '" . __diagnostic_text($element)
            . "' in XLSX XML member '$name'. Prefixes can be valid XLSX, but are not supported by Spreadsheet::XLSX. Use Spreadsheet::ParseXLSX for namespace-prefixed files.\n"
            if $element =~ /:([^:]+)\z/ && $data_elements{$1};
    }
    return $xml;
}

# readChunk() limits compressed input, not inflated output. Small input chunks
# bound temporary inflate buffers; check output before appending it. Never trust
# central-directory sizes alone: actual output must not exceed the declared size.
sub __member_contents {
    my ($member) = @_;
    my $declared = $member->uncompressedSize();
    die "XLSX ZIP member size exceeds limit\n" if $declared > $MAX_MEMBER_SIZE;
    my $old_method = $member->desiredCompressionMethod(Archive::Zip::COMPRESSION_STORED);
    my $contents = '';
    my $ok = eval {
        die "Cannot read XLSX ZIP member\n" unless $member->rewindData() == Archive::Zip::AZ_OK;
        while (1) {
            my ($buffer, $status) = $member->readChunk(1024);
            die "Cannot read XLSX ZIP member\n"
                unless $status == Archive::Zip::AZ_OK || $status == Archive::Zip::AZ_STREAM_END;
            my $size = length($contents) + length($$buffer);
            die "XLSX ZIP member size exceeds limit\n" if $size > $MAX_MEMBER_SIZE;
            die "XLSX ZIP member size does not match metadata\n" if $size > $declared;
            $contents .= $$buffer;
            last if $status == Archive::Zip::AZ_STREAM_END;
        }
        die "XLSX ZIP member size does not match metadata\n" if length($contents) != $declared;
        1;
    };
    my $error = $@;
    $member->endRead();
    $member->desiredCompressionMethod($old_method);
    die $error unless $ok;
    return $contents;
}


1;
__END__

=head1 NAME

Spreadsheet::XLSX - Perl extension for reading MS Excel 2007 files.

=head1 SYNOPSIS

    use Text::Iconv;
    my $converter = Text::Iconv->new("utf-8", "windows-1251");
    
    # Text::Iconv is not really required.
    # This can be any object with the convert method. Or nothing.
    
    use Spreadsheet::XLSX;
    
    my $excel = Spreadsheet::XLSX->new('test.xlsx', $converter);
    
    foreach my $sheet (@{$excel->{Worksheet}}) {
    
        printf("Sheet: %s\n", $sheet->{Name});
        
        $sheet->{MaxRow} ||= $sheet->{MinRow};
        $sheet->{MaxCol} ||= $sheet->{MinCol};
        
        foreach my $row ($sheet->{MinRow} .. $sheet->{MaxRow}) {
             
            foreach my $col ($sheet->{MinCol} ..  $sheet->{MaxCol}) {
            
                my $cell = $sheet->{Cells}[$row][$col];
        
                if ($cell) {
                    printf("( %s , %s ) => %s\n", $row, $col, $cell->{Val});
                }
        
            }
        
        }
    
    }

=head1 DESCRIPTION

This module is a (quick and dirty) emulation of L<Spreadsheet::ParseExcel> for
Excel 2007 (.xlsx) file format.  It supports styles and many of Excel's quirks,
but not all.  It populates the classes from L<Spreadsheet::ParseExcel> for interoperability;
including Workbook, Worksheet, and Cell.

=head1 NUMBER FORMATS

Built-in number formats use the formatter's definition table; explicit
custom format codes take precedence. C<value()> returns the formatted
representation, while numeric C<unformatted()> values retain the stored
number. For example, the number C<14> with format C<0.00> is displayed as
C<14.00> without changing its raw value.

An explicit cell style (including C<s="0">) overrides default styles.
Otherwise, a row style enabled by C<customFormat> takes precedence over a
column style, followed by the workbook's default cell style. These defaults
apply to cells read from the worksheet; empty cells are not synthesized.

=head1 STRING CELLS

Both shared strings (C<t="s">) and inline strings (C<t="inlineStr">)
are supported. Inline text is read from the cell's C<is> element without
requiring a shared-string table or a C<v> element. Rich-text runs are
concatenated in order, whitespace is preserved, and the optional converter
is applied to each text fragment for both string representations.

The five predefined XML entities (C<&amp;>, C<&lt;>, C<&gt;>, C<&quot;>,
C<&apos;>) and decimal or hexadecimal character references are decoded
once per text fragment before the converter runs. Numeric references use
the same UTF-8 byte representation as literal text when no converter is
supplied. For example, C<&amp;lt;> becomes the literal text C<&lt;>, not
another decoded character. Invalid numeric XML character references cause
an exception. The same decoding applies to phonetic hint text.

=head1 PHONETIC HINTS

Phonetic hints in shared strings and inline strings are not included in C<value()> or
C<unformatted()>. Cells containing such strings expose the hints as
C<$cell-E<gt>{RPh}>, an array of hashes with C<Val>, C<Sb> (start offset)
and C<Eb> (end offset). The optional converter is applied to hint text as
well as ordinary cell text; offsets retain their original XLSX values.

If present, C<$cell-E<gt>{PhoneticPr}> contains C<FontId> and the optional
C<Type> and C<Alignment> properties. Metadata is copied for each cell.

=head1 LIMITATIONS AND PARSE ERRORS

Worksheet relationship targets are resolved relative to C<xl/workbook.xml>,
or from the ZIP package root when they begin with C</>. Dot segments are
normalized. Missing relationships, missing target members, paths escaping
the package root, and external worksheet targets cause an exception naming
the worksheet and relationship. External resources are never fetched.
Chartsheets remain empty worksheet placeholders; their chart data is not
interpreted as cell data.

ZIP input is limited to 10,000 entries, 64 MiB per uncompressed member, and
256 MiB of total declared uncompressed data, including unused members.
Members used by the parser are decompressed incrementally and their actual
sizes are checked against the limits and ZIP metadata. Exceeding a limit or
encountering inconsistent sizes raises an exception.

Applications needing different limits can scope them to a parsing operation:

    local $Spreadsheet::XLSX::MAX_MEMBER_SIZE = 128 * 1024 * 1024;
    local $Spreadsheet::XLSX::MAX_TOTAL_SIZE = 512 * 1024 * 1024;
    local $Spreadsheet::XLSX::MAX_MEMBERS = 20000;
    my $excel = Spreadsheet::XLSX->new($filename);

These limits bound uncompressed input, not the total memory used by parsed
cells and XML processing.

The module uses regular expressions to extract workbook data. It does
B<not> perform full XML validation or XLSX schema validation. Some obvious
syntax errors, such as malformed attributes or unterminated tags, comments
and CDATA sections, cause an exception naming the XML member and byte
position. Other malformed XML (for example, incorrectly nested elements
or invalid entity references) may not be detected. DTD declarations are
not supported. No external entities are loaded or expanded.

Unprefixed elements, including elements in the default SpreadsheetML
namespace, are supported. Explicit prefixes on recognized data elements, such as
C<x:worksheet> or C<p:Relationship>, cause an exception naming the element
and XML member. Such prefixes can be valid XLSX syntax; this is a limitation
of Spreadsheet::XLSX, not evidence that the file is invalid. Other extension elements continue to be ignored.
Namespace declarations and attributes such as C<r:id> remain supported.
Prefix declarations are not resolved or validated; recognition is based
on the local element names used by this parser. Use L<Spreadsheet::ParseXLSX> for valid XLSX files
using explicit element prefixes or when proper XML parsing is required.

Cell positions must use A1-style addresses within C<A1:XFD1048576>.
Defined names such as C<Artikelnummer1> cannot replace an address in a
cell's C<r> attribute. Missing or invalid addresses cause an exception
identifying the worksheet and XML member. The parser does not attempt to
repair malformed XML or infer positions from invalid addresses.

=head1 SEE ALSO

=over 2

=item L<Spreadsheet::ParseXLSX>

This module (Spreadsheet::XLSX) has some serious issues with the way it uses regexs for parsing the XML.
I would strongly encourage switching to L<Spreadsheet::ParseXLSX> which takes a more reliable approach.

=item L<Text::CSV_XS>, L<Text::CSV_PP>

=item L<Spreadsheet::ParseExcel>

=item L<Spreadsheet::ReadSXC>

=item L<Spreadsheet::BasicRead>

for xlscat likewise functionality (Excel only)

=item L<Spreadsheet::ConvertAA>

for an alternative set of C<cell2cr()> / C<cr2cell()> pair

=item L<Spreadsheet::Perl>

offers a Pure Perl implementation of a
spreadsheet engine. Users that want this format to be supported in
L<Spreadsheet::Read> are hereby motivated to offer patches. It's not high
on my todo-list.

=item xls2csv

L<https://metacpan.org/release/KEN/xls2csv-1.07> offers an alternative for my C<xlscat -c>,
in the xls2csv tool, but this tool focusses on character encoding
transparency, and requires some other modules.

=item L<Spreadsheet::Read>

read the data from a spreadsheet (interface module)

=back

=head1 AUTHOR

Dmitry Ovsyanko

Patches by:

	Steve Simms
	Joerg Meltzer
	Loreyna Yeung	
	Rob Polocz
	Gregor Herrmann
	H.Merijn Brand
	endacoe
	Pat Mariani
	Sergey Pushkin
	
=head1 ACKNOWLEDGEMENTS	

	Thanks to TrackVia Inc. (http://www.trackvia.com) for paying for Rob Polocz working time.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Dmitry Ovsyanko

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
