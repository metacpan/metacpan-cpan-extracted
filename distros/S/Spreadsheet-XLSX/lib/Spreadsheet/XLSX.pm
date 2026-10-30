package Spreadsheet::XLSX;

use 5.006000;
use strict;
use warnings;

use base 'Spreadsheet::ParseExcel::Workbook';

our $VERSION = '0.20';

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

    $shared_info{shared_strings}= __load_shared_strings($zip, $shared_info{converter});
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
    my $workbook_xml = __member_contents($member_workbook);
    if ($workbook_xml =~ /date1904="1"/) {
        $self->{Flg1904} = 1;
    }

    foreach ($workbook_xml =~ /\<(.*?)\/?\>/g) {

        /^(\w+)\s+/;

        my ($tag, $other) = ($1, $');

        my @pairs = split /\" /, $other;

        $tag eq 'sheet' or next;

        my $sheet = {
            MaxRow => 0,
            MaxCol => 0,
            MinRow => 1000000,
            MinCol => 1000000,
        };

        foreach ($other =~ /(\S+=".*?")/gsm) {

            my ($k, $v) = split /=?"/;    #"

            if ($k eq 'name') {
                $sheet->{Name} = $v;
                $sheet->{Name} = $shared_info->{converter}->convert($sheet->{Name}) if defined $shared_info->{converter};
            } elsif ($k eq 'r:id') {

                $sheet->{path} = $shared_info->{rels}->{$v};

            }

        }

        my $wsheet = Spreadsheet::ParseExcel::Worksheet->new(%$sheet);
        $self->{Worksheet}[$self->{SheetCount}] = $wsheet;
        $self->{SheetCount} += 1;

    }


    foreach my $sheet (@{$self->{Worksheet}}) {

        my $member_sheet = $zip->memberNamed("xl/$sheet->{path}") or next;

        my ($row, $col);

        my $parsing_v_tag = 0;
        my $s    = 0;
        my $s2   = 0;
        my $sty  = 0;
        my $sheet_xml = __member_contents($member_sheet);
        foreach ($sheet_xml =~ /(\<.*?\/?\>|.*?(?=\<))/g) {
            if (/^<c(?:\s|\/?>)/) {

                my ($reference) = /\sr="([^"]*)"/;
                ($row, $col) = __decode_cell_name($reference);

                $s   = m/t=\"s\"/      ? 1  : 0;
                $s2  = m/t=\"str\"/    ? 1  : 0;
                $sty = m/s="([0-9]+)"/ ? $1 : 0;

            } elsif (/^<v>/) {
                $parsing_v_tag = 1;
            } elsif (/^<\/v>/) {
                $parsing_v_tag = 0;
            } elsif (length($_) && $parsing_v_tag) {
                my $v = $s ? $shared_info->{shared_strings}->[$_] : $_;

                if ($v eq "</c>") {
                    $v = "";
                }
                my $type      = "Text";
                my $thisstyle = "";

                if (not($s) && not($s2)) {
                    $type = "Numeric";

                    if (defined $sty && defined $shared_info->{styles}->[$sty]) {
                        $thisstyle = $shared_info->{style_info}->{$shared_info->{styles}->[$sty]};
                        if ($thisstyle =~ /\b(mmm|m|d|yy|h|hh|mm|ss)\b/) {
                            $type = "Date";
                        }
                    }
                }


                $sheet->{MaxRow} = $row if $sheet->{MaxRow} < $row;
                $sheet->{MaxCol} = $col if $sheet->{MaxCol} < $col;
                $sheet->{MinRow} = $row if $sheet->{MinRow} > $row;
                $sheet->{MinCol} = $col if $sheet->{MinCol} > $col;

                if ($v =~ /(.*)E\-(.*)/gsm && $type eq "Numeric") {
                    $v = $1 / (10**$2);    # this handles scientific notation for very small numbers
                }

                my $cell = Spreadsheet::ParseExcel::Cell->new(
                    Val    => $v,
                    Format => $thisstyle,
                    Type   => $type
                );

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
    my ($reference) = @_;
    die "Invalid XLSX cell reference\n"
        unless defined($reference)
        && $reference =~ /\A([A-Z]{1,3})([1-9][0-9]{0,6})\z/;
    my ($letters, $digits) = ($1, $2);
    die "XLSX cell row exceeds worksheet limit\n" if $digits > 1048576;

    my $col = 0;
    $col = $col * 26 + ord($_) - ord('A') + 1 for split //, $letters;
    die "XLSX cell column exceeds worksheet limit\n" if $col > 16384;

    return ($digits - 1, $col - 1);
}


sub __load_shared_strings {
    my ($zip, $converter) = @_;

    my $member_shared_strings = $zip->memberNamed('xl/sharedStrings.xml');

    my @shared_strings = ();

    if ($member_shared_strings) {

        my $mstr = __member_contents($member_shared_strings);
        $mstr =~ s/<t\/>/<t><\/t>/gsm;    # this handles an empty t tag in the xml <t/>
        foreach my $si ($mstr =~ /<si.*?>(.*?)<\/si/gsm) {
            my $str;
            foreach my $t ($si =~ /<t.*?>(.*?)<\/t/gsm) {
                $t = $converter->convert($t) if defined $converter;
                $str .= $t;
            }
            push @shared_strings, $str;
        }
    }

    return \@shared_strings;
}


sub __load_styles {
    my ($zip) = @_;

    my $member_styles = $zip->memberNamed('xl/styles.xml');

    my @styles = ();
    my %style_info = ();

    if ($member_styles) {
        my $formatter = Spreadsheet::XLSX::Fmt2007->new();
        my $styles_xml = __member_contents($member_styles);

        # IDs from both format declarations and style references are data,
        # never regular-expression syntax.
        foreach my $id ($styles_xml =~ /\bnumFmtId="([^"]*)"/g) {
            die "Invalid XLSX number format ID\n" unless $id =~ /\A[0-9]+\z/;
        }

        foreach my $t ($styles_xml =~ /xf\ numFmtId="([^"]*)"(?!.*\/cellStyleXfs)/gsm) {    #"
            push @styles, $t;
        }

        my $default = $1 || '';
    
        foreach my $t1 (@styles) {
            $styles_xml =~ /numFmtId="\Q$t1\E" formatCode="([^"]*)/;
            my $formatCode = $1 || '';
            if ($formatCode eq $default || not($formatCode)) {
                if ($t1 == 9 || $t1 == 10) {
                    $formatCode = '0.00000%';
                } elsif ($t1 == 14) {
                    $formatCode = 'yyyy-mm-dd';
                } else {
                    $formatCode = '';
                }
#                $formatCode = $formatter->FmtStringDef($t1);
            }
            $style_info{$t1} = $formatCode;
            $default = $1 || '';
        }

    }
    return (\@styles, \%style_info);
}


sub __load_rels {
    my ($zip) = @_;

    my $member_rels = $zip->memberNamed('xl/_rels/workbook.xml.rels') or die("xl/_rels/workbook.xml.rels not found in this zip\n");

    my %rels = ();

    my $rels_xml = __member_contents($member_rels);
    foreach ($rels_xml =~ /\<Relationship (.*?)\/?\>/g) {

        my ($id, $target);
        ($id) = /Id="(.*?)"/;
        ($target) = /Target="(.*?)"/;
 
	    if (defined $id and defined $target) {	
    		$rels{$id} = $target;
        }

    }

    return \%rels;
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
        
        foreach my $row ($sheet->{MinRow} .. $sheet->{MaxRow}) {
             
            $sheet->{MaxCol} ||= $sheet->{MinCol};
            
            foreach my $col ($sheet->{MinCol} ..  $sheet->{MaxCol}) {
            
                my $cell = $sheet->{Cells}[$row][$col];
        
                if ($cell) {
                    printf("( %s , %s ) => %s\n", $row, $col, $cell->{Val});
                }
        
            }
        
        }
    
    }

=head1 DESCRIPTION

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

This module is a (quick and dirty) emulation of L<Spreadsheet::ParseExcel> for 
Excel 2007 (.xlsx) file format.  It supports styles and many of Excel's quirks, 
but not all.  It populates the classes from L<Spreadsheet::ParseExcel> for interoperability; 
including Workbook, Worksheet, and Cell.

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

=item Spreadsheet::ConvertAA

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

Dmitry Ovsyanko, E<lt>do@eludia.ruE<gt>, http://eludia.ru/wiki/

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
