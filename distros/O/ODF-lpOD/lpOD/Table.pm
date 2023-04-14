#=============================================================================
#
#       Copyright (c) 2010 Ars Aperta, Itaapy, Pierlis, Talend.
#       Copyright (c) 2014 Jean-Marie Gouarné.
#       Author: Jean-Marie Gouarné <jean.marie.gouarne@online.fr>
#
#=============================================================================
use     5.010_001;
use     strict;
use     experimental    'smartmatch';
#=============================================================================
#	Tables and table components (columns, rows, cells, row/col groups)
#=============================================================================
package ODF::lpOD::Matrix;
use base 'ODF::lpOD::Element';
our $VERSION                    = '1.002';
use constant PACKAGE_DATE       => '2011-06-06T08:38:04';
use ODF::lpOD::Common;
use feature ':5.10';
#-----------------------------------------------------------------------------

use constant    ROW_FILTER      => 'table:table-row';
use constant    COLUMN_FILTER   => 'table:table-column';
use constant    CELL_FILTER     => qr'table:(covered-|)table-cell';
use constant    TABLE_FILTER    => 'table:table';

#-----------------------------------------------------------------------------

sub     set_group
        {
        my $self        = shift;
        my $type        = shift;
        my $start       = shift;
        my $end         = shift;
        unless ($start && $end)
                {
                alert "Range not valid"; return FALSE;
                }
        if ($start->after($end))
                {
                alert "Start element is not before end element";
                return FALSE;
                }
        unless ($start->is_child($self) && $end->is_child($self))
                {
                alert "Grouping not allowed"; return FALSE;
                }
        my $tag = ($type ~~ ['column', 'row']) ?
                        'table:table-' . $type . '-group'       :
                        'table:table-' . $type;
        my $group = ODF::lpOD::Element->create($tag);
        $group->paste_before($start);
        my @elts = (); my $e = $start;
        do      {
                push @elts, $e;
                $e = $e->next_sibling;
                }
                while ($e && ! $e->after($end));
        $group->group(@elts);
        my %opt         = @_;
        $group->set_attribute('display', odf_boolean($opt{display}));
        return $group;
        }

sub     get_group
        {
        my $self        = shift;
        my $type        = shift;
        my $position    = shift;
        return $self->child($position, 'table:table-' . $type . '-group');
        }

#-----------------------------------------------------------------------------

sub     get_size
        {
        my $self        = shift;
        my $height      = 0;
        my $width       = 0;
        my $row         = $self->first_row;
        my $max_h       = $self->att('#lpod:h');
        my $max_w       = $self->att('#lpod:w');
        while ($row)
                {
                $height += $row->get_repeated;
		if (wantarray)
			{
			my $row_width = $row->get_width;
			$width = $row_width if $row_width > $width;
			}
		last if ((defined $max_h) and ($height >= $max_h));
                $row = $row->next($self);
                }
        $height = $max_h if defined $max_h and $max_h < $height;
        return wantarray ? ($height, $width) : $height;
        }

sub     contains
        {
        my $self        = shift;
        my $expr        = shift;
        my $segment     = $self->first_descendant(TEXT_SEGMENT);
        while ($segment)
                {
                my %r = ();
                my $t = $segment->get_text;
                return $segment if $t =~ /$expr/;
                $segment = $segment->next_elt($self, TEXT_SEGMENT);
                }
        return FALSE;
        }

sub     table
        {
        my $self        = shift;
        return $self->is(TABLE_FILTER) ? $self : $self->parent(TABLE_FILTER);
        }

#=============================================================================
package ODF::lpOD::ColumnGroup;
use base 'ODF::lpOD::Matrix';
our $VERSION                    = '1.003';
use constant PACKAGE_DATE       => '2011-06-06T08:32:22';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     _create		{ ODF::lpOD::ColumnGroup->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller	= shift;
        return ODF::lpOD::Element->create('table:table-column-group', @_);
        }

#-----------------------------------------------------------------------------

sub     get_size
        {
        my $self        = shift;
        return $self->SUPER::get_size   if $self->isa('ODF::lpOD::Table');
        my $width = $self->get_column_count;
        my $t = $self->table;
        my $height = $t ? $t->get_length : undef;
        return wantarray ? ($height, $width) : $height;
        }

sub     all_columns
        {
        my $self        = shift;
        return $self->descendants(ODF::lpOD::Matrix->COLUMN_FILTER);
        }

sub     first_column
        {
        my $self        = shift;
        my $elt = $self->first_child(qr'(column$|column-group)')
                                        or return undef;
        if      ($elt->isa('ODF::lpOD::Column'))
					{ return $elt; }
        elsif   ($elt->isa('ODF::lpOD::ColumnGroup'))
					{ return $elt->first_column; }
        else
					{ return undef; }
        }

sub     last_column
        {
        my $self        = shift;
        my $elt = $self->last_child(qr'(column$|column-group)')
                                        or return undef;
        if      ($elt->isa('ODF::lpOD::Column'))
					{ return $elt; }
        elsif   ($elt->isa('ODF::lpOD::ColumnGroup'))
					{ return $elt->last_column; }
        else
					{ return undef; }
        }

sub     get_column_count
        {
        my $self        = shift;
        my $count       = 0;
        my $col         = $self->first_column;
        my $max_w       = $self->att('#lpod:w');
        while ($col)
                {
                $count += $col->get_repeated;
                $col = $col->next($self);
                }
        return (defined $max_w and $max_w < $count) ? $max_w : $count;
        }

sub     get_position
        {
        my $self        = shift;
        my $start = $self->first_column;
        return $start ? $start->get_position : undef;
        }

sub     _get_column
        {
        my $self        = shift;
        my $position    = shift;
        my $col = $self->first_column   or return undef;
        for (my $i = 0 ; $i < $position ; $i++)
                {
                $col = $col->next($self) or return undef;
                }
        return $col;
        }

#-----------------------------------------------------------------------------

sub     get_column
        {
        my $self        = shift;
        my $position    = alpha_to_num(shift) || 0;
        my $width       = $self->get_column_count;
        my $max_w       = $self->get_attribute('#lpod:w');
        my $filter      = ODF::lpOD::Matrix->COLUMN_FILTER;
        if ($position < 0)
                {
                $position += $width;
                }
        if (($position >= $width) || ($position < 0))
                {
                alert "Column position $position out of range";
                return undef;
                }
        my $col = $self->first_column or return undef;

        my $p = $position;
        my $r = $col->get_repeated;
        while ($p >= $r)
            {
            $p -= $r;
            $col = $col->next($self);
            $r = $col->get_repeated;
            }
        if ($self->rw and $col->repeat($r, $p))
            {
            $col = $self->get_column($position);
            }

        return $col;
        }

sub     get_columns
        {
        my $self        = shift;
        my $arg         = shift;
        my ($start, $end);
        if ($arg)
                {
                ($start, $end) = translate_range($arg, shift);
                }
        $start //= 0; $end //= $self->get_column_count() - 1;
        my @list = ();

        if ($self->ro)
                {
                my $col = $self->get_column($start);
                my $n = $end - $start;
                while ($n >= 0)
                        {
                        my $r = $col->get_repeated;
                        while ($r > 0 && $n >= 0)
                                {
                                push @list, $col;
                                $r--; $n--;
                                }
                        $col = $col->next($self);
                        }
                }
        else
                {
                for (my $i = $start ; $i <= $end ; $i++)
                        {
                        push @list, $self->get_column($i);
                        }
                }
        return @list;
        }

sub     add_column
        {
        my $self        = shift;
        my %opt         = process_options
                (
                number          => 1,
                propagate       => TRUE,
                @_
                );
        my $expand      = $opt{expand};
        my $propagate   = $opt{propagate};
        my $empty       = $opt{empty};
        my $cell_style  = $opt{cell_style};
        my $style       = $opt{style};
        my $col_filter  = ODF::lpOD::Matrix->COLUMN_FILTER;
        my $row_filter  = ODF::lpOD::Matrix->ROW_FILTER;
        my $position    = undef;
        my $ref_elt     = $opt{before} // $opt{after};
        my $set_style = exists $opt{style};
        my $set_cell_style = exists $opt{cell_style};
        unless (defined $ref_elt)
                {
                $position = 'after';
                }
        else
                {
                if (defined $opt{before} && defined $opt{after})
                        {
                        alert "'before' and 'after' are mutually exclusive";
                        return FALSE;
                        }
                $position = defined $opt{before} ? 'before' : 'after';
                $ref_elt = $self->get_column($ref_elt) unless ref $ref_elt;
                unless  (
                        $ref_elt->isa('ODF::lpOD::Column')
                                &&
                        $ref_elt->parent() == $self
                        )
                        {
                        alert "Wrong $position reference";
                        return FALSE;
                        }
                }
        my $number = $opt{number};
        return undef unless $number && ($number > 0);
        delete @opt
                {qw
                (number before after expand propagate empty style cell_style)
                };
        my $elt;
        unless ($ref_elt)
                {
                my $proto = $self->last_child($col_filter);
                if ($proto)
                        {
                        $elt = $proto->clone;
                        $elt->paste_after($proto);
                        }
                else
                        {
                        $elt = ODF::lpOD::Column->create(%opt);
                        $elt->paste_first_child($self);
                        }
                }
        else
                {
                $elt = $ref_elt->clone;
                $elt->paste($position, $ref_elt);
                }
        $elt->set_style($style) if $set_style;
        if ($number && $number > 1)
                {
                if (is_true($expand))
                        {
                        $elt->set_repeated(undef);
                        $elt->repeat($number);
                        }
                else
                        {
                        $elt->set_repeated($number);
                        }
                }
        else
                {
                $elt->set_repeated(undef);
                }
        if (is_true($propagate))
                {
                my $context = $self;
                my %opt =
                        (
                        number  => $number,
                        expand  => $expand,
                        empty   => $empty
                        );
                $opt{style} = $cell_style if $set_cell_style;
                my $hz_pos = $elt->get_position;
                $hz_pos-- if $position eq 'after';
                unless ($self->isa('ODF::lpOD::Table'))
                        {
                        $context = $self->parent('table:table');
                        }
                foreach my $row ($context->descendants($row_filter))
                        {
                        if ($position && ($hz_pos < $row->get_width))
                                {
                                $opt{$position} = $row->get_cell($hz_pos);
                                }
                        else
                                {
                                delete $opt{$position};
                                }
                        $row->add_cell(%opt);
                        }
                }
        return $elt;
        }

sub     delete_column
        {
        my $self        = shift;
        my $position    = shift;
        my %opt         =
                (
                propagate       => TRUE,
                @_
                );
        my $column;
        unless (ref $position)
                {
                $column = $self->get_column($position);
                }
        else
                {
                $column = $position;
                unless  (
                        $column->isa('ODF::lpOD::Column')
                                &&
                        $column->parent() == $self
                        )
                        {
                        alert "Column can't be deleted in this context";
                        return FALSE;
                        }
                $position = $column->get_position;
                }
        unless ($column && defined $position)
                {
                alert "Wrong column position"; return FALSE;
                }
        $column->ODF::lpOD::Element::delete;
        if ($opt{propagate})
                {
                my $row_filter = ODF::lpOD::Matrix->ROW_FILTER;
                my $context = $self;
                unless ($self->isa('ODF::lpOD::Table'))
                        {
                        $context = $self->parent('table:table');
                        }
                foreach my $row ($context->descendants($row_filter))
                        {
                        my $cell = $row->get_cell($position);
                        $cell && $cell->delete;
                        }
                }
        return TRUE;
        }

sub     set_column_group
        {
        my $self        = shift;
        my ($start, $end) = translate_range(shift, shift);
        my $e1 = $self->get_column($start);
        my $e2 = $self->get_column($end);
        return $self->set_group('column', $e1, $e2, @_);
        }

sub     get_column_group
        {
        my $self        = shift;
        return $self->get_group('column', @_);
        }

sub     get_cell
        {
        my $self        = shift;
        my ($r, $c) = translate_coordinates(@_);
        my $col = $self->get_column($c)    or return undef;
        return $col->get_cell($r);
        }

sub     get_cells
        {
        my $self	= shift;
        my ($r1, $c1, $r2, $c2) = translate_range(@_);
        my @cells = (); my $i = 0;

        foreach my $col ($self->get_columns($c1, $c2))
                {
                @{$cells[$i]} = $col->get_cells($c1, $c2); $i++;
                }
        return @cells;
        }

sub     collapse
        {
        my $self        = shift;
        $_->set_visibility('collapse') for $self->get_columns;
        }

sub     uncollapse
        {
        my $self        = shift;
        $_->set_visibility(undef) for $self->get_columns;
        }

sub     set_default_cell_style
        {
        my $self	= shift;
        my $style	= shift;
        $_->set_default_cell_style($style) for $self->all_columns;
        }

#-----------------------------------------------------------------------------

sub     clear
        {
        my $self        = shift;
        my %opt         = @_;
        $_->clear for $self->get_columns($opt{start}, $opt{end});
        }

#=============================================================================
package ODF::lpOD::RowGroup;
use base 'ODF::lpOD::Matrix';
our $VERSION                    = '1.005';
use constant PACKAGE_DATE       => '2011-06-06T08:37:31';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     _create  { ODF::lpOD::RowGroup->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller	= shift;
        return ODF::lpOD::Element->create('table:table-row-group', @_);
        }

#-----------------------------------------------------------------------------

sub     read_optimize
        {
        my $self	= shift;
        return $self->ro(shift);
        }

sub     all_rows
        {
        my $self        = shift;
        return $self->descendants(ODF::lpOD::Matrix->ROW_FILTER);
        }

sub     all_cells
        {
        my $self        = shift;
        return $self->descendants(ODF::lpOD::Matrix->CELL_FILTER);
        }

sub     empty_cells
        {
        my $self        = shift;
        $_->empty_cells for $self->all_rows;
        }

sub     clean
        {
        my $self        = shift;
        $_->clean() for $self->descendants(ODF::lpOD::Matrix->ROW_FILTER);
        }

sub     first_row
        {
        my $self        = shift;
        my $elt = $self->first_child(qr'(row$|row-group)') or return undef;
        if      ($elt->isa('ODF::lpOD::Row'))
						{ return $elt; }
        elsif   ($elt->isa('ODF::lpOD::RowGroup'))
						{ return $elt->first_row; }
        else
						{ return undef; }
        }

sub     last_row
        {
        my $self        = shift;
        my $elt = $self->last_child(qr'(row$|row-group)') or return undef;
        if      ($elt->isa('ODF::lpOD::Row'))
						{ return $elt; }
        elsif   ($elt->isa('ODF::lpOD::RowGroup'))
						{ return $elt->last_row; }
        else
						{ return undef; }
        }

sub     get_height
        {
        my $self        = shift;
        my $height      = 0;
        my $row         = $self->first_row;
        my $max_h       = $self->att('#lpod:h');
        while ($row)
                {
                $height += $row->get_repeated;
                $row = $row->next($self);
                }
        return (defined $max_h and $max_h < $height) ? $max_h : $height;
        }

sub     get_position
        {
        my $self        = shift;
        my $start = $self->first_row;
        return $start ? $start->get_position : undef;
        }

#-----------------------------------------------------------------------------

sub     _get_row
        {
        my $self        = shift;
        my $position    = shift;
        my $row = $self->first_row   or return undef;
        for (my $i = 0 ; $i < $position ; $i++)
                {
                $row = $row->next($self) or return undef;
                }
        return $row;
        }

sub     get_row
        {
        my $self        = shift;
        my $position    = alpha_to_num(shift) || 0;
        my $height      = $self->get_height;
        my $max_h       = $self->att('#lpod:h');
        unless (is_numeric($position))
                {
                $position = alpha_to_num($position);
                }
        if ($position < 0)
                {
                $position += $height;
                }
        if (($position >= $height) || ($position < 0))
                {
                alert "Row position $position out of range";
                return undef;
                }
        my $row = $self->first_row or return undef;
        my $p = $position;
        my $r = $row->get_repeated;
        while ($p >= $r)
                {
                $p -= $r;
                $row = $row->next($self);
                $r = $row->get_repeated;
                }
        if ($self->rw and $row->repeat($r, $p))
                {
                $row = $self->get_row($position);
                }

        return $row;
        }

sub     get_rows
        {
        my $self        = shift;
        my $arg         = shift;
        my ($start, $end);
        if ($arg)
                {
                ($start, $end) = translate_range($arg, shift);
                }
        $start //= 0; $end //= $self->get_size() - 1;
        my @list = ();

        if ($self->ro)
                {
                my $row = $self->get_row($start);
                my $n = $end - $start;
                while ($n >= 0 && $row)
                        {
                        my $r = $row->get_repeated;
                        while ($r > 0 && $n >= 0)
                                {
                                push @list, $row;
                                $r--; $n--;
                                }
                        $row = $row->next($self);
                        }
                }
        else
                {
                for (my $i = $start ; $i <= $end ; $i++)
                        {
                        push @list, $self->get_row($i);
                        }
                }
        return @list;
        }

sub     get_rows_by_index
        {
        my $self        = shift;
        my $index       = shift;
        my $filter      = shift;
        my @rownums = ();
        unless (defined $index)
                {
                alert "Missing arguments"; return undef;
                }
        my $pos = 0;
        my $match = FALSE;
        my $old_status = $self->read_optimize;
        $self->read_optimize(TRUE);
        for my $row ($self->get_rows)
                {
                my $cell = $row->get_cell($index) or next;
                my $v = $cell->get_value;
                unless (defined $v)
                        {
                        $match = TRUE unless (defined $filter);
                        }
                else
                        {
                        $match = TRUE if $v ~~ $filter;
                        }
                if ($match)
                        {
                        if (wantarray)
                                {
                                push @rownums, $pos;
                                $match = FALSE;
                                }
                        else
                                {
                                $self->read_optimize($old_status);
                                return $self->get_row($pos);
                                }
                        }
                $pos++;
                }
        $self->read_optimize($old_status);
        my @rows = ();
        push @rows, $self->get_row($_) for @rownums;
        return @rows;
        }

sub     get_row_by_index
        {
        my $self        = shift;
        return scalar $self->get_rows_by_index(@_);
        }

sub     add_row
        {
        my $self        = shift;
        my %opt         = process_options
                (
                number          => 1,
                expand          => TRUE,
                @_
                );
        my $empty       = $opt{empty};
        my $cell_style  = $opt{cell_style};
        my $style       = $opt{style};
        my $ref_elt     = $opt{before} // $opt{after};
        my $expand      = $opt{expand};
        my $set_style = exists $opt{style};
        my $set_cell_style = exists $opt{cell_style};
        my $position    = undef;
        unless (defined $ref_elt)
                {
                $position = 'after';
                }
        else
                {
                if (defined $opt{before} && defined $opt{after})
                        {
                        alert "'before' and 'after' are mutually exclusive";
                        return FALSE;
                        }
                $position = defined $opt{before} ? 'before' : 'after';
                $ref_elt = $self->get_row($ref_elt) unless ref $ref_elt;
                unless  (
                        $ref_elt->isa('ODF::lpOD::Row')
                                &&
                        $ref_elt->parent() == $self
                        )
                        {
                        alert "Wrong $position reference";
                        return FALSE;
                        }
                }
        my $number = $opt{number};
        return undef unless $number && ($number > 0);
        delete @opt{qw(number before after expand empty style cell_style)};
        my $elt;
        unless ($ref_elt)
                {
                my $proto = $self->last_child(ODF::lpOD::Matrix->ROW_FILTER);
                $elt = $proto ?
			$proto->clone() : ODF::lpOD::Row->create(%opt);
                }
        else
                {
                $elt = $ref_elt->clone;
                }
        $elt->empty_cells if is_true($empty);
        $elt->set_style($style) if $set_style;
        if ($set_cell_style)
                {
                $_->set_style($cell_style) for $elt->all_cells;
                }
        if ($ref_elt)
                {
                $elt->paste($position, $ref_elt);
                }
        else
                {
                $elt->paste_last_child($self);
                }
        if ($number && $number > 1)
                {
                if (is_true($expand))
                        {
                        $elt->set_repeated(undef);
                        $elt->repeat($number);
                        }
                else
                        {
                        $elt->set_repeated($number);
                        }
                }
        else
                {
                $elt->set_repeated(undef);
                }

        return $elt;
        }

sub     delete_row
        {
        my $self        = shift;
        my $position    = shift;
        my $row;
        if (ref $position)
                {
                $row = $position;
                unless  (
                        $row->isa('ODF::lpOD::Row')
                                &&
                        $row->parent() == $self
                        )
                        {
                        alert "Row can't be deleted in this context";
                        return FALSE;
                        }
                }
        else
                {
                $row = $self->get_row($position);
                }
        $row->delete;
        }

sub     set_row_group
        {
        my $self        = shift;
        my ($start, $end) = translate_range(shift, shift);
        my $e1 = $self->get_row($start);
        my $e2 = $self->get_row($end);
        return $self->set_group('row', $e1, $e2, @_);
        }

sub     get_row_group
        {
        my $self        = shift;
        return $self->get_group('row', @_);
        }

sub     get_cell
        {
        my $self        = shift;
        my ($r, $c) = translate_coordinates(@_);
        my $row = $self->get_row($r)    or return undef;
        return $row->get_cell($c);
        }

sub     get_cells
        {
        my $self	= shift;
        my ($r1, $c1, $r2, $c2) = translate_range(@_);
        my @cells = (); my $i = 0;
        foreach my $row ($self->get_rows($r1, $r2))
                {
                @{$cells[$i]} = $row->get_cells($c1, $c2); $i++;
                }
        return @cells;
        }

sub     get_cell_values
        {
        my $self	= shift;
        my $type        = shift;
        unless ($type)
                {
                alert "Missing cell data type"; return undef;
                }
        my ($r1, $c1, $r2, $c2) = translate_range(@_);
        my $old_status = $self->read_optimize;
        $self->read_optimize(TRUE);
        my $row;
        if (wantarray)
                {
                my @values = ();
                my $i = 0;
                foreach $row ($self->get_rows($r1, $r2))
                        {
                        foreach my $cell ($row->get_cells($c1, $c2))
                                {
                                my ($v, $t) = $cell->get_value;
                                $v = undef unless
                                        $t eq $type or $type eq 'all';
                                push @{$values[$i]}, $v;
                                }
                        $i++;
                        }
                $self->read_optimize($old_status);
                return @values;
                }
        else
                {
                my @cells = ();
                foreach $row ($self->get_rows($r1, $r2))
                        {
                        push @cells, $row->get_cells($c1, $c2);
                        }
                $self->read_optimize($old_status);
                return scalar
                        $self->ODF::lpOD::TableElement::_get_cell_values
                                                        ($type, @cells);
                }
        }

sub     get_text
        {
        my $self        = shift;
        my %opt         = @_;
        return $self->ODF::lpOD::Element::get_text(%opt)
                if is_true($opt{recursive});
        my $text;
        my $old_status = $self->read_optimize;
        $self->read_optimize(TRUE);
        for my $row ($self->get_rows)
                {
                for ($row->get_cells)
                        {
                        my $t = $_->get_value;
                        $text .= $t if defined $t;
                        }
                }
        $self->read_optimize($old_status);
        return $text;
        }

sub     collapse
        {
        my $self        = shift;
        $_->set_visibility('collapse') for $self->get_rows;
        }

sub     uncollapse
        {
        my $self        = shift;
        $_->set_visibility('visible') for $self->get_rows;
        }

sub     set_default_cell_style
        {
        my $self	= shift;
        my $style	= shift;
        $_->set_default_cell_style($style) for $self->all_rows;
        }

#-----------------------------------------------------------------------------

sub     clear
        {
        my $self        = shift;
        my %opt         = @_;
        if (is_true($opt{compact}))
                {
                my ($height, $width) = $self->get_size;
                $self->ODF::lpOD::Element::clear;
                my $row = ODF::lpOD::Row->create;
                $row->set_repeated($height);
                $row->paste_first_child($self);
                my $cell = ODF::lpOD::Cell->create;
                $cell->set_repeated($width);
                $cell->paste_first_child($row);
                }
        else
                {
                $_->clear(%opt) for $self->all_rows;
                }
        }

#=============================================================================
#       Tables
#-----------------------------------------------------------------------------
package ODF::lpOD::Table;
use base ('ODF::lpOD::RowGroup', 'ODF::lpOD::ColumnGroup');
our $VERSION                    = '1.002';
use constant PACKAGE_DATE       => '2011-06-06T08:46:58';
use ODF::lpOD::Common;
#=============================================================================
#--- constructor -------------------------------------------------------------

sub     _create         { ODF::lpOD::Table->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller	= shift;
        my $name        = shift;
        unless ($name)
                {
                alert "Missing table name";
                return FALSE;
                }

        my %opt = process_options
                (
                style           => undef,
                display         => undef,
                protected       => undef,
                key             => undef,
                @_
                );

        my $width       = $opt{width};
        my $height      = $opt{length} // $opt{height};
        unless (defined $width && defined $height)
                {
                ($height, $width) = input_2d_value($opt{size}, "");
                }
        $width  // 0; $height // 0;
        if ($width < 0 || $height < 0)
                {
                alert "Wrong table size ($height x $width)";
                return FALSE;
                }

        my $t = ODF::lpOD::Element->create('table:table');
        $t->set_attribute('name', $name);
        $t->set_attribute('style name', $opt{style});
        $t->set_attribute('protected', odf_boolean($opt{protected}));
        $t->set_attribute('protection key', $opt{key});
        $t->set_attribute('display', odf_boolean($opt{display}));
        $t->set_attribute('print', odf_boolean($opt{print}));
        $t->set_attribute('print ranges', $opt{print_ranges});

        $t->add_column(
                number          => $width,
                expand          => $opt{expand},
                propagate => FALSE
                );
        my $r = $t->add_row;
        unless (is_true($opt{expand}))
                {
                $r->add_cell()->set_repeated($width);
                $r->set_repeated($height);
                }
        else
                {
                $r->add_cell(number => $width, expand => TRUE);
                $r->repeat($height);
                }

        $t->set_default_cell_style($opt{cell_style}) if ($opt{cell_style});

        return $t;
        }

#--- special optimization ----------------------------------------------------

sub     set_working_area
        {
        my $self        = shift;
        my ($h, $w)     = @_;
        $self->set_attribute('#lpod:h' => $h);
        $self->set_attribute('#lpod:w' => $w);
        }

#-----------------------------------------------------------------------------

sub     set_column_header
        {
        my $self        = shift;
        if ($self->get_column_header)
                {
                alert "Column header already defined for this table";
                return FALSE;
                }
        my $number      = shift || 1;
        my $start       = $self->get_row(0);
        my $end         = $self->get_row($number > 1 ? $number-1 : 0);
        return $self->set_group('header-rows', $start, $end);
        }

sub     get_column_header
        {
        my $self        = shift;
        return $self->first_child('table:table-header-rows');
        }

sub     set_row_header
        {
        my $self        = shift;
        if ($self->get_row_header)
                {
                alert "Row header already defined for this table";
                return FALSE;
                }
        my $number      = shift || 1;
        my $start       = $self->get_column(0);
        my $end         = $self->get_column($number > 1 ? $number-1 : 0);
        return $self->set_group('header-columns', $start, $end);
        }

sub     get_row_header
        {
        my $self        = shift;
        return $self->first_child('table:table-header-columns');
        }

sub	set_default_cell_style
	{
	my $self	= shift;
	my $style	= shift;
	$_->set_default_cell_style($style)
		for ($self->all_rows, $self->all_columns);
	}

#-----------------------------------------------------------------------------

sub     get_cell_value
        {
        my $self	= shift;
        my $old_status = $self->read_optimize;
        my $cell = $self->get_cell(@_);
        $self->read_optimize($old_status);
        return wantarray ?
                ($cell->get_value(), $cell->get_type()) :
                $cell->get_value;
        }

#=============================================================================
package ODF::lpOD::TableElement;
use base 'ODF::lpOD::Element';
our $VERSION                    = '1.004';
use constant PACKAGE_DATE       => '2011-06-06T08:49:11';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     table
        {
        my $self	= shift;
        return $self->get_ancestor('table:table');
        }

sub     tro
        {
        my $self	= shift;
        my $table = $self->table or return FALSE;
        return is_true($table->ro);
        }

sub     trw
        {
        my $self	= shift;
        my $table = $self->table or return TRUE;
        return is_false($table->ro);
        }

sub     repeat
        {
        my $self        = shift;
        my $r		= shift // $self->get_repeated;
        return undef unless $r > 1;
        my $p		= shift;
        unless (defined $p)
                {
                $self->set_repeated(undef);
                return $self->SUPER::repeat($r);
                }
        else
                {
                if (($p < 0) or ($p >= $r))
                        {
                        return undef;
                        }
                elsif ($p == 0)
                        {
                        $self->set_repeated(undef);
                        my $c1 = $self->clone; $c1->paste_after($self);
                        $c1->set_repeated($r - 1);
                        }
                else
                        {
                        $self->set_repeated($p);
                        my $c1 = $self->clone; $c1->paste_after($self);
                        $c1->set_repeated(undef); $p++;
                        if ($p < $r)
                                {
                                my $c2 = $c1->clone; $c2->paste_after($c1);
                                $c2->set_repeated($r - $p);
                                }
                        }

                return TRUE;
                }
        }

sub     get_cell_value
        {
        my $self	= shift;
        my $table = $self->table;
        unless ($table)
                {
                alert "Not in table"; return undef;
                }
        my $old_status = $table->read_optimize;
        my $cell = $self->get_cell(@_);
        $table->read_optimize($old_status);
        return wantarray ?
                ($cell->get_value(), $cell->get_type()) :
                $cell->get_value;
        }

sub     _get_cell_values
        {
        my $self        = shift;
        my $type        = shift;
        my $col = $self->isa('ODF::lpOD::Column') ? TRUE : FALSE;
        my ($sum, $min, $max);
        my $count = 0;
        my @values = ();
        my $cf = $ODF::lpOD::Common::COMPARE;
        for my $cell (@_)
                {
                my ($v, $t) = $cell->get_value;
                next unless defined $v;
                next unless (($t eq $type) || ($type eq 'all'));
                my $rep = $col ? 1 : $cell->get_repeated;
                $count += $rep;
                if (wantarray)
                        {
                        push @values, $v;
                        }
                else
                        {
                        $min //= $v; $max //= $v;
                        given ($type)
                                {
                                when (['string', 'all'])
                                        {
                                        $min = $v if &$cf($min, $v) > 0;
                                        $max = $v if &$cf($max, $v) < 0;
                                        }
                                when (['date', 'time'])
                                        {
                                        $min = $v if $min gt $v;
                                        $max = $v if $max lt $v;
                                        }
                                when (['float', 'currency', 'percentage'])
                                        {
                                        $min = $v if $min > $v;
                                        $max = $v if $max < $v;
                                        $sum += ($v * $rep);
                                        }
                                when ('boolean')
                                        {
                                        if (is_true($v))        { $min++ }
                                        else                    { $max++ }
                                        }
                                }
                        }
                }
        return wantarray ? @values : [ $count, $min, $max, $sum ];
        }

sub     get_cell_values
        {
        my $self	= shift;
        my $table = $self->table;
        unless ($table)
                {
                alert "Not in table"; return undef;
                }
        my $type = shift;
        unless ($type)
                {
                alert "Missing cell data type"; return undef;
                }
        my $old_status = $table->read_optimize;
        $table->read_optimize(TRUE);
        my @cells = $self->get_cells(@_);
        $table->read_optimize($old_status);
        return $self->_get_cell_values($type, @cells);
        }

sub     set_default_cell_style
        {
        my $self	= shift;
        $self->set_attribute('table:default-cell-style-name' => shift);
        }

#-----------------------------------------------------------------------------

sub     get_position
        {
        my $self        = shift;
        my $parent      = $self->table;
        unless ($parent)
                {
                alert "Missing or wrong table attachment";
                return undef;
                }
        my $position = 0;
        my $elt = $self->previous($parent);
        while ($elt)
                {
                $position += ($elt->get_repeated() // 1);
                $elt = $elt->previous($parent);
                }
        return wantarray ? ($parent->get_name, $position) : $position;
        }

#-----------------------------------------------------------------------------

sub     clear
        {
        my $self        = shift;
        my %opt         = @_;
        my $rep = $self->get_repeated;
        my $style = $self->get_style;
        $self->del_attributes;
        $self->set_repeated($rep);
        $self->set_style($style);
        }

#=============================================================================
#       Table columns
#-----------------------------------------------------------------------------
package ODF::lpOD::Column;
use base 'ODF::lpOD::TableElement';
our $VERSION                    = '1.004';
use constant PACKAGE_DATE       => '2011-06-06T08:53:28';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     _create         { ODF::lpOD::Column->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller	= shift;
        my %opt = process_options
                (
                style   => undef,
                @_
                );

        my $col = ODF::lpOD::Element->create('table:table-column')
					or return undef;
        $col->set_attribute('style name', $opt{style})
                        if defined $opt{style};
        $col->set_default_cell_style($opt{cell_style})
                if defined $opt{cell_style};
        delete @opt{qw(style cell_style)};
        foreach my $a (keys %opt)
                {
                $col->set_attribute($a, $opt{$a});
                }
        return $col;
        }

#-----------------------------------------------------------------------------

sub     delete
        {
        my $self        = shift;
        my $parent =    $self->parent;
        if ($parent && $parent->isa('ODF::lpOD::ColumnGroup'))
                {
                return $parent->delete_column($self, @_);
                }
        else
                {
                return $self->SUPER::delete;
                }
        }

sub     clear
        {
        my $self        = shift;
        $_->clear for $self->get_cells;
        $self->SUPER::clear;
        }

#-----------------------------------------------------------------------------

sub     get_length
        {
        my $self	= shift;
        my $parent = $self->table;
        unless ($parent)
                {
                alert "No defined length for a non attached column";
                return undef;
                }
        return scalar $parent->get_height;
        }

sub     get_repeated
        {
        my $self        = shift;
        return $self->get_attribute('table:number-columns-repeated') // 1;
        }

sub     set_repeated
        {
        my $self        = shift;
        my $rep         = shift;
        $rep = undef unless $rep && $rep > 1;
        return $self->set_attribute('table:number-columns-repeated' => $rep);
        }

sub     next
        {
        my $self        = shift;
        my $context     = shift || $self->table;
        my $filter      = shift || qr'column';
        my $elt = $self->next_elt($context, $filter);
        while ($elt)
                {
                if      ($elt->isa('ODF::lpOD::Column'))
                        {
                        return $elt;
                        }
                elsif   ($elt->isa('ODF::lpOD::ColumnGroup'))
                        {
                        my $n = $elt->first_column;
                        return $n if $n;
                        }
                $elt = $elt->next_elt($context, $filter);
                }
        return undef;
        }

sub     previous
        {
        my $self        = shift;
        my $context     = shift || $self->table;
        my $filter      = shift || ODF::lpOD::Matrix->COLUMN_FILTER;
        my $elt = $self->prev_elt($context, $filter);
        while ($elt)
                {
                if      ($elt->isa('ODF::lpOD::Column'))
                        {
                        return $elt;
                        }
                elsif   ($elt->isa('ODF::lpOD::ColumnGroup'))
                        {
                        my $n = $elt->last_column();
                        return $n if $n;
                        }
                $elt = $elt->prev_elt($context, $filter);
                }
        return undef;
        }

sub     set_cell_style
        {
        my $self	= shift;
        my $style	= shift;
        $_->set_style($style) for $self->get_cells;
        }

#-----------------------------------------------------------------------------

sub     get_cell
        {
        my $self	= shift;
        my $table	= $self->table;
        unless ($table)
                {
                alert "Not in table"; return undef;
                }
        if ($self->get_repeated() > 1)
                {
                alert "Not supported in this mode"; return undef;
                }
        my $col_num = $self->get_position;
        my $row_num = alpha_to_num(shift) // 0;
        return $table->get_cell($row_num, $col_num);
        }

sub     get_cells
	{
        my $self	= shift;
        my $table	= $self->table;
        unless ($table)
                {
                alert "Not in table"; return undef;
                }
        if ($self->get_repeated() > 1)
                {
                alert "Not supported in this mode"; return undef;
                }
        my $arg         = shift;
        my ($start, $end);
        unless ($arg)
                {
                $start = 0; $end = $self->get_length() - 1;
                }
        else
                {
                ($start, $end) = translate_range($arg, shift);
                }
        $start //= 0; $end //= $self->get_length() - 1;
        my @cells = ();
        for (my $i = $start ; $i <= $end ; $i++)
                {
                my $c = $self->get_cell($i) or last;
                push @cells, $c;
                }
	return @cells;
	}

#=============================================================================
#       Table rows
#-----------------------------------------------------------------------------
package ODF::lpOD::Row;
use base 'ODF::lpOD::TableElement';
our $VERSION                    = '1.005';
use constant PACKAGE_DATE       => '2011-06-06T08:57:37';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     _create         { ODF::lpOD::Row->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller	= shift;
        my %opt = process_options
                (
                style   => undef,
                @_
                );

        my $row = ODF::lpOD::Element->create('table:table-row')
                        or return undef;
        $row->set_attribute('style name', $opt{style})
                        if defined $opt{style};
        $row->set_default_cell_style($opt{cell_style})
                if defined $opt{cell_style};
        delete @opt{qw(style cell_style)};

        foreach my $a (keys %opt)
                {
                $row->set_attribute($a, $opt{$a});
                }
        return $row;
        }

#-----------------------------------------------------------------------------

sub     clean
        {
        my $self        = shift;
        my $cell        = $self->last_child(ODF::lpOD::Matrix->CELL_FILTER)
                or return undef;
        $cell->set_repeated(undef);
        }

sub     all_cells
        {
        my $self	= shift;
        return $self->descendants(ODF::lpOD::Matrix->CELL_FILTER);
        }

sub     set_cell_style
        {
        my $self	= shift;
        my $style	= shift;
        $_->set_style($style) for $self->all_cells;
        }

sub     empty_cells
        {
        my $self        = shift;
        foreach my $cell ($self->all_cells)
                {
                $cell->set_value(undef);
                $cell->set_type(undef);
                $cell->set_text(undef);
                }
        }

#-----------------------------------------------------------------------------

sub     get_cell
        {
        my $self        = shift;
        my $position    = alpha_to_num(shift) || 0;
        my $width       = $self->get_width;
        if ($position < 0)
                {
                $position += $width;
                }
        if (($position >= $width) || ($position < 0))
                {
                alert "Cell position $position out of range";
                return undef;
                }
        my $cell = $self->first_child(ODF::lpOD::Matrix->CELL_FILTER)
                or return undef;

        my $p = $position;
        my $r = $cell->get_repeated;
        while ($p >= $r)
                {
                $p -= $r;
                $cell = $cell->next($self);
                $r = $cell->get_repeated;
                }
        if ($self->trw and $cell->repeat($r, $p))
                {
                $cell = $self->get_cell($position);
                }

        return $cell;
        }

sub     get_cells
        {
        my $self        = shift;
        my $arg         = shift;
        my ($start, $end);
        unless ($arg)
                {
                $start = 0; $end = $self->get_width() - 1;
                }
        else
                {
                ($start, $end) = translate_range($arg, shift);
                }
        $start //= 0; $end //= $self->get_width() - 1;
        my @list = ();
        if ($self->tro)
                {
                my $cell = $self->get_cell($start);
                my $n = $end - $start;
                        my $sp = $start - $cell->get_position;
                while ($n >= 0 && $cell)
                        {
                        my $r = $cell->get_repeated() - $sp;
                        while ($r > 0 && $n >= 0)
                                {
                                push @list, $cell;
                                $r--; $n--;
                                }
                        $cell = $cell->next
                                (
                                $self,
                                ODF::lpOD::Matrix->CELL_FILTER
                                );
                                $sp = 0;
                        }
                }
        else
                {
                for (my $i = $start ; $i <= $end ; $i++)
                        {
                        push @list, $self->get_cell($i);
                        }
                }

        return @list;
        }

sub     get_text
        {
        my $self        = shift;
        my %opt         = @_;
        return $self->ODF::lpOD::Element::get_text(%opt)
                        if is_true($opt{recursive});
        my $text;
        for ($self->get_cells)
                {
                my $t = $_->get_value;
                $text .= $t if defined $t;
                }
        return $text;
        }

sub     get_width
        {
        my $self        = shift;
        my $width       = 0;
        my $cell        = $self->first_child(ODF::lpOD::Matrix->CELL_FILTER);
        my $tbl		= $self->table;
        my $max_w       = $tbl ? $tbl->att('#lpod:w') : undef;
        while ($cell)
                {
                $width += $cell->get_repeated;
                $cell = $cell->next;
                }
        return (defined $max_w and $max_w < $width) ? $max_w : $width;
        }

sub     clear
        {
        my $self        = shift;
        my %opt         = @_;
        if (is_true($opt{compact}))
                {
                my $width = $self->get_width;
                $self->ODF::lpOD::Element::clear;
                my $cell = ODF::lpOD::Cell->create;
                $cell->set_repeated($width);
                $cell->paste_first_child($self);
                }
        else
                {
                $_->clear for $self->all_cells;
                }
        return $self->SUPER::clear;
        }

sub     add_cell
        {
        my $self        = shift;
        my %opt         =
                (
                number          => 1,
                @_
                );
        my $expand      = $opt{expand};
        my $empty       = $opt{empty};
        my $set_style   = exists $opt{style};
        my $style       = $opt{style};
        my $position    = undef;
        my $ref_elt     = $opt{before} // $opt{after};
        unless (defined $ref_elt)
                {
                $position = 'after';
                }
        else
                {
                if ($opt{before} && $opt{after})
                        {
                        alert "'before' and 'after' are mutually exclusive";
                        return FALSE;
                        }
                $position = defined $opt{before} ? 'before' : 'after';
                unless  (
                        $ref_elt->isa('ODF::lpOD::Cell')
                                &&
                        $ref_elt->parent() == $self
                        )
                        {
                        alert "Wrong $position reference";
                        return FALSE;
                        }
                }
        my $number = $opt{number};
        return undef unless $number && ($number > 0);
        delete @opt{qw(number before after expand empty style)};
        my $elt;
        unless ($ref_elt)
                {
                my $proto = $self->last_child(ODF::lpOD::Matrix->CELL_FILTER);
                $elt = $proto ?
                $proto->clone() : ODF::lpOD::Cell->create(%opt);
                }
        else
                {
                $elt = $ref_elt->clone;
                }
        if ($ref_elt)
                {
                $elt->paste($position, $ref_elt);
                }
        else
                {
                $elt->paste_last_child($self);
                }
        $elt->set_style($style) if $set_style;
        $elt->set_attributes
                (
                'number columns spanned'        => undef,
                'number rows spanned'           => undef
                );
        if (is_true($empty))
                {
                $elt->set_value(undef);
                $elt->set_type(undef);
                $elt->set_text(undef);
                }
        if ($number && $number > 1)
                {
                if (is_true($expand))
                        {
                        $elt->repeat($number);
                        }
                else
                        {
                        $elt->set_repeated($number);
                        }
                }
        return $elt;
        }

sub     get_repeated
        {
        my $self        = shift;
        return $self->get_attribute('table:number-rows-repeated') // 1;
        }

sub     set_repeated
        {
        my $self        = shift;
        my $rep         = shift;
        $rep = undef unless $rep && $rep > 1;
        return $self->set_attribute('table:number-rows-repeated' => $rep);
        }

sub     next
        {
        my $self        = shift;
        my $context     = shift || $self->table;
        my $filter      = shift || qr'row';
        my $elt = $self->next_elt($context, $filter);
        while ($elt)
                {
                if      ($elt->isa('ODF::lpOD::Row'))
                        {
                        return $elt;
                        }
                elsif   ($elt->isa('ODF::lpOD::RowGroup'))
                        {
                        my $n = $elt->first_row;
                        return $n if $n;
                        }
                $elt = $elt->next_elt($context, $filter);
                }
        }

sub     previous
        {
        my $self        = shift;
        my $context     = shift || $self->table;
        my $filter      = shift || ODF::lpOD::Matrix->ROW_FILTER;
        my $elt = $self->prev_elt($context, $filter);
        while ($elt)
                {
                if      ($elt->isa('ODF::lpOD::Row'))
                        {
                        if ($elt->parent->is('table:table-header-rows'))
                                {
                                return undef unless $self
                                        ->parent
                                        ->is('table:table-header-rows');
                                }
                        return $elt;
                        }
                elsif   ($elt->isa('ODF::lpOD::RowGroup'))
                        {
                        my $n = $elt->last_row();
                        return $n if $n;
                        }
                $elt = $elt->prev_elt($context, $filter);
                }
        return undef;
        }

#=============================================================================
#       Table cells
#-----------------------------------------------------------------------------
package ODF::lpOD::Cell;
use base ('ODF::lpOD::Field', 'ODF::lpOD::TableElement');
our $VERSION                    = '1.005';
use constant PACKAGE_DATE       => '2012-01-24T08:09:35';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

BEGIN	{
        *repeat         = *ODF::lpOD::TableElement::repeat;
        *get_parent_row = *row;
        }

#-----------------------------------------------------------------------------
our     %ATTRIBUTE;
#-----------------------------------------------------------------------------

sub     _create         { ODF::lpOD::Cell->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller	= shift;
                my $cell = ODF::lpOD::Field->create('table:table-cell', @_);
                return $cell ? bless($cell, __PACKAGE__) : undef;
        }

#-----------------------------------------------------------------------------

sub     row
        {
        my $self	= shift;
        return $self->parent('table:table-row');
        }

sub     column
        {
        my $self	= shift;
        my $t = $self->table;
        unless ($t)
                {
                alert "Not in table"; return undef;
                }
        my $pos = $self->get_position	or return undef;
        return $t->get_column($pos);
        }

#-----------------------------------------------------------------------------

sub     insert_element
        {
        my $context     = shift;
        my $e           = shift;
        my %opt		= @_;
        my $position	= lc $opt{position} || 'first_child';
        if (UNIVERSAL::isa($e, "ODF::lpOD::Frame"))
            {
            if (my $doc = $context->document)
                {
                if ($doc->get_type() eq 'spreadsheet')
                    {
                    $e->paste($position => $context);
                    }
                else
                    {
                    my $p = ODF::lpOD::Paragraph->create;
                    $p->paste($position => $context);
                    $e->paste_first_child($p);
                    }
                return $e;
                }
            }
        return $context->SUPER::insert_element($e, %opt);
        }

#-----------------------------------------------------------------------------

sub     get_repeated
        {
        my $self        = shift;
        return $self->get_attribute('table:number-columns-repeated') // 1;
        }

sub     set_repeated
        {
        my $self        = shift;
        my $rep         = shift;
        $rep = undef unless $rep && $rep > 1;
        return $self->set_attribute('table:number-columns-repeated' => $rep);
        }

sub     is_covered
        {
        my $self        = shift;
        my $tag         = $self->get_tag;
        return $tag =~ /covered/ ? TRUE : FALSE;
        }

sub     next
        {
        my $self        = shift;
        my $row = $self->row;
        unless ($row)
                {
                alert "Wrong context"; return FALSE;
                }
        return $self->next_elt($row, ODF::lpOD::Matrix->CELL_FILTER);
        }

sub     previous
        {
        my $self        = shift;
        my $row = $self->row;
        unless ($row)
                {
                alert "Wrong context"; return FALSE;
                }
        return $self->prev_elt($row, ODF::lpOD::Matrix->CELL_FILTER);
        }

sub     get_position
        {
        my $self        = shift;
        my $row = $self->row;
        unless ($row)
                {
                alert "Missing or wrong attachment";
                return FALSE;
                }
        my $position = 0;
        my $elt = $self->previous;
        while ($elt)
                {
                $position += $elt->get_repeated // 1;
                $elt = $elt->previous;
                }
        if (wantarray)
                {
                return  (
                        $row->get_position(),
                        $position
                        );
                }
        return $position;
        }

#-----------------------------------------------------------------------------

sub     set_text
        {
        my $self        = shift;
        my $text        = shift;
        my %opt         =
                (
                style           => undef,
                @_
                );
        $self->cut_children(qr'^text|^table');
        return undef unless defined $text;
        $self->append_element
                (
                ODF::lpOD::Paragraph->create
                        (text => $text, style => $opt{style})
                );
        }

sub     set_value
        {
        my $self	= shift;
        return $self->get_type() ne 'string' ?
                $self->SUPER::set_value(@_) : $self->set_text(@_);
        }

sub     get_text
        {
        my $self        = shift;
        return $self->ODF::lpOD::TextElement::get_text(@_);
        }

sub     get_content
        {
        my $self        = shift;
        return $self->get_children_elements;
        }

sub     set_content
        {
        my $self        = shift;
        $self->set_text;
        foreach my $elt (@_)
                {
                if (ref $elt && $elt->isa('ODF::lpOD::Element'))
                        {
                        $self->append_element($elt);
                        }
                }
        }

sub     remove_span
        {
        my $self        = shift;
        my $hspan = $self->get_attribute('number columns spanned') || 1;
        my $vspan = $self->get_attribute('number rows spanned') || 1;
        $self->del_attribute('number columns spanned');
        $self->del_attribute('number rows spanned');
        my $row = $self->parent(ODF::lpOD::Matrix->ROW_FILTER);
        my $table = $self->parent(ODF::lpOD::Matrix->TABLE_FILTER);
        my $vpos = $row->get_position;
        my $hpos = $self->get_position;
        my $vend = $vpos + $vspan - 1;
        my $hend = $hpos + $hspan - 1;
        ROW: for (my $i = $vpos ; $i <= $vend ; $i++)
                {
                my $cr = $table->get_row($i) or last ROW;
                CELL: for (my $j = $hpos ; $j <= $hend ; $j++)
                        {
                        my $covered = $cr->get_cell($j) or last CELL;
                        next CELL if $covered == $self;
                        $covered->set_tag('table:table-cell');
                        $covered->set_atts($self->atts);
                        }
                }
        return ($hspan, $vspan);
        }

sub     set_span
        {
        my $self        = shift;
        if ($self->is_covered)
                {
                alert "Span expansion is not allowed for covered cells";
                return FALSE;
                }
        my %opt         = @_;
        my $hspan = $opt{columns}       // 1;
        my $vspan = $opt{rows}          // 1;
        my $old_hspan = $self->get_attribute('number columns spanned') || 1;
        my $old_vspan = $self->get_attribute('number rows spanned') || 1;
        unless  (($hspan > 1) || ($vspan > 1))
                {
                return $self->remove_span;
                }
        unless  (($hspan != $old_hspan) || ($vspan != $old_vspan))
                {
                return ($old_vspan, $old_hspan);
                }
        $self->remove_span;
        $hspan	= $old_hspan unless $hspan;
        $vspan	= $old_vspan unless $vspan;
        my $row = $self->parent(ODF::lpOD::Matrix->ROW_FILTER);
        my $table = $self->parent(ODF::lpOD::Matrix->TABLE_FILTER);
        my $vpos = $row->get_position;
        my $hpos = $self->get_position;
        my $vend = $vpos + $vspan - 1;
        my $hend = $hpos + $hspan - 1;
        $self->set_attribute('number columns spanned', $hspan);
        $self->set_attribute('number rows spanned', $vspan);
        ROW: for (my $i = $vpos ; $i <= $vend ; $i++)
                {
                my $cr = $table->get_row($i) or last ROW;
                CELL: for (my $j = $hpos ; $j <= $hend ; $j++)
                        {
                        my $covered = $cr->get_cell($j) or last CELL;
                        next CELL if $covered == $self;
                        $_->move(last_child => $self)
                                for $covered->get_content;
                        $covered->remove_span;
                        $covered->set_tag('table:covered-table-cell');
                        }
                }
        return ($hspan, $vspan);
        }

sub     get_span
        {
        my $self        = shift;
        return  (
                $self->get_attribute('number rows spanned') // 1,
                $self->get_attribute('number columns spanned') // 1
                );
        }

sub     clear
        {
        my $self        = shift;
        $self->remove_span      if $self->table;
        my $rep = $self->get_repeated;
        my $style = $self->get_style;
        $self->del_attributes;
        $self->set_repeated($rep);
        $self->set_style($style);
        $self->set_text;
        }

#=============================================================================
#       Named ranges
#-----------------------------------------------------------------------------
package ODF::lpOD::NamedRange;
use base 'ODF::lpOD::Element';
our $VERSION                    = '1.001';
use constant PACKAGE_DATE       => '2012-03-29T08:06:56';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
        my $nr = ODF::lpOD::Element->create('table:named-range');
        $nr->set_attribute('name' => shift);
        $nr->set_properties(@_);
        return $nr;
        }

#-----------------------------------------------------------------------------

sub     set_name
        {
        my $self        = shift;
        my $name        = shift         or return undef;
        my $old = $self->get_attribute('name');
        my $doc = $self->document;
        if ($doc and ($name ne $old) and $doc->get_named_range($name))
                {
                alert "Named range $name already exists";
                return undef;
                }
        return $self->set_attribute('name' => $name);
        }

sub     get_properties
        {
        my $self        = shift;
        my (%p, $t, $b, $s, $e);
        my $range = $self->get_attribute('table:cell-range-address');
        my $base = $self->get_attribute('table:base-cell-address');
        for ($range, $base)
                {
                if ($_) { $_ =~ s/\$//g; $_ =~ s/://g; }
                }
        ($p{table}, $b) = split(/\./, $base)            if $base;
        ($t, $p{start}, $p{end}) = split(/\./, $range)  if $range;
        $p{table} ||= $t;
        $p{range} = $p{start} . ':' . $p{end}
                if defined $p{start} and defined $p{end};
        $p{usage} = $self->get_attribute('range usable as') || 'none';
        return wantarray ? %p : {%p};
        }

sub     set_properties
        {
        my $self        = shift;
        my $att         = shift         or return undef;
        my %att = ref $att ? %{$att} : ($att, @_);
        my $t = ref $att{table} ? $att{table}->get_name : $att{table};
        my %old = $self->get_properties;
        $att{$_} //= $old{$_} for keys %old;
        if ($att{range})
                {
                ($att{start}, $att{end}) = split(/:/, $att{range});
                delete $att{range};
                }

        $att{'base cell address'}       ||=
                        $t . '.' . $att{start};
        $att{'cell range address'}      ||=
                        $t . '.' . $att{start} . ':.' . $att{end};
        $att{'range usable as'}         ||=
                        ($att{usage} // 'none');
        delete @att{qw(table start end usage)};

        $self->set_attributes(%att);
        }

sub     _get_range_access
        {
        my $self        = shift;
        my $doc = $self->document;
        unless ($doc)
                {
                alert "Not in document"; return undef;
                }
        my $context = $doc->get_body('spreadsheet');
        my $p = $self->get_properties;
        my $t = $context->get_table($p->{table});
        unless ($t)
                {
                alert "Unknown table"; return FALSE;
                }
        return ($t, $p->{range});
        }

sub     get_cells
        {
        my $self        = shift;
        my ($t, $range) = $self->_get_range_access;
        return $t ? $t->get_cells($range, @_) : undef;
        }

sub     get_cell_values
        {
        my $self        = shift;
        my $type        = shift;
        my ($t, $range) = $self->_get_range_access;
        return $t ? $t->get_cell_values($type, $range) : undef;
        }

#=============================================================================
1;
