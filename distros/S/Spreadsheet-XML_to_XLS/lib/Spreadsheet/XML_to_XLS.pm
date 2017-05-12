package Spreadsheet::XML_to_XLS;
use strict;
use warnings;

our $VERSION = '0.02';

use XML::DOM;
use Spreadsheet::WriteExcel;

my $parser;
my $doc;
my $book;
my %styles;
my %styleStore;
my @colorPalette = ();
my %colorStore = ();

sub build {
    my (undef, $inputFile, $outputFile) = @_;
    die "Cen't open $inputFile" unless -r $inputFile;
    $parser = new XML::DOM::Parser;
    $doc = $parser->parsefile($inputFile);
    $book = Spreadsheet::WriteExcel->new($outputFile);
    %styles = &parse_styles($doc);
    %styleStore = ();

    %colorStore = ();
    $colorPalette[8]  = 'black';
    $colorPalette[9]  = 'white';
    $colorPalette[10] = 'red';
    $colorPalette[11] = 'lime';
    $colorPalette[12] = 'blue';
    $colorPalette[13] = 'yellow';
    $colorPalette[14] = 'magenta';
    $colorPalette[15] = 'cyan';
    $colorPalette[16] = 'brown';
    $colorPalette[17] = 'green';
    $colorPalette[18] = 'navy';
    $colorPalette[20] = 'purple';
    $colorPalette[22] = 'silver';
    $colorPalette[23] = 'gray';
    $colorPalette[53] = 'orange';

    foreach my $worksheet ($doc->getElementsByTagName("worksheet")) {
        my $wsheet = {};
        my $attr = $wsheet->{'attr'} = &get_attributes($worksheet);
        &extend_style($styles{"default"}, $wsheet->{'attr'}) if exists $styles{"default"};
        $attr->{'col'} = 0 unless exists $attr->{'col'} and $attr->{'col'} =~ /^\d+$/;
        $attr->{'row'} = 0 unless exists $attr->{'row'} and $attr->{'row'} =~ /^\d+$/;
        $attr->{'type'} = 'col' unless exists $attr->{'type'};
        $attr->{'name'} = '' unless exists $attr->{'name'};
        $wsheet->{'tag'} = 'worksheet';
        $wsheet->{'data'} = [];
        $wsheet->{'top'} = $wsheet;
        $wsheet->{'mapCells'} = {};
        $wsheet->{'widthCols'} = {};
        $wsheet->{'heightRows'} = {};
        $wsheet->{'images'} = [];
        $wsheet->{'charts'} = [];
        $wsheet->{'namedsets'} = {};
        &parse_a_set($worksheet, $wsheet);
        &calc_position($wsheet);
        &write_excel($wsheet);
    }
    $book->close();
}

sub calc_position {
    my $wsheet = shift;
    my $attr = $wsheet->{'attr'};
    $attr->{'col'} = 0 unless exists $attr->{'col'};
    $attr->{'row'} = 0 unless exists $attr->{'row'};
    $attr->{'maxcol'} = 0;
    $attr->{'maxrow'} = 0;
    if ($wsheet->{'tag'} eq 'cell') {
        $attr->{'maxcol'} = $attr->{'mincol'} = $attr->{'col'};
        $attr->{'maxrow'} = $attr->{'minrow'} = $attr->{'row'};
        if (exists $attr->{'colspan'} and $attr->{'colspan'} =~ /^(\d+)$/) {
            my $num = $1;
            if ($num > 1) {
                $attr->{'maxcol'} += $num - 1;
                delete $attr->{'align'} if exists $attr->{'align'};
                $attr->{'center_across'} = 1;
                for (my $col = $attr->{'mincol'} + 1; $col <= $attr->{'maxcol'}; $col++) {
                    my $hash = {};
                    $hash->{'top'} = $wsheet->{'top'};
                    $hash->{'tag'} = 'cell';
                    $hash->{'col'} = $col;
                    $hash->{'row'} = $attr->{'maxrow'};
                    %{$hash->{'attr'}} = %$attr;
                    $hash->{'attr'}->{'blank'} = 1;
                    $hash->{'top'}->{'mapCells'}->{$attr->{'minrow'}}->{$col} = $hash; 
                }
            }
        }
        $wsheet->{'top'}->{'mapCells'}->{$attr->{'minrow'}}->{$attr->{'mincol'}} = $wsheet; 
    }
    if (exists $wsheet->{'data'}) {
        unless (exists $attr->{'type'}) {
            if ($wsheet->{'parent'}->{'attr'}->{'type'} eq 'col') {
                $attr->{'type'} = 'row';
            } else {
                $attr->{'type'} = 'col';
            }
        }
        my $curcol = $attr->{'col'};
        my $currow = $attr->{'row'};
        foreach my $child (@{$wsheet->{'data'}}) {
            my $cattr = $child->{'attr'};
            &calc_start_for_child($cattr, 'col', $curcol);
            &calc_start_for_child($cattr, 'row', $currow);
            &calc_position($child);
            $attr->{'maxcol'} = $cattr->{'maxcol'} if $attr->{'maxcol'} < $cattr->{'maxcol'};
            $attr->{'maxrow'} = $cattr->{'maxrow'} if $attr->{'maxrow'} < $cattr->{'maxrow'};
            if ($attr->{'type'} eq 'col') {
                $currow = $attr->{'maxrow'} + 1;
            } else {
                $curcol = $attr->{'maxcol'} + 1;
            }
        }
    }
    $attr->{'mincol'} = $attr->{'maxcol'} unless exists $attr->{'mincol'};
    $attr->{'minrow'} = $attr->{'maxrow'} unless exists $attr->{'minrow'};
    if (exists $wsheet->{'data'}) {
        foreach my $child (@{$wsheet->{'data'}}) {
            my $cattr = $child->{'attr'};
            $attr->{'mincol'} = $cattr->{'mincol'} if $attr->{'mincol'} > $cattr->{'mincol'};
            $attr->{'minrow'} = $cattr->{'minrow'} if $attr->{'minrow'} > $cattr->{'minrow'};
        }
    }
    if ($wsheet->{'tag'} eq 'set') {
        my %sattr = &attr_for_skipped_cell($wsheet);
        my $map = $wsheet->{'top'}->{'mapCells'};
        if (keys %sattr > 0) {
            for (my $row = $attr->{'minrow'}; $row <= $attr->{'maxrow'}; $row++) {
                for (my $col = $attr->{'mincol'}; $col <= $attr->{'maxcol'}; $col++) {
                    next if exists $map->{$row}->{$col};
                    my $hash = {};
                    $hash->{'tag'} = 'cell';
                    %{$hash->{'attr'}} = %sattr;
                    $map->{$row}->{$col} = $hash;
                }
            }
        }
        if (exists $attr->{'border_common'}) {
            my $border_common = $attr->{'border_common'};
            my $mincol = $attr->{'mincol'};
            my $maxcol = $attr->{'maxcol'};
            my $minrow = $attr->{'minrow'};
            my $maxrow = $attr->{'maxrow'};
            for (my $col = $mincol; $col <= $maxcol; $col++) {
                $map->{$minrow}->{$col}->{'attr'}->{'border_top'} = $border_common;
                $map->{$maxrow}->{$col}->{'attr'}->{'border_bottom'} = $border_common;
            }
            for (my $row = $minrow; $row <= $maxrow; $row++) {
                $map->{$row}->{$mincol}->{'attr'}->{'border_left'} = $border_common;
                $map->{$row}->{$maxcol}->{'attr'}->{'border_right'} = $border_common;
            }
            delete $attr->{'border_common'};
        }
        if (exists $attr->{'border_common_color'}) {
            my $border_common_color = $attr->{'border_common_color'};
            my $mincol = $attr->{'mincol'};
            my $maxcol = $attr->{'maxcol'};
            my $minrow = $attr->{'minrow'};
            my $maxrow = $attr->{'maxrow'};
            for (my $col = $mincol; $col <= $maxcol; $col++) {
                $map->{$minrow}->{$col}->{'attr'}->{'border_top_color'} = $border_common_color;
                $map->{$maxrow}->{$col}->{'attr'}->{'border_bottom_color'} = $border_common_color;
            }
            for (my $row = $minrow; $row <= $maxrow; $row++) {
                $map->{$row}->{$mincol}->{'attr'}->{'border_left_color'} = $border_common_color;
                $map->{$row}->{$maxcol}->{'attr'}->{'border_right_color'} = $border_common_color;
            }
            delete $attr->{'border_common_color'};
        }
        if ($wsheet->{'parent'}->{'tag'} eq 'worksheet') {
            foreach my $name (keys %{$wsheet->{'parent'}->{'namedsets'}}) {
                my $set = $wsheet->{'parent'}->{'namedsets'}->{$name};
                my $attr = $set->{'attr'};
                next if exists $attr->{'mincol'};
                if (exists $attr->{'col'} and not exists $attr->{'row'}) {
                    $attr->{'col'} = $set->{'parent'}->{'attr'}->{'mincol'} + $1 if $attr->{'col'} =~ /^\+(\d+)$/;
                    $attr->{'mincol'} = $attr->{'maxcol'} = $attr->{'col'};
                    $attr->{'minrow'} = $set->{'parent'}->{'attr'}->{'minrow'};
                    $attr->{'maxrow'} = $set->{'parent'}->{'attr'}->{'maxrow'};
                }
                if (not exists $attr->{'col'} and exists $attr->{'row'}) {
                    $attr->{'row'} = $set->{'parent'}->{'attr'}->{'minrow'} + $1 if $attr->{'row'} =~ /^\+(\d+)$/;
                    $attr->{'minrow'} = $attr->{'maxrow'} = $attr->{'row'};
                    $attr->{'mincol'} = $set->{'parent'}->{'attr'}->{'mincol'};
                    $attr->{'maxcol'} = $set->{'parent'}->{'attr'}->{'maxcol'};
                }
            }
        }
    }
}

sub calc_start_for_child {
    my ($cattr, $type, $cur) = @_;
    if (exists $cattr->{$type}) {
        unless ($cattr->{$type} =~ /^\d+$/) {
            if ($cattr->{$type} =~ /^\+(\d+)$/) {
                $cattr->{$type} = $cur + $1;
            } else {
                $cattr->{$type} = $cur;
            }
        }
    } else {
        $cattr->{$type} = $cur;
    }
}

sub parse_a_set {
    my ($elem, $parent) = @_;
    my $hash = &parse_a_node($elem, $parent, 'set');
    $hash->{'data'} = [];
    my @childs = &get_childs($elem);
    if (@childs > 0) {
        push @{$parent->{'data'}}, $hash;
        foreach my $item (@childs) {
            &parse_a_set($item->{'child'}, $hash) if lc $item->{'tag'} eq 'set';
            &parse_a_cell($item->{'child'}, $hash) if lc $item->{'tag'} eq 'cell';
            &parse_a_image($item->{'child'}, $hash) if lc $item->{'tag'} eq 'img';
            &parse_a_chart($item->{'child'}, $hash) if lc $item->{'tag'} eq 'chart';
        }
    }
    if (exists $hash->{'attr'}->{'name'}) {
        my $name = $hash->{'attr'}->{'name'};
        if ($name) {
            $hash->{'top'}->{'namedsets'}->{$name} = $hash if $hash->{'parent'}->{'tag'} eq 'set';
        }
    }
}

sub parse_a_cell {
    my ($elem, $parent) = @_;
    my $hash = &parse_a_node($elem, $parent, 'cell');
    push @{$parent->{'data'}}, $hash;
    $hash->{'value'} = &get_value($elem);
    if (exists $hash->{'attr'}->{'comment'}) {
        my $comment = {};
        $comment->{'data'} = $hash->{'attr'}->{'comment'};
        $comment->{'attr'} = {};
        $hash->{'attr'}->{'comment'} = $comment;
    }
    foreach my $item (&get_childs($elem)) {
        &parse_a_comment($item->{'child'}, $hash) if lc $item->{'tag'} eq 'comment';
        &parse_a_image($item->{'child'}, $hash) if lc $item->{'tag'} eq 'img';
    }    
}

sub parse_a_node {
    my ($elem, $parent, $tag) = @_;
    my $hash = {};
    $hash->{'parent'} = $parent;
    $hash->{'top'} = $parent->{'top'};
    $hash->{'tag'} = $tag;
    if ($parent->{'tag'} eq 'worksheet') {
        $hash->{'attr'} = $parent->{'attr'};
    } else {
        $hash->{'attr'} = &get_attributes($elem);
    }
    &parse_pos($hash->{'attr'}) if exists $hash->{'attr'}->{'pos'};

    my $style = &read_style($parent->{'attr'});
    if (exists $hash->{'attr'}->{'style'} ) {
        my $sname = $hash->{'attr'}->{'style'};
        $style = $styles{$sname};
    }
    &extend_style($style, $hash->{'attr'});
    return $hash;
}

sub parse_a_comment {
    my ($elem, $parent) = @_;
    my $hash = {};
    $hash->{'attr'} = &get_attributes($elem);
    $hash->{'data'} = &get_value($elem);
    $parent->{'attr'}->{'comment'} = $hash;
}

sub parse_a_image {
    my ($elem, $parent) = @_;
    my $hash = {};
    $hash->{'attr'} = &get_attributes($elem);
    $hash->{'parent'} = $parent;
    &parse_pos($hash->{'attr'}) if exists $hash->{'attr'}->{'pos'};
    push(@{$parent->{'top'}->{'images'}}, $hash);
}

sub parse_a_chart {
    my ($elem, $parent) = @_;
    my $hash = {};
    $hash->{'attr'} = &get_attributes($elem);
    if (exists $hash->{'attr'}->{'col'} and exists $hash->{'attr'}->{'row'}) {
        &get_pos($hash->{'attr'});
    }
    $hash->{'data'} = [];
    return unless exists $hash->{'attr'}->{'pos'};
    foreach my $item (&get_childs($elem)) {
        push @{$hash->{'data'}}, &get_attributes($item->{'child'}) if lc $item->{'tag'} eq 'data';
        $hash->{'title'} = &get_attributes($item->{'child'}) if lc $item->{'tag'} eq 'title';
        $hash->{'x_axis'} = &get_attributes($item->{'child'}) if lc $item->{'tag'} eq 'x_axis';
        $hash->{'y_axis'} = &get_attributes($item->{'child'}) if lc $item->{'tag'} eq 'y_axis';
    }    
    push(@{$parent->{'top'}->{'charts'}}, $hash);
}

# Save result in Excel doc
sub write_excel {
    my $wsheet = shift;
    my $sheet = $book->add_worksheet($wsheet->{'attr'}->{'name'});
    foreach my $row (keys %{$wsheet->{'top'}->{'mapCells'}}) {
        foreach my $col (keys %{$wsheet->{'top'}->{'mapCells'}->{$row}}) {
            next unless exists $wsheet->{'top'}->{'mapCells'}->{$row}->{$col};
            my $cell = $wsheet->{'top'}->{'mapCells'}->{$row}->{$col};
            next unless exists $cell->{'attr'};
            if (exists $cell->{'attr'}->{'width'}) {
                my $width = $cell->{'attr'}->{'width'};
                delete $cell->{'attr'}->{'width'};
                if ($width > 0) {
                    unless (exists $wsheet->{'widthCols'}->{$col}) {
                        $wsheet->{'widthCols'}->{$col} = $width;
                    } else {
                        $wsheet->{'widthCols'}->{$col} = $width if $width > $wsheet->{'widthCols'}->{$col}; 
                    }
                }
            }
            if (exists $cell->{'attr'}->{'height'}) {
                my $height = $cell->{'attr'}->{'height'};
                delete $cell->{'attr'}->{'height'};
                if ($height > 0) {
                    unless (exists $wsheet->{'heightRows'}->{$row}) {
                        $wsheet->{'heightRows'}->{$row} = $height;
                    } else {
                        $wsheet->{'heightRows'}->{$row} = $height if $height > $wsheet->{'heightRows'}->{$row}; 
                    }
                }
            }
        }
    }
    foreach my $col (keys %{$wsheet->{'widthCols'}}) {
        $sheet->set_column($col, $col, $wsheet->{'widthCols'}->{$col});
    }
    foreach my $row (keys %{$wsheet->{'heightRows'}}) {
        $sheet->set_row($row, $wsheet->{'heightRows'}->{$row});
    }
    foreach my $row (sort {$a <=> $b} keys %{$wsheet->{'top'}->{'mapCells'}}) {
        foreach my $col (sort {$a <=> $b} keys %{$wsheet->{'top'}->{'mapCells'}->{$row}}) {
            my $item = $wsheet->{'mapCells'}->{$row}->{$col};
            my $attr = $item->{'attr'};
            my $value = $item->{'value'};
            my $style = &read_style($item->{'attr'});
            &customise_style($style);
            my $id = &add_format($style);
            if (exists $item->{'attr'}->{'blank'}) {
                $sheet->write_blank($row, $col, $id);
            } else {
                $sheet->write($row, $col, $value, $id);
            }
            if (exists $attr->{'comment'}) {
                my $hash = $attr->{'comment'};
                $sheet->write_comment($attr->{'row'}, $attr->{'col'}, $hash->{'data'}, %{$hash->{'attr'}});
            }
        }
    }
    foreach my $image (@{$wsheet->{'images'}}) {
        my $cell = $image->{'parent'};
        my $attr = $image->{'attr'};
        my $row = (exists $attr->{'row'}) ? $attr->{'row'} : $cell->{'attr'}->{'row'};
        my $col = (exists $attr->{'col'}) ? $attr->{'col'} : $cell->{'attr'}->{'col'};
        my $src = $attr->{'src'};
        my $x = (exists $attr->{'x'} and $attr->{'x'} > 0) ? $attr->{'x'}: 0;
        my $y = (exists $attr->{'y'} and $attr->{'y'} > 0) ? $attr->{'y'}: 0;
        $sheet->insert_image($row, $col, $src, $x, $y);
    }
    foreach my $chart (@{$wsheet->{'charts'}}) {
        my $attr = $chart->{'attr'};
        my $pos = $chart->{'attr'}->{'pos'};
        my $x = (exists $chart->{'attr'}->{'x'}) ? $chart->{'attr'}->{'x'} : 0;
        my $y = (exists $chart->{'attr'}->{'y'}) ? $chart->{'attr'}->{'y'} : 0;
        my $width = (exists $chart->{'attr'}->{'width'}) ? $chart->{'attr'}->{'width'} : 1;
        my $height = (exists $chart->{'attr'}->{'height'}) ? $chart->{'attr'}->{'height'} : 1;
        next unless exists $chart->{'attr'}->{'type'};
        my $type = $chart->{'attr'}->{'type'};
        &get_pos($chart->{'attr'}) if exists $chart->{'attr'}->{'col'} and exists $chart->{'attr'}->{'row'};
        next unless exists $chart->{'attr'}->{'pos'};
        my $cattr = {};
        $cattr->{'embedded'} = 1;
        $cattr->{'type'} = $type;
        $cattr->{'name'} = $chart->{'attr'}->{'name'} if exists $chart->{'attr'}->{'name'};
        my $ch = $book->add_chart(%$cattr);
        foreach my $data (@{$chart->{'data'}}) {
            next unless exists $data->{'values'};
            $data->{'values'} = &check_if_named_set($data->{'values'}, $wsheet);
            $data->{'categories'} = &check_if_named_set($data->{'categories'}, $wsheet) if $data->{'categories'};
            $ch->add_series(%$data);
        }
        $ch->set_title(%{$chart->{'title'}}) if exists $chart->{'title'};
        $ch->set_x_axis(%{$chart->{'x_axis'}}) if exists $chart->{'x_axis'};
        $ch->set_y_axis(%{$chart->{'y_axis'}}) if exists $chart->{'y_axis'};
        $sheet->insert_chart($pos, $ch, $x, $y, $width, $height);
    }
}

sub check_if_named_set() {
    my ($values, $wsheet) = @_;
    if (exists $wsheet->{'top'}->{'namedsets'}->{$values}) {
        $values = &get_size_of_set($wsheet->{'top'}->{'namedsets'}->{$values});
    }
    return $values;
}

# Subroutines to parse XML::DOM tree
sub get_attributes {
    my $elem = shift;
    my %hash = %{$elem->getAttributes()};
    delete $hash{''} if exists $hash{''};
    my %attrs = map { $_ => $elem->getAttribute($_) } keys %hash;
    return \%attrs;
}

sub get_value {
    my $elem = shift;
    my $value = '';
    foreach my $child ($elem->getChildNodes()) {
        next unless $child->getNodeType() eq XML::DOM::TEXT_NODE;
        $value = $value . $child->getData();
    }
    my $attr = &get_attributes($elem);
    if (exists $attr->{'trunc'} and &parse_boolean($attr->{'trunc'}) eq 1 ) {
        $value = $` if $value =~ /\s+$/;
        $value = $' if $value =~ /^\s+/;
        $value =~ s/\n/ /g;
    }
    return $value;
}

sub get_childs {
    my $elem = shift;
    my @childs = ();
    foreach my $child ($elem->getChildNodes()) {
        next unless $child->getNodeType() eq XML::DOM::ELEMENT_NODE;
        my $tag = $child->getNodeName();
        push @childs, {'tag'=>$tag, 'child'=>$child};
    }
    return @childs;
}

# Service subroutines
sub parse_pos {
    my $ptr = shift;
    my $pos = uc $ptr->{'pos'};
    if ($pos =~ /([A-Z]{1,2})(\d+)/) {
        my $row = $2 - 1;
        my $col = $1;
        if ($col =~ /(\S)(\S)/) {
            $col = (ord($1) - ord('A') + 1) * 26 + ord($2) - ord('A');
        } else {
            $col = ord($col) - ord('A');
        }
        $ptr->{'row'} = $row;
        $ptr->{'col'} = $col;
        delete $ptr->{'pos'};
    }
}

sub get_pos {
    my $ptr = shift;
    $ptr->{'pos'} = &rowcol_to_pos($ptr->{'row'}, $ptr->{'col'}, 'pos');
    delete $ptr->{'row'};
    delete $ptr->{'col'};
}

sub rowcol_to_pos {
    my ($row, $col, $type) = @_;
    my $pos;
    $row++;
    my $up = int($col / 26);
    my $low = $col % 26;
    $low = chr($low + ord('A'));
    $low = chr($up + ord('A') - 1).$low if $up > 0;
    if ($type eq 'set') {
        $pos = '$'.$low.'$'.$row;
    } else {
        $pos = $low.$row;
    }
    return $pos;
}

sub get_size_of_set {
    my $ptr = shift;
    my $mincol = $ptr->{'attr'}->{'mincol'};
    my $maxcol = $ptr->{'attr'}->{'maxcol'};
    my $minrow = $ptr->{'attr'}->{'minrow'};
    my $maxrow = $ptr->{'attr'}->{'maxrow'};
    my $minpos = &rowcol_to_pos($minrow, $mincol, 'set');
    my $maxpos = &rowcol_to_pos($maxrow, $maxcol, 'set');
    return "$minpos:$maxpos";
}

sub read_style {
    my $attr = shift;
    my @styletags = (
        'font', 'size', 'color', 'bold', 'italic', 'underline', 
        'bg_color', 'fg_color',
        'width', 'height',
        'align', 'valign',
        'indent', 'wrap',
        'border', 'border_color',
        'border_top', 'border_bottom', 'border_left', 'border_right',
        'border_top_color', 'border_bottom_color', 'border_left_color', 'border_right_color',
        'center_across'
    );
    my $hash = {};
    foreach my $tag (@styletags) {
        $hash->{$tag} = $attr->{$tag} if exists $attr->{$tag};
    }
    return $hash;
}

sub attr_for_skipped_cell {
    my $wsheet = shift;
    my %sattr = ();
    my @styletags = (
        'bg_color', 'fg_color',
        'width', 'height',
        'border', 'border_color',
        'border_top', 'border_bottom', 'border_left', 'border_right',
        'border_top_color', 'border_bottom_color', 'border_left_color', 'border_right_color'
    );
    foreach my $tag (@styletags) {
        $sattr{$tag} = $wsheet->{'attr'}->{$tag} if exists $wsheet->{'attr'}->{$tag};
    }
    return %sattr;
}

sub customise_style {
    my $style = shift;
    $style->{'bold'} = &parse_boolean($style->{'bold'}) if exists $style->{'bold'};
    $style->{'italic'} = &parse_boolean($style->{'italic'}) if exists $style->{'italic'};
    $style->{'underline'} = &parse_boolean($style->{'underline'}) if exists $style->{'underline'};
    $style->{'wrap'} = &parse_boolean($style->{'wrap'}) if exists $style->{'wrap'};
    delete $style->{'wrap'} if exists $style->{'wrap'} and $style->{'wrap'} ne 1;

    $style->{'color'} = &parse_color($style->{'color'}) if exists $style->{'color'};
    $style->{'bg_color'} = &parse_color($style->{'bg_color'}) if exists $style->{'bg_color'};
    $style->{'fg_color'} = &parse_color($style->{'fg_color'}) if exists $style->{'fg_color'};
    $style->{'border_color'} = &parse_color($style->{'border_color'}) if exists $style->{'border_color'};

    $style->{'valign'} = 'vcenter' if exists $style->{'valign'} and $style->{'valign'} eq 'middle';
}

sub extend_style {
    my ($style, $attr) = @_;
    my %hash = %{$style};
    foreach my $key (keys %{&read_style($attr)}) {
        $hash{$key} = $attr->{$key};
    }
    foreach my $key (keys %hash) {
        $attr->{$key} = $hash{$key};
    }
}

sub add_format {
    my $style = shift;
    return if keys %$style == 0;
    my $key = join(' ', map {$_."='".$style->{$_}."'"} sort keys %$style);
    my $id;
    if (exists $styleStore{$key}) {
        $id = $styleStore{$key};
    } else {
        my $text_wrapping = 0;
        my $border_top = 0;
        my $border_bottom = 0;
        my $border_left = 0;
        my $border_right = 0;
        my $border_top_color;
        my $border_bottom_color;
        my $border_left_color;
        my $border_right_color;

        if (exists $style->{'wrap'} ) {
            $text_wrapping = 1;
            delete $style->{'wrap'};
        }
        if (exists $style->{'border_top'} ) {
            $border_top = $style->{'border_top'};
            delete $style->{'border_top'};
        }
        if (exists $style->{'border_bottom'} ) {
            $border_bottom = $style->{'border_bottom'};
            delete $style->{'border_bottom'};
        }
        if (exists $style->{'border_left'} ) {
            $border_left = $style->{'border_left'};
            delete $style->{'border_left'};
        }
        if (exists $style->{'border_right'} ) {
            $border_right = $style->{'border_right'};
            delete $style->{'border_right'};
        }
        if (exists $style->{'border_top_color'} ) {
            $border_top_color = $style->{'border_top_color'};
            delete $style->{'border_top_color'};
        }
        if (exists $style->{'border_bottom_color'} ) {
            $border_bottom_color = $style->{'border_bottom_color'};
            delete $style->{'border_bottom_color'};
        }
        if (exists $style->{'border_left_color'} ) {
            $border_left_color = $style->{'border_left_color'};
            delete $style->{'border_left_color'};
        }
        if (exists $style->{'border_right_color'} ) {
            $border_right_color = $style->{'border_right_color'};
            delete $style->{'border_right_color'};
        }

        $id = $book->add_format(%$style);
        $id->set_text_wrap() if $text_wrapping;
        $id->set_top($border_top) if $border_top;
        $id->set_bottom($border_bottom) if $border_bottom;
        $id->set_left($border_left) if $border_left;
        $id->set_right($border_right) if $border_right;

        $id->set_top_color($border_top_color) if $border_top_color;
        $id->set_bottom_color($border_bottom_color) if $border_bottom_color;
        $id->set_left_color($border_left_color) if $border_left_color;
        $id->set_right_color($border_right_color) if $border_right_color;

        $styleStore{$key} = $id;
    }
    return $id;
}

#<!ENTITY %boolean "(0|1|n|y|no|yes|false|true) 0">
sub parse_boolean {
    my $value = lc shift;
    my $res = 0;
    $res = 0 if $value eq 'n' or $value eq 'no' or $value eq 'false' or $value eq 'off';
    $res = 1 if $value eq 'y' or $value eq 'yes' or $value eq 'true' or $value eq 'on' or $value eq 1;
    return $res;
}

sub parse_color {
    my $color = lc shift;
    # Fill color table is the first time
    if (keys %colorStore == 0) {
        for (my $i = 8; $i < 64; $i++) {
            next unless $colorPalette[$i];
            $colorStore{$i} = $colorPalette[$i];
        }
    }
    return $color unless $color =~ /^\#[0-9a-f]{6}$/;
    return $colorStore{$color} if exists $colorStore{$color};
    for (my $i = 56; $i > 7; $i--) {
        next if $colorPalette[$i];
        $color =~ /^\#(\S\S)(\S\S)(\S\S)/;
        my $red = hex $1;
        my $green = hex $2;
        my $blue = hex $3;
        my $id = $book->set_custom_color($i, $red, $green, $blue);
        $colorPalette[$id] = $color;
        $colorStore{$color} = $id;
        return $id;
    }
    return 'red';
}

sub parse_styles {
    my $doc = shift;
    my %styles = ();

    foreach my $styleNode ($doc->getElementsByTagName("style")) {
        my $attr = &get_attributes($styleNode);
        next unless exists $attr->{"name"};
        $styles{$attr->{"name"}} = $attr;
    }
    return %styles unless keys %styles > 0;

    my $styleflag;
    do {
        $styleflag = 0;
        foreach my $name (keys %styles) {
            next unless exists $styles{$name}->{'extend'};
            my $sname = $styles{$name}->{'extend'};
            next if exists $styles{$sname}->{'extend'};
            &extend_style($styles{$sname}, $styles{$name});
            delete $styles{$name}->{'extend'};
            $styleflag = 1;
        }
    } while ($styleflag);

    foreach my $name (keys %styles) {
        $styles{$name} = &read_style($styles{$name});
    }
    return %styles;
}

#    Category   Description       Property        Method Name
#    --------   -----------       --------        -----------
#    Font       Font type         font            set_font()
#               Font size         size            set_size()
#               Font color        color           set_color()
#               Bold              bold            set_bold()
#               Italic            italic          set_italic()
#               Underline         underline       set_underline()
#               Strikeout         font_strikeout  set_font_strikeout()
#               Super/Subscript   font_script     set_font_script()
#               Outline           font_outline    set_font_outline()
#               Shadow            font_shadow     set_font_shadow()
#
#    Number     Numeric format    num_format      set_num_format()
#
#    Protection Lock cells        locked          set_locked()
#               Hide formulas     hidden          set_hidden()
#
#    Alignment  Horizontal align  align           set_align()
#               Vertical align    valign          set_align()
#               Rotation          rotation        set_rotation()
#               Text wrap         text_wrap       set_text_wrap()
#               Justify last      text_justlast   set_text_justlast()
#               Center across     center_across   set_center_across()
#               Indentation       indent          set_indent()
#               Shrink to fit     shrink          set_shrink()
#
#    Pattern    Cell pattern      pattern         set_pattern()
#               Background color  bg_color        set_bg_color()
#               Foreground color  fg_color        set_fg_color()
#
#    Border     Cell border       border          set_border()
#               Bottom border     bottom          set_bottom()
#               Top border        top             set_top()
#               Left border       left            set_left()
#               Right border      right           set_right()
#               Border color      border_color    set_border_color()
#               Bottom color      bottom_color    set_bottom_color()
#               Top color         top_color       set_top_color()
#               Left color        left_color      set_left_color()
#               Right color       right_color     set_right_color()

1;
