#
# Copyright (C) 1997 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: Ascii.pm,v 1.3 1997/10/25 21:47:32 ken Exp $
#

package Quilt::Writer::Ascii;
@Quilt::Writer::Ascii::ISA = qw{Quilt::Context};

use strict;
use vars qw{$entity_maps};

use Text::EntityMap;
use Quilt::Context;

my $entity_maps = undef;

sub new {
    my ($type, %init) = @_;

    if (!defined $init{file_handle}) {
	if (!defined %FileHandle::) {
	    require FileHandle;
	    import FileHandle;
	}

	# default to stdout
	$init{file_handle} = FileHandle->new ('>-');
    }

    # XXX this probably shouldn't be here
    # note the conversion of `sdata_dirs' list to an anonymous array to
    # make a single argument
    if (!defined $entity_maps) {
	$entity_maps = load_char_maps ('.2ab', [ Text::EntityMap::sdata_dirs() ]);
    }

    my ($self) = {
	current => [{}],
	file_handle => $init{file_handle},
	entity_map => $entity_maps,
    };

    bless ($self, $type);

    $self->push ({
	inline => 0,
	line_width => 72,
    });

    return ($self);
}

# XXX move me or get rid of me
# `load_char_maps' takes a `EntityMap' format suffix and loads all of
# the character entity replacement sets for that suffix into a
# EntityMapGroup.  `load_char_maps' searches every directory in
# `@{$path}'.

sub load_char_maps {
    my ($format, $paths) = @_;

    my (@char_maps) = ();
    my ($path, $file_name, $char_map);

    foreach $path (@{$paths}) {
	if (-d $path) {
	    opendir (SDATADIR, $path)
		or die "load_char_map: opening directory \`$path' for reading: $!\n";
	    foreach $file_name (readdir (SDATADIR)) {
		next if ($file_name !~ /$format$/);
		eval {$char_map = Text::EntityMap->load ("$path/$file_name")}
  		    or die "load_char_map: loading \`$path/$file_name'\n$@\n";
		push (@char_maps, $char_map);
	    }
	    closedir (SDATADIR);
	}
    }

    warn "load_char_maps: no entity maps found\n"
	if ($#char_maps == -1);

    return (Text::EntityMap->group (@char_maps));
}

sub push_display {
    my ($self, $obj) = @_;

    $self->collect_data;
    my ($key);
    foreach $key (qw{start_indent end_indent}) {
	# this object may not have an indent
	my $value;
	eval { $value = $obj->$key() };
	last if !defined $value;
	if (defined ($value)) {
	    if ($value =~ /^[+-]/) {
		$obj->$key (eval "\$self->\$key() $value");
	    } else {
		$obj->$key ($value);
	    }
	}
    }
    $self->SUPER::push ($obj);
    $self->push_break (new Quilt::Flow::DisplaySpace (space => $self->space_before));
}

sub pop_display {
    my ($self) = @_;

    $self->collect_data;
    $self->push_break (new Quilt::Flow::DisplaySpace (space => $self->space_after));
    $self->SUPER::pop;
}

sub push_inline {
    my ($self, $obj) = @_;

    $self->collect_break;
    $self->SUPER::push ($obj);
}

sub pop_inline {
    my ($self) = @_;

    $self->collect_break;
    $self->SUPER::pop;
}

sub push_break {
    my ($self, $obj) = @_;

    $self->collect_data;
    my $space = $obj->space;
    if (!defined $space) {
	$obj->space (0);
	$space = 0;
    }
    my $priority = $obj->priority;
    if (!defined $priority) {
	$obj->priority (0);
	$priority = 0;
    }
    # XXX doesn't fully implement DSSSL display space semantics (12.5.4.1)
    if (!defined $self->{break}) {
	$self->{break} = $space;
	$self->{break_priority} = $priority;
    } else {
	if ($priority > $self->{break_priority}) {
	    $self->{break_priority} = $priority;
	    $self->{break} = $space;
	} elsif	($priority == $self->{break_priority}
		 && $space > $self->{break}) {
	    $self->{break} = $space;
	}
    }
}

sub collect_break {
    my $self = shift;

    if (defined $self->{break}) {
	if (ref ($self->{file_handle})) {
	    $self->{file_handle}->print ("\n" x $self->{break});
	} else {
	    $self->{file_handle} .= "\n" x $self->{break};
	}
	undef $self->{break};
    }
}

sub push_data {
    my ($self, $data) = @_;

    $self->collect_break;
    push (@{$self->{data}}, $data);
}

# XXX `mark' hack, I believe the way this is intended to be handled in
# DSSSL is to use side-by-side display objects.
sub push_mark {
    my ($self, $mark) = @_;

    $self->{mark} .= $mark;
}

sub collect_data {
    my ($self) = @_;

    if (defined $self->{data}) {
	my ($str);
	$str = join ("", @{$self->{data}});
	if ($self->lines eq "asis") {
	    my ($indent) = " " x $self->start_indent;
	    $str =~ s/^/$indent/mg;
	} else {
	    $str = $self->fmt ($str,
			       $self->start_indent,
			       $self->end_indent,
			       $self->line_width,
			       $self->quadding);
	}
	if (defined $self->{mark}) {
	    my ($mark_length) = length ($self->{mark});
	    substr ($str, $self->start_indent - $mark_length, $mark_length) = $self->{mark};
	    undef $self->{mark};
	}
	$str .= "\n"
	    if (substr ($str, -1) ne "\n");
	if (ref ($self->{file_handle})) {
	    $self->{file_handle}->print ($str);
	} else {
	    $self->{file_handle} .= $str;
	}
	undef $self->{data};
    }
}

#
# fmt re-fills paragraphs (like fmt(1)) in `ascii' output
#

sub _fmt {
    my ($str, $indent, $line_width, $justify) = @_;

    if ($justify eq 'center') {
	$indent += ($line_width - length ($str)) / 2;
    }
    return (" " x $indent . $str . "\n");
}

sub fmt {
    my ($self, $str, $indent, $rindent, $line_width, $justify) = @_;

    $str =~ s/[\s\n\r]+/ /gs;	# strip multiple spaces/newlines
    $str =~ s/^\s//;		# remove leading space
    $str =~ s/\s$//;		# remove trailing space
    $line_width = $line_width - $indent - $rindent;
    $str =~ s/(.{1,$line_width})(\s|$)/&_fmt($1, $indent, $line_width, $justify)/ge;

    return ($str);
}

sub format_table {
    my $self = shift; my $table = shift; my $builder = shift;

    $self->collect_break;

    my ($part, $row, $entry);
    my (@avg_length, @min_width, @col_width);
    my ($ii, $jj);

    my ($num_parts) = $table->num_parts;
    my ($num_table_rows) = $table->num_rows;
    my ($num_columns) = $table->num_columns;
    for ($ii = 0; $ii < $num_columns; $ii ++) {
	$avg_length[$ii] = 0;
	$min_width[$ii] = 0;
    }

    #
    # Calculate column widths
    #  1) find minimum word widths for each column (max of any one
    #     word within a column)
    #  2) find average character-length of each column (avg of all
    #     entries in the column)
    #  3) set column width to max of proportion of average column
    #     length and  minimum width (from 1)
    #     a) if proportion is less than minimum, set to minimum and
    #        subtract difference from available space for other columns
    #
    foreach $part (@{$table->parts}) {
	foreach $row (@{$part->rows}) {
	    my ($col_num) = 0;
	    foreach $entry (@{$row->entries}) {
		my ($word);
		my ($test_data) = $entry->as_string($self);

		$entry->{'length'} = length ($test_data);
		$avg_length[$col_num] += $entry->{'length'};
		foreach $word (split (/[\s\n]/s, $test_data)) {
		    if (length ($word) > $min_width[$col_num]) {
			$min_width[$col_num] = length ($word);
		    }
		}
		$col_num ++;
	    }
	}
    }

    # make `avg_length' earn it's name :-)
    my ($total_avg_length) = 0;
    for ($jj = 0; $jj < $num_columns; $jj ++) {
	$total_avg_length += ($avg_length[$jj]
			      = ($avg_length[$jj] / $num_table_rows));
    }

    # set `$col_width' to the proportion of the `avg_length' to
    # `total_avg_length', or `$min_width' if that's greater.
    # If `$min_width' _is_ greater, remove that much space from the
    # other columns ($less_space)
    die "$::prog: assert: \$total_avg_length is 0, no table data"
	if ($total_avg_length == 0);
    my ($less_space) = 0;
    # `3' is our inter-column gap
    my ($line_width) = $self->line_width - $num_columns * 3;
    for ($jj = 0; $jj < $num_columns; $jj ++) {
	$col_width[$jj] = int ($line_width * ($avg_length[$jj]/$total_avg_length) + 0.5);
	if ($col_width[$jj] < $min_width[$jj]) {
	    $less_space += $min_width[$jj] - $col_width[$jj];
	    $col_width[$jj] = $min_width[$jj];
	}
    }

    # now that we now how much space is really available, reproportion
    # the space among the wider columns.  If we run into another min
    # greater than column width, then warn
    my ($already_warned) = 0;
    $line_width -= $less_space;
    for ($jj = 0; $jj < $num_columns; $jj ++) {
	if ($col_width[$jj] != $min_width[$jj]) {
	    $col_width[$jj] = int ($line_width * ($avg_length[$jj]/$total_avg_length) + 0.5);
	    if ($col_width[$jj] < $min_width[$jj]) {
		$line_width -= $min_width[$jj] - $col_width[$jj];
		$col_width[$jj] = $min_width[$jj];
		if (!$already_warned) {
		    $already_warned = 1;
		    warn "table too wide\n";
		}
	    }
	}
    }

    #
    # format every entry of every row of every part
    #

    # our context is pretty bare, `center' is default for ``head'' part
    $self->push (new Quilt::Flow ('space_before' => 1,
				  'space_after' => 1,
				  'start_indent' => 0,
				  'end_indent' => 0,
				  'first_line_start_indent' => 0,
				  'line_width' => 0,
				  'quadding' => 'center',
				  'lines' => 'wrap'));
    my ($data) = "";
    my $single_row_sep = row_sep (\@col_width, $table->frame, "-") . "\n";
    my $double_row_sep = row_sep (\@col_width, $table->frame, "=") . "\n";
    if ($num_parts == 1 || $table->frame !~ /none/i) {
	# only a ``body'' part or framing all, put divider above and set start justify
	$data .= $single_row_sep;
	# `start' is default for other parts
	$self->quadding ('start');
    }
    my $part_num = 1;
    foreach $part (@{$table->parts}) {
	my (@rows);
	foreach $row (@{$part->rows}) {
	    my (@entries);
	    my ($col_num) = 0;
	    my ($ascii);
	    foreach $entry (@{$row->entries}) {
		$self->line_width ($col_width[$col_num]);
		# XXX this could be designed better
		push (@{$self->{'file_handles'}}, $self->{'file_handle'});
		$self->{'file_handle'} = '';
		$entry->iter->children_accept ($builder, $self);
		$self->collect_data;
		# remove leading and trailing blank lines
		$self->{'file_handle'} =~ s/^[\s\n]*\n//s;
		$self->{'file_handle'} =~ s/[\s\n]*$/\n/s; # leave one newline
		push (@entries, $self->{'file_handle'});
		$self->{'file_handle'} = pop (@{$self->{'file_handles'}});
		$col_num ++;
	    }

	    push (@rows, merge_entries (\@col_width, $table->frame, @entries));
	}
	
	if ($table->frame =~ /none/i) {
	    $data .= join ("\n", @rows);
	    $data .= $single_row_sep;
	} else {
	    $data .= join ($single_row_sep, @rows);
	    if ($part_num == $num_parts) {
		$data .= $single_row_sep;
	    } else {
		$data .= $double_row_sep;
	    }
	}
	# `start' is default for other parts
	$self->quadding ('start');

	$part_num ++;
    }
    $self->pop;

    return $data;
}

sub row_sep {
    my ($col_widths, $frame, $csep) = @_;

    my @entries;
    my $ii;
    for ($ii = 0; $ii <= $#$col_widths; $ii ++) {
	push (@entries, $csep x $col_widths->[$ii]);
    }
    my $pre = ($frame =~ /none/i) ? "" : "+$csep";
    my $post = ($frame =~ /none/i) ? "" : "$csep+";
    my $sep = ($frame =~ /none/i) ? "   " : "$csep+$csep";
    return ($pre . join ($sep, @entries) . $post);
}

sub merge_entries {
    my ($col_widths, $frame, @entries) = @_;
    my (@splits, $ii);
    my ($data) = "";

    for ($ii = 0; $ii <= $#{$col_widths}; $ii ++) {
	my (@line_splits) = split (/\n/, $entries[$ii]);
	$splits[$ii] = \@line_splits;
    }

    my ($done) = 0;
    while (!$done) {
	my (@line);
	$done = 1;
	for ($ii = 0; $ii <= $#{$col_widths}; $ii ++) {
	    my ($col_width) = $col_widths->[$ii];
	    if ($frame =~ /none/i && $ii == $#{$col_widths}) {
		# Leave off extra space at end of line
		$col_width = length ($splits[$ii]->[0]);
	    }
	    if ($#{$splits[$ii]} > -1) {
		push (@line, sprintf ("%-${col_width}.${col_width}s",
				      shift (@{$splits[$ii]})));
	    } else {
		push (@line, " " x $col_width);
	    }
	    ($#{$splits[$ii]} != -1) && ($done = 0);
	}
	my $pre = ($frame =~ /none/i) ? "" : "| ";
	my $post = ($frame =~ /none/i) ? "" : " |";
	my $sep = ($frame =~ /none/i) ? "   " : " | ";
	$data .= $pre . join ($sep, @line) . "$post\n";
    }

    return $data;
}

sub space_before  {
    my $self = shift;
    @_ ? $self->{'current'}[-1]{'space_before'} = shift
	: return $self->{'current'}[-1]{'space_before'};
}
sub space_after  {
    my $self = shift;
    @_ ? $self->{'current'}[-1]{'space_after'} = shift
	: return $self->{'current'}[-1]{'space_after'};
}
sub first_line_start_indent  {
    my $self = shift;
    @_ ? $self->{'current'}[-1]{'first_line_start_indent'} = shift
	: return $self->{'current'}[-1]{'first_line_start_indent'};
}
sub start_indent  {
    my $self = shift;
    @_ ? $self->{'current'}[-1]{'start_indent'} = shift
	: return $self->{'current'}[-1]{'start_indent'};
}
sub end_indent  {
    my $self = shift;
    @_ ? $self->{'current'}[-1]{'end_indent'} = shift
	: return $self->{'current'}[-1]{'end_indent'};
}
sub line_width  {
    my $self = shift;
    @_ ? $self->{'current'}[-1]{'line_width'} = shift
	: return $self->{'current'}[-1]{'line_width'};
}
sub lines  {
    my $self = shift;
    @_ ? $self->{'current'}[-1]{'lines'} = shift
	: return $self->{'current'}[-1]{'lines'};
}
sub quadding  {
    my $self = shift;
    @_ ? $self->{'current'}[-1]{'quadding'} = shift
	: return $self->{'current'}[-1]{'quadding'};
}
sub inline  {
    my $self = shift;
    @_ ? $self->{'current'}[-1]{'inline'} = shift
	: return $self->{'current'}[-1]{'inline'};
}

1;
