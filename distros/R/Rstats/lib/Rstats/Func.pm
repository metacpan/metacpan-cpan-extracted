package Rstats::Func;

use strict;
use warnings;

require Rstats;

use Carp 'croak';
use Rstats::Func;
use Rstats::Util;
use Text::UnicodeTable::Simple;

use List::Util ();
use POSIX ();
use Math::Round ();
use Encode ();

sub factor {
  my $r = shift;
  
  my ($x1, $x_levels, $x_labels, $x_exclude, $x_ordered)
    = args_array($r, [qw/x levels labels exclude ordered/], @_);

  # default - x
  $x1 = Rstats::Func::as_character($r, $x1) unless Rstats::Func::is_character($r, $x1);
  
  # default - levels
  unless (defined $x_levels) {
    $x_levels = Rstats::Func::sort($r, unique($r, $x1), {'na.last' => Rstats::Func::TRUE($r)});
  }
  
  # default - exclude
  $x_exclude = NA($r) unless defined $x_exclude;
  
  # fix levels
  if (defined $x_exclude->value && Rstats::Func::length($r, $x_exclude)->value) {
    my $new_a_levels_values = [];
    for my $x_levels_value (@{$x_levels->values}) {
      my $match;
      for my $x_exclude_value (@{$x_exclude->values}) {
        if (defined $x_levels_value
          && defined $x_exclude_value
          && $x_levels_value eq $x_exclude_value)
        {
          $match = 1;
          last;
        }
      }
      push @$new_a_levels_values, $x_levels_value unless $match;
    }
    $x_levels = Rstats::Func::c_($r, @$new_a_levels_values);
  }
  
  # default - labels
  unless (defined $x_labels) {
    $x_labels = $x_levels;
  }
  
  # default - ordered
  $x_ordered = Rstats::Func::is_ordered($r, $x1) unless defined $x_ordered;
  
  my $x1_values = $x1->values;
  
  my $labels_length = Rstats::Func::length($r, $x_labels)->value;
  my $levels_length = Rstats::Func::length($r, $x_levels)->value;
  if ($labels_length == 1 && Rstats::Func::get_length($r, $x1) != 1) {
    my $value = $x_labels->value;
    $x_labels = paste($r, $value, C_($r, "1:$levels_length"), {sep => ""});
  }
  elsif ($labels_length != $levels_length) {
    Carp::croak("Error in factor 'labels'; length $labels_length should be 1 or $levels_length");
  }
  
  # Levels hash
  my $levels;
  my $x_levels_values = $x_levels->values;
  for (my $i = 1; $i <= $levels_length; $i++) {
    my $x_levels_value = $x_levels_values->[$i - 1];
    $levels->{$x_levels_value} = $i;
  }
  
  my $f1_values = [];
  for my $x1_value (@$x1_values) {
    if (!defined $x1_value) {
      push @$f1_values, undef;
    }
    else {
      my $f1_value = exists $levels->{$x1_value}
        ? $levels->{$x1_value}
        : undef;
      push @$f1_values, $f1_value;
    }
  }
  
  my $f1 = Rstats::Func::c_integer($r, @$f1_values);
  if ($x_ordered) {
    $f1->{class} = Rstats::Func::c_character($r, 'factor', 'ordered');
  }
  else {
    $f1->{class} = Rstats::Func::c_character($r, 'factor');
  }
  $f1->{levels} = Rstats::Func::as_vector($r, $x_labels);
  
  $f1->{type} = 'integer';
  $f1->{object_type} = 'array';
  
  return $f1;
}

sub ordered {
  my $r = shift;
  
  my $opt = ref $_[-1] eq 'HASH' ? pop : {};
  $opt->{ordered} = Rstats::Func::TRUE($r);
  
  factor($r, @_, $opt);
}

sub list {
  my $r = shift;
  
  my @elements = @_;
  
  @elements = map { !Rstats::Func::is_list($r, $_) ? Rstats::Func::to_object($r, $_) : $_ } @elements;
  
  my $list = Rstats::Func::new_list($r);
  $list->list(\@elements);
  $list->r($r);
  
  return $list;
}

sub data_frame {
  my $r = shift;
  
  my @data = @_;
  
  return cbind($r, @data) if ref $data[0] && Rstats::Func::is_data_frame($r, $data[0]);
  
  my $elements = [];
  
  # name count
  my $name_count = {};
  
  # count
  my $counts = [];
  my $column_names = [];
  my $row_names = [];
  my $row_count = 1;
  while (my ($name, $v) = splice(@data, 0, 2)) {
    if (Rstats::Func::is_character($r, $v) && !grep {$_ eq 'AsIs'} @{$v->class->values}) {
      $v = Rstats::Func::as_factor($r, $v);
    }

    my $dim_values = Rstats::Func::dim($r, $v)->values;
    if (@$dim_values > 1) {
      my $count = $dim_values->[0];
      my $dim_product = 1;
      $dim_product *= $dim_values->[$_] for (1 .. @$dim_values - 1);
      
      for my $num (1 .. $dim_product) {
        push @$counts, $count;
        my $fix_name;
        if (my $count = $name_count->{$name}) {
          $fix_name = "$name.$count";
        }
        else {
          $fix_name = $name;
        }
        push @$column_names, $fix_name;
        push @$elements, splice(@{$v->values}, 0, $count);
      }
    }
    else {
      my $count = Rstats::Func::get_length($r, $v);
      push @$counts, $count;
      my $fix_name;
      if (my $count = $name_count->{$name}) {
        $fix_name = "$name.$count";
      }
      else {
        $fix_name = $name;
      }
      push @$column_names, $fix_name;
      push @$elements, $v;
    }
    push @$row_names, "$row_count";
    $row_count++;
    $name_count->{$name}++;
  }
  
  # Max count
  my $max_count = List::Util::max @$counts;
  
  # Check multiple number
  for my $count (@$counts) {
    if ($max_count % $count != 0) {
      Carp::croak "Error in data.frame: arguments imply differing number of rows: @$counts";
    }
  }
  
  # Fill vector
  for (my $i = 0; $i < @$counts; $i++) {
    my $count = $counts->[$i];
    
    my $repeat = $max_count / $count;
    if ($repeat > 1) {
      my $repeat_elements = [];
      push @$repeat_elements, $elements->[$i] for (1 .. $repeat);
      $elements->[$i] = Rstats::Func::c_($r, @$repeat_elements);
    }
  }
  
  # Create data frame
  my $data_frame = Rstats::Func::new_data_frame($r);
  $data_frame->{row_length} = $max_count;
  $data_frame->list($elements);
  Rstats::Func::dimnames(
    $r,
    $data_frame,
    Rstats::Func::list(
      $r,
      Rstats::Func::c_($r, @$row_names),
      Rstats::Func::c_($r, @$column_names)
    )
  );
  $data_frame->r($r);
  
  return $data_frame;
}

sub matrix {
  my $r = shift;
  
  
  my ($x1, $x_nrow, $x_ncol, $x_byrow, $x_dirnames)
    = Rstats::Func::args_array($r, ['x1', 'nrow', 'ncol', 'byrow', 'dirnames'], @_);

  Carp::croak "matrix method need data as frist argument"
    unless defined $x1;
  
  # Row count
  my $nrow;
  $nrow = $x_nrow->value if defined $x_nrow;
  
  # Column count
  my $ncol;
  $ncol = $x_ncol->value if defined $x_ncol;
  
  # By row
  my $byrow;
  $byrow = $x_byrow->value if defined $x_byrow;
  
  my $x1_values = $x1->values;
  my $x1_length = Rstats::Func::get_length($r, $x1);
  if (!defined $nrow && !defined $ncol) {
    $nrow = $x1_length;
    $ncol = 1;
  }
  elsif (!defined $nrow) {
    $nrow = int($x1_length / $ncol);
    $nrow ||= 1;
  }
  elsif (!defined $ncol) {
    $ncol = int($x1_length / $nrow);
    $ncol ||= 1;
  }
  my $length = $nrow * $ncol;
  
  my $dim = [$nrow, $ncol];
  my $matrix;
  my $x_matrix;

  if (Rstats::Func::get_type($r, $x1) eq "character") {
    $x_matrix = c_character($r, $x1_values);
  }
  elsif (Rstats::Func::get_type($r, $x1)  eq "complex") {
    $x_matrix = c_complex($r, $x1_values);
  }
  elsif (Rstats::Func::get_type($r, $x1)  eq "double") {
    $x_matrix = c_double($r, $x1_values);
  }
  elsif (Rstats::Func::get_type($r, $x1)  eq "integer") {
    $x_matrix = c_integer($r, $x1_values);
  }
  elsif (Rstats::Func::get_type($r, $x1)  eq "logical") {
    $x_matrix = c_logical($r, $x1_values);
  }
  else {
    croak("Invalid type " . Rstats::Func::get_type($r, $x1) . " is passed");
  }
  
  if ($byrow) {
    $matrix = Rstats::Func::array(
      $r,
      $x_matrix,
      Rstats::Func::c_($r, $dim->[1], $dim->[0]),
    );
    
    $matrix = Rstats::Func::t($r, $matrix);
  }
  else {
    $matrix = Rstats::Func::array($r, $x_matrix, Rstats::Func::c_($r, @$dim));
  }
  
  return $matrix;
}




sub dimnames {
  my $r = shift;
  
  my $x1 = shift;
  
  if (@_) {
    my $dimnames_list = shift;
    if ($dimnames_list->{object_type} eq 'list') {
      my $length = Rstats::Func::get_length($r, $dimnames_list);
      my $dimnames = [];
      for (my $i = 0; $i < $length; $i++) {
        my $x_dimname = $dimnames_list->getin($i + 1);
        if (is_character($r, $x_dimname)) {
          my $dimname = Rstats::Func::as_vector($r, $x_dimname);
          push @$dimnames, $dimname;
        }
        else {
          croak "dimnames must be character list";
        }
      }
      $x1->{dimnames} = $dimnames;
      
      if (Rstats::Func::is_data_frame($r, $x1)) {
        $x1->{names} = Rstats::Func::as_vector($r, $x1->{dimnames}[1]);
      }
    }
    else {
      croak "dimnames must be list";
    }
  }
  else {
    if (exists $x1->{dimnames}) {
      my $x_dimnames = Rstats::Func::list($r);
      $x_dimnames->list($x1->{dimnames});
    }
    else {
      return Rstats::Func::NULL($r);
    }
  }
}

sub rownames {
  my $r = shift;
  
  my $x1 = shift;
  
  if (@_) {
    my $x_rownames = Rstats::Func::to_object($r, shift);
    
    unless (exists $x1->{dimnames}) {
      $x1->{dimnames} = [];
    }
    
    $x1->{dimnames}[0] = Rstats::Func::as_vector($r, $x_rownames);
  }
  else {
    my $x_rownames = Rstats::Func::NULL($r);
    if (defined $x1->{dimnames}[0]) {
      $x_rownames = Rstats::Func::as_vector($r, $x1->{dimnames}[0]);
    }
    return $x_rownames;
  }
}


sub colnames {
  my $r = shift;
  
  my $x1 = shift;
  
  if (@_) {
    my $x_colnames = Rstats::Func::to_object($r, shift);
    
    unless (exists $x1->{dimnames}) {
      $x1->{dimnames} = [];
    }
    
    $x1->{dimnames}[1] = Rstats::Func::as_vector($r, $x_colnames);
  }
  else {
    my $x_colnames = Rstats::Func::NULL($r);
    if (defined $x1->{dimnames}[1]) {
      $x_colnames = Rstats::Func::as_vector($r, $x1->{dimnames}[1]);
    }
    return $x_colnames;
  }
}

sub labels {
  my $r = shift;
  return $r->as->character(@_);
}

sub as_list {
  my $r = shift;
  
  my $x1 = shift;
  
  if (exists $x1->{list}) {
    return $x1;
  }
  else {
    my $list = Rstats::Func::new_list($r);;
    my $x2 = Rstats::Func::as_vector($r, $x1);
    $list->list([$x2]);
    
    return $list;
  }
}

sub as_factor {
  my $r = shift;
  
  my $x1 = shift;
  
  if (Rstats::Func::is_factor($r, $x1)) {
    return $x1;
  }
  else {
    my $a = is_character($r, $x1) ? $x1 :  Rstats::Func::as_character($r, $x1);
    my $f = Rstats::Func::factor($r, $a);
    
    return $f;
  }
}

sub as_matrix {
  my $r = shift;
  
  my $x1 = shift;
  
  my $x1_dim_elements = $x1->dim_as_array->values;
  my $x1_dim_count = @$x1_dim_elements;
  my $x2_dim_elements = [];
  my $row;
  my $col;
  if ($x1_dim_count == 2) {
    $row = $x1_dim_elements->[0];
    $col = $x1_dim_elements->[1];
  }
  else {
    $row = 1;
    $row *= $_ for @$x1_dim_elements;
    $col = 1;
  }
  
  my $x2 = Rstats::Func::as_vector($r, $x1);
  
  return Rstats::Func::matrix($r, $x2, $row, $col);
}

sub I {
  my $r = shift;
  
  my $x1 = shift;
  
  my $x2 = Rstats::Func::c_($r, $x1);
  Rstats::Func::copy_attrs_to($r, $x1, $x2);
  $x2->class('AsIs');
  
  return $x2;
}

sub subset {
  my $r = shift;
  
  my ($x1, $x_condition, $x_names)
    = args_array($r, ['x1', 'condition', 'names'], @_);
  
  $x_names = Rstats::Func::NULL($r) unless defined $x_names;
  
  my $x2 = $x1->get($x_condition, $x_names);
  
  return $x2;
}

sub t {
  my $r = shift;
  
  my $x1 = shift;
  
  my $x1_row = Rstats::Func::dim($r, $x1)->values->[0];
  my $x1_col = Rstats::Func::dim($r, $x1)->values->[1];
  
  my $x2 = matrix($r, 0, $x1_col, $x1_row);
  
  for my $row (1 .. $x1_row) {
    for my $col (1 .. $x1_col) {
      my $value = $x1->value($row, $col);
      $x2->at($col, $row);
      Rstats::Func::set($r, $x2, $value);
    }
  }
  
  return $x2;
}

sub transform {
  my $r = shift;
  
  my $x1 = shift;
  my @args = @_;

  my $new_names = Rstats::Func::names($r, $x1)->values;
  my $new_elements = $x1->list;
  
  my $names = Rstats::Func::names($r, $x1)->values;
  
  while (my ($new_name, $new_v) = splice(@args, 0, 2)) {
    if (Rstats::Func::is_character($r, $new_v)) {
      $new_v = Rstats::Func::I($r, $new_v);
    }

    my $found_pos = -1;
    for (my $i = 0; $i < @$names; $i++) {
      my $name = $names->[$i];
      if ($new_name eq $name) {
        $found_pos = $i;
        last;
      }
    }
    
    if ($found_pos == -1) {
      push @$new_names, $new_name;
      push @$new_elements, $new_v;
    }
    else {
      $new_elements->[$found_pos] = $new_v;
    }
  }
  
  
  my @new_args;
  for (my $i = 0; $i < @$new_names; $i++) {
    push @new_args, $new_names->[$i], $new_elements->[$i];
  }
  
  my $x2 = Rstats::Func::data_frame($r, @new_args);
  
  return $x2;
}

sub na_omit {
  my $r = shift;
  
  my $x1 = shift;
  
  my @poss;
  for my $v (@{$x1->list}) {
    for (my $index = 1; $index <= $x1->{row_length}; $index++) {
      push @poss, $index unless defined $v->value($index);
    }
  }
  
  my $x2 = $x1->get(-c_($r, @poss), NULL($r));
  
  return $x2;
}

# TODO: merge is not implemented yet
sub merge {
  my $r = shift;

  die "Error in merge() : merge is not implemented yet";
  
  my ($x1, $x2, $x_all, $x_all_x, $x_all_y, $x_by, $x_by_x, $x_by_y, $x_sort)
    = args_array($r, [qw/x1 x2 all all.x all.y by by.x by.y sort/], @_);
  
  # Join way
  $x_all = Rstats::Func::FALSE($r) unless defined $x_all;
  $x_all_x = Rstats::Func::FALSE($r) unless defined $x_all_x;
  $x_all_y = Rstats::Func::FALSE($r) unless defined $x_all_y;
  my $all;
  if ($x_all) {
    $all = 'both';
  }
  elsif ($x_all_x) {
    $all = 'left';
  }
  elsif ($x_all_y) {
    $all = 'rigth';
  }
  else {
    $all = 'common';
  }
  
  # ID
  $x_by = Rstats::Func::names($r, $x1)->get(1) unless defined $x_by;
  $x_by_x = $x_by unless defined $x_by_x;
  $x_by_y = $x_by unless defined $x_by_y;
  my $by_x = $x_by_x->value;
  my $by_y = $x_by_y->value;
  
  # Sort
  my $sort = defined $x_sort ? $x_sort->value : 0;
}

my $type_level = {
  character => 6,
  complex => 5,
  double => 4,
  integer => 3,
  logical => 2,
  na => 1
};

sub higher_type {
  my $r = shift;
  
  my ($type1, $type2) = @_;
  
  if ($type_level->{$type1} > $type_level->{$type2}) {
    return $type1;
  }
  else {
    return $type2;
  }
}

# TODO
#read.table(file, header = FALSE, sep = "", quote = "\"'",
#           dec = ".", row.names, col.names,
#           as.is = !stringsAsFactors,
#           na.strings = "NA", colClasses = NA, nrows = -1,
#           skip = 0, check.names = TRUE, fill = !blank.lines.skip,
#           strip.white = FALSE, blank.lines.skip = TRUE,
#           comment.char = "#",
#           allowEscapes = FALSE, flush = FALSE,
#           stringsAsFactors = default.stringsAsFactors(),
#           encoding = "unknown")
sub read_table {
  my $r = shift;
  
  my ($x_file, $x_sep, $x_skip, $x_nrows, $x_header, $x_comment_char, $x_row_names, $x_encoding)
    = args_array($r, [qw/file sep skip nrows header comment.char row.names encoding/], @_);
  
  my $file = $x_file->value;
  open(my $fh, '<', $file)
    or Carp::croak "cannot open file '$file': $!";
  
  # Separater
  my $sep = defined $x_sep ? $x_sep->value : "\\s+";
  my $encoding = defined $x_encoding ? $x_encoding->value : 'UTF-8';
  my $skip = defined $x_skip ? $x_skip->value : 0;
  my $header_opt = defined $x_header ? $x_header->value : 0;
  
  my $type_columns;
  my $columns = [];
  my $row_size;
  my $header;
  while (my $line = <$fh>) {
    if ($skip > 0) {
      $skip--;
      next;
    }
    $line = Encode::decode($encoding, $line);
    $line =~ s/\x0D?\x0A?$//;
    
    if ($header_opt && !$header) {
      $header = [split(/$sep/, $line)];
      next;
    }
    
    my @row = split(/$sep/, $line);
    my $current_row_size = @row;
    $row_size ||= $current_row_size;
    
    # Row size different
    Carp::croak "line $. did not have $row_size elements"
      if $current_row_size != $row_size;
    
    $type_columns ||= [('logical') x $row_size];
    
    for (my $i = 0; $i < @row; $i++) {
      
      $columns->[$i] ||= [];
      push @{$columns->[$i]}, $row[$i];
      my $type;
      if (defined Rstats::Util::looks_like_na($row[$i])) {
        $type = 'logical';
      }
      elsif (defined Rstats::Util::looks_like_logical($row[$i])) {
        $type = 'logical';
      }
      elsif (defined Rstats::Util::looks_like_integer($row[$i])) {
        $type = 'integer';
      }
      elsif (defined Rstats::Util::looks_like_double($row[$i])) {
        $type = 'double';
      }
      elsif (defined Rstats::Util::looks_like_complex($row[$i])) {
        $type = 'complex';
      }
      else {
        $type = 'character';
      }
      $type_columns->[$i] = Rstats::Func::higher_type($r, $type_columns->[$i], $type);
    }
  }
  
  my $data_frame_args = [];
  for (my $i = 0; $i < $row_size; $i++) {
    if (defined $header->[$i]) {
      push @$data_frame_args, $header->[$i];
    }
    else {
      push @$data_frame_args, "V" . ($i + 1);
    }
    my $type = $type_columns->[$i];
    if ($type eq 'character') {
      my $x1 = Rstats::Func::c_($r, @{$columns->[$i]});
      push @$data_frame_args, Rstats::Func::as_factor($r, $x1);
    }
    elsif ($type eq 'complex') {
      my $x1 = Rstats::Func::c_($r, @{$columns->[$i]});
      push @$data_frame_args, Rstats::Func::as_complex($r, $x1);
    }
    elsif ($type eq 'double') {
      my $x1 = Rstats::Func::c_($r, @{$columns->[$i]});
      push @$data_frame_args, Rstats::Func::as_double($r, Rstats::Func::as_double($r, $x1));
    }
    elsif ($type eq 'integer') {
      my $x1 = Rstats::Func::c_($r, @{$columns->[$i]});
      push @$data_frame_args, Rstats::Func::as_integer($r, $x1);
    }
    else {
      my $x1 = Rstats::Func::c_($r, @{$columns->[$i]});
      push @$data_frame_args, Rstats::Func::as_logical($r, $x1);
    }
  }
  
  my $d1 = Rstats::Func::data_frame($r, @$data_frame_args);
  
  return $d1;
}

sub interaction {
  my $r = shift;
  
  my $opt;
  $opt = ref $_[-1] eq 'HASH' ? pop : {};
  my @xs = map { Rstats::Func::as_factor($r, to_object($r, $_)) } @_;
  my ($x_drop, $x_sep);
  ($x_drop, $x_sep) = args_array($r, ['drop', 'sep'], $opt);
  
  $x_sep = Rstats::Func::c_($r, ".") unless defined $x_sep;
  my $sep = $x_sep->value;
  
  $x_drop = Rstats::Func::FALSE($r) unless defined $x_drop;
  
  my $max_length;
  my $values_list = [];
  for my $x (@xs) {
    my $length = Rstats::Func::length($r, $x)->value;
    $max_length = $length if !defined $max_length || $length > $max_length;
  }
  
  # Vector
  my $f1_elements = [];
  for (my $i = 0; $i < $max_length; $i++) {
    my $chars = [];
    for my $x (@xs) {
      my $fix_x = Rstats::Func::as_character($r, $x);
      my $length = Rstats::Func::get_length($r, $fix_x);
      push @$chars, $fix_x->value(($i % $length) + 1)
    }
    my $value = join $sep, @$chars;
    push @$f1_elements, $value;
  }
  
  # Levels
  my $f1;
  my $f1_levels_elements = [];
  if ($x_drop) {
    $f1_levels_elements = $f1_elements;
    $f1 = factor($r, c_($r, @$f1_elements));
  }
  else {
    my $levels = [];
    for my $x (@xs) {
      push @$levels, Rstats::Func::levels($r, $x)->values;
    }
    my $cps = Rstats::Util::cross_product($levels);
    for my $cp (@$cps) {
      my $value = join $sep, @$cp;
      push @$f1_levels_elements, $value;
    }
    $f1_levels_elements = [sort {$a cmp $b} @$f1_levels_elements];
    $f1 = factor($r, c_($r, @$f1_elements), {levels => Rstats::Func::c_($r, @$f1_levels_elements)});
  }
  
  return $f1;
}

sub gl {
  my $r = shift;
  
  my ($x_n, $x_k, $x_length, $x_labels, $x_ordered)
    = args_array($r, [qw/n k length labels ordered/], @_);
  
  my $n = $x_n->value;
  my $k = $x_k->value;
  $x_length = Rstats::Func::c_($r, $n * $k) unless defined $x_length;
  my $length = $x_length->value;
  
  my $x_levels = Rstats::Func::c_($r, 1 .. $n);
  $x_levels = Rstats::Func::as_character($r, $x_levels);
  my $levels = $x_levels->values;
  
  my $x1_elements = [];
  my $level = 1;
  my $j = 1;
  for (my $i = 0; $i < $length; $i++) {
    if ($j > $k) {
      $j = 1;
      $level++;
    }
    if ($level > @$levels) {
      $level = 1;
    }
    push @$x1_elements, $level;
    $j++;
  }
  
  my $x1 = Rstats::Func::c_($r, @$x1_elements);
  
  $x_labels = $x_levels unless defined $x_labels;
  $x_ordered = Rstats::Func::FALSE($r) unless defined $x_ordered;
  
  return factor($r, $x1, {levels => $x_levels, labels => $x_labels, ordered => $x_ordered});
}

sub upper_tri {
  my $r = shift;
  
  my ($x1_m, $x1_diag) = args_array($r, ['m', 'diag'], @_);
  
  my $diag = defined $x1_diag ? $x1_diag->value : 0;
  
  my $x2_values = [];
  if (Rstats::Func::is_matrix($r, $x1_m)) {
    my $x1_dim_values = Rstats::Func::dim($r, $x1_m)->values;
    my $rows_count = $x1_dim_values->[0];
    my $cols_count = $x1_dim_values->[1];
    
    for (my $col = 0; $col < $cols_count; $col++) {
      for (my $row = 0; $row < $rows_count; $row++) {
        my $x2_value;
        if ($diag) {
          $x2_value = $col >= $row ? 1 : 0;
        }
        else {
          $x2_value = $col > $row ? 1 : 0;
        }
        push @$x2_values, $x2_value;
      }
    }
    
    my $x2 = matrix($r, Rstats::Func::c_logical($r, @$x2_values), $rows_count, $cols_count);
    
    return $x2;
  }
  else {
    Carp::croak 'Error in upper_tri() : Not implemented';
  }
}

sub lower_tri {
  my $r = shift;
  
  my ($x1_m, $x1_diag) = args_array($r, ['m', 'diag'], @_);
  
  my $diag = defined $x1_diag ? $x1_diag->value : 0;
  
  my $x2_values = [];
  if (Rstats::Func::is_matrix($r, $x1_m)) {
    my $x1_dim_values = Rstats::Func::dim($r, $x1_m)->values;
    my $rows_count = $x1_dim_values->[0];
    my $cols_count = $x1_dim_values->[1];
    
    for (my $col = 0; $col < $cols_count; $col++) {
      for (my $row = 0; $row < $rows_count; $row++) {
        my $x2_value;
        if ($diag) {
          $x2_value = $col <= $row ? 1 : 0;
        }
        else {
          $x2_value = $col < $row ? 1 : 0;
        }
        push @$x2_values, $x2_value;
      }
    }
    
    my $x2 = matrix($r, Rstats::Func::c_logical($r, @$x2_values), $rows_count, $cols_count);
    
    return $x2;
  }
  else {
    Carp::croak 'Error in lower_tri() : Not implemented';
  }
}

sub diag {
  my $r = shift;
  
  my $x1 = to_object($r, shift);
  
  my $size;
  my $x2_values;
  if (Rstats::Func::get_length($r, $x1) == 1) {
    $size = $x1->value;
    $x2_values = [];
    push @$x2_values, 1 for (1 .. $size);
  }
  else {
    $size = Rstats::Func::get_length($r, $x1);
    $x2_values = $x1->values;
  }
  
  my $x2 = matrix($r, 0, $size, $size);
  for (my $i = 0; $i < $size; $i++) {
    $x2->at($i + 1, $i + 1);
    $x2->set($x2_values->[$i]);
  }

  return $x2;
}

sub set_diag {
  my $r = shift;
  
  my $x1 = to_object($r, shift);
  my $x2 = to_object($r, shift);
  
  my $x2_elements;
  my $x1_dim_values = Rstats::Func::dim($r, $x1)->values;
  my $size = $x1_dim_values->[0] < $x1_dim_values->[1] ? $x1_dim_values->[0] : $x1_dim_values->[1];
  
  $x2 = array($r, $x2, $size);
  my $x2_values = $x2->values;
  
  for (my $i = 0; $i < $size; $i++) {
    $x1->at($i + 1, $i + 1);
    $x1->set($x2_values->[$i]);
  }
  
  return $x1;
}

sub kronecker {
  my $r = shift;
  
  my $x1 = to_object($r, shift);
  my $x2 = to_object($r, shift);
  
  ($x1, $x2) = @{Rstats::Func::upgrade_type($r, [$x1, $x2])} if $x1->get_type ne $x2->get_type;
  
  my $x1_dim = Rstats::Func::dim($r, $x1);
  my $x2_dim = Rstats::Func::dim($r, $x2);
  my $dim_max_length
    = Rstats::Func::get_length($r, $x1_dim) > Rstats::Func::get_length($r, $x2_dim) ? Rstats::Func::get_length($r, $x1_dim) : Rstats::Func::get_length($r, $x2_dim);
  
  my $x3_dim_values = [];
  my $x1_dim_values = $x1_dim->values;
  my $x2_dim_values = $x2_dim->values;
  for (my $i = 0; $i < $dim_max_length; $i++) {
    my $x1_dim_value = $x1_dim_values->[$i] || 1;
    my $x2_dim_value = $x2_dim_values->[$i] || 1;
    my $x3_dim_value = $x1_dim_value * $x2_dim_value;
    push @$x3_dim_values, $x3_dim_value;
  }
  
  my $x3_dim_product = 1;
  $x3_dim_product *= $_ for @{$x3_dim_values};
  
  my $x3_values = [];
  for (my $i = 0; $i < $x3_dim_product; $i++) {
    my $x3_index = Rstats::Util::pos_to_index($i, $x3_dim_values);
    my $x1_index = [];
    my $x2_index = [];
    for (my $k = 0; $k < @$x3_index; $k++) {
      my $x3_i = $x3_index->[$k];
      
      my $x1_dim_value = $x1_dim_values->[$k] || 1;
      my $x2_dim_value = $x2_dim_values->[$k] || 1;

      my $x1_ind = int(($x3_i - 1)/$x2_dim_value) + 1;
      push @$x1_index, $x1_ind;
      my $x2_ind = $x3_i - $x2_dim_value * ($x1_ind - 1);
      push @$x2_index, $x2_ind;
    }
    my $x1_value = $x1->value(@$x1_index);
    my $x2_value = $x2->value(@$x2_index);
    my $x3_value = multiply($r, $x1_value, $x2_value);
    push @$x3_values, $x3_value;
  }
  
  my $x3 = array($r, c_($r, @$x3_values), Rstats::Func::c_($r, @$x3_dim_values));
  
  return $x3;
}

sub outer {
  my $r = shift;
  
  my $x1 = to_object($r, shift);
  my $x2 = to_object($r, shift);
  
  ($x1, $x2) = @{Rstats::Func::upgrade_type($r, [$x1, $x2])} if $x1->get_type ne $x2->get_type;
  
  my $x1_dim = Rstats::Func::dim($r, $x1);
  my $x2_dim = Rstats::Func::dim($r, $x2);
  my $x3_dim = [@{$x1_dim->values}, @{$x2_dim->values}];
  
  my $indexs = [];
  for my $x3_d (@$x3_dim) {
    push @$indexs, [1 .. $x3_d];
  }
  my $poses = Rstats::Util::cross_product($indexs);
  
  my $x1_dim_length = Rstats::Func::get_length($r, $x1_dim);
  my $x3_values = [];
  for my $pos (@$poses) {
    my $pos_tmp = [@$pos];
    my $x1_pos = [splice @$pos_tmp, 0, $x1_dim_length];
    my $x2_pos = $pos_tmp;
    my $x1_value = $x1->value(@$x1_pos);
    my $x2_value = $x2->value(@$x2_pos);
    my $x3_value = $x1_value * $x2_value;
    push @$x3_values, $x3_value;
  }
  
  my $x3 = array($r, c_($r, @$x3_values), Rstats::Func::c_($r, @$x3_dim));
  
  return $x3;
}



sub sub {
  my $r = shift;
  
  my ($x1_pattern, $x1_replacement, $x1_x, $x1_ignore_case)
    = args_array($r, ['pattern', 'replacement', 'x', 'ignore.case'], @_);
  
  my $pattern = $x1_pattern->value;
  my $replacement = $x1_replacement->value;
  my $ignore_case = defined $x1_ignore_case ? $x1_ignore_case->value : 0;
  
  my $x2_values = [];
  for my $x (@{$x1_x->values}) {
    if (!defined $x) {
      push @$x2_values, undef;
    }
    else {
      if ($ignore_case) {
        $x =~ s/$pattern/$replacement/i;
      }
      else {
        $x =~ s/$pattern/$replacement/;
      }
      push @$x2_values, "$x";
    }
  }
  
  my $x2 = Rstats::Func::c_character($r, @$x2_values);
  Rstats::Func::copy_attrs_to($r, $x1_x, $x2);
  
  return $x2;
}

sub gsub {
  my $r = shift;
  
  my ($x1_pattern, $x1_replacement, $x1_x, $x1_ignore_case)
    = args_array($r, ['pattern', 'replacement', 'x', 'ignore.case'], @_);
  
  my $pattern = $x1_pattern->value;
  my $replacement = $x1_replacement->value;
  my $ignore_case = defined $x1_ignore_case ? $x1_ignore_case->value : 0;
  
  my $x2_values = [];
  for my $x (@{$x1_x->values}) {
    if (!defined $x) {
      push @$x2_values, $x;
    }
    else {
      if ($ignore_case) {
        $x =~ s/$pattern/$replacement/gi;
      }
      else {
        $x =~ s/$pattern/$replacement/g;
      }
      push @$x2_values, $x;
    }
  }
  
  my $x2 = Rstats::Func::c_character($r, @$x2_values);
  Rstats::Func::copy_attrs_to($r, $x1_x, $x2);
  
  return $x2;
}

sub grep {
  my $r = shift;
  
  my ($x1_pattern, $x1_x, $x1_ignore_case) = args_array($r, ['pattern', 'x', 'ignore.case'], @_);
  
  my $pattern = $x1_pattern->value;
  my $ignore_case = defined $x1_ignore_case ? $x1_ignore_case->value : 0;
  
  my $x2_values = [];
  my $x1_x_values = $x1_x->values;
  for (my $i = 0; $i < @$x1_x_values; $i++) {
    my $x = $x1_x_values->[$i];
    
    unless (!defined $x) {
      if ($ignore_case) {
        if ($x =~ /$pattern/i) {
          push @$x2_values, $i + 1;
        }
      }
      else {
        if ($x =~ /$pattern/) {
          push @$x2_values, $i + 1;
        }
      }
    }
  }
  
  return Rstats::Func::c_double($r, @$x2_values);
}

sub C_ {
  my $r = shift;
  my $seq_str = shift;

  my $by;
  my $mode;
  if ($seq_str =~ s/^(.+)\*//) {
    $by = $1;
  }
  
  my $from;
  my $to;
  if ($seq_str =~ /([^\:]+)(?:\:(.+))?/) {
    $from = $1;
    $to = $2;
    $to = $from unless defined $to;
  }
  
  my $vector = seq($r,{from => $from, to => $to, by => $by});
  
  return $vector;
}

sub col {
  my $r = shift;
  my $x1 = shift;
  
  my $nrow = nrow($r, $x1)->value;
  my $ncol = ncol($r, $x1)->value;
  
  my @values;
  for my $col (1 .. $ncol) {
    push @values, ($col) x $nrow;
  }
  
  return array($r, c_($r, @values), Rstats::Func::c_($r, $nrow, $ncol));
}

sub chartr {
  my $r = shift;
  
  my ($x1_old, $x1_new, $x1_x) = args_array($r, ['old', 'new', 'x'], @_);
  
  my $old = $x1_old->value;
  my $new = $x1_new->value;
  
  my $x2_values = [];
  for my $x (@{$x1_x->values}) {
    if (!defined $x) {
      push @$x2_values, $x;
    }
    else {
      $old =~ s#/#\/#;
      $new =~ s#/#\/#;
      eval "\$x =~ tr/$old/$new/";
      Carp::croak $@ if $@;
      push @$x2_values, "$x";
    }
  }
  
  my $x2 = Rstats::Func::c_character($r, @$x2_values);
  Rstats::Func::copy_attrs_to($r, $x1_x, $x2);
  
  return $x2;
}

sub charmatch {
  my $r = shift;
  
  my ($x1_x, $x1_table) = args_array($r, ['x', 'table'], @_);
  
  die "Error in charmatch() : Not implemented"
    unless $x1_x->get_type eq 'character' && $x1_table->get_type eq 'character';
  
  my $x2_values = [];
  for my $x1_x_value (@{$x1_x->values}) {
    my $x1_x_char = $x1_x_value;
    my $x1_x_char_q = quotemeta($x1_x_char);
    my $match_count;
    my $match_pos;
    my $x1_table_values = $x1_table->values;
    for (my $k = 0; $k < Rstats::Func::get_length($r, $x1_table); $k++) {
      my $x1_table_char = $x1_table_values->[$k];
      if ($x1_table_char =~ /$x1_x_char_q/) {
        $match_count++;
        $match_pos = $k;
      }
    }
    if ($match_count == 0) {
      push @$x2_values, undef;
    }
    elsif ($match_count == 1) {
      push @$x2_values, $match_pos + 1;
    }
    elsif ($match_count > 1) {
      push @$x2_values, 0;
    }
  }
  
  return Rstats::Func::c_double($r, @$x2_values);
}



sub nrow {
  my $r = shift;
  
  my $x1 = shift;
  
  if (Rstats::Func::is_data_frame($r, $x1)) {
    return Rstats::Func::c_($r, $x1->{row_length});
  }
  elsif (Rstats::Func::is_list($r, $x1)) {
    return Rstats::Func::NULL($r);
  }
  else {
    return Rstats::Func::c_($r, Rstats::Func::dim($r, $x1)->values->[0]);
  }
}

sub is_element {
  my $r = shift;
  
  my ($x1, $x2) = (to_object($r, shift), to_object($r, shift));
  
  Carp::croak "mode is diffrence" if $x1->get_type ne $x2->get_type;
  
  my $type = $x1->get_type;
  my $x1_values = $x1->values;
  my $x2_values = $x2->values;
  my $x3_values = [];
  for my $x1_value (@$x1_values) {
    my $match;
    for my $x2_value (@$x2_values) {
      if ($type eq 'character') {
        if ($x1_value eq $x2_value) {
          $match = 1;
          last;
        }
      }
      elsif ($type eq 'double' || $type eq 'integer') {
        if ($x1_value == $x2_value) {
          $match = 1;
          last;
        }
      }
      elsif ($type eq 'complex') {
        if ($x1_value->{re} == $x2_value->{re} && $x1_value->{im} == $x2_value->{im}) {
          $match = 1;
          last;
        }
      }
    }
    push @$x3_values, $match ? 1 : 0;
  }
  
  return Rstats::Func::c_logical($r, @$x3_values);
}

sub setequal {
  my $r = shift;
  
  my ($x1, $x2) = (to_object($r, shift), to_object($r, shift));
  
  Carp::croak "mode is diffrence" if $x1->get_type ne $x2->get_type;
  
  my $x3 = Rstats::Func::sort($r, $x1);
  my $x4 = Rstats::Func::sort($r, $x2);
  
  return Rstats::Func::FALSE($r) if Rstats::Func::get_length($r, $x3) ne Rstats::Func::get_length($r, $x4);
  
  my $not_equal;
  my $x3_elements = Rstats::Func::decompose($r, $x3);
  my $x4_elements = Rstats::Func::decompose($r, $x4);
  for (my $i = 0; $i < Rstats::Func::get_length($r, $x3); $i++) {
    unless ($x3_elements->[$i] == $x4_elements->[$i]) {
      $not_equal = 1;
      last;
    }
  }
  
  return $not_equal ? Rstats::Func::FALSE($r) : TRUE($r);
}

sub setdiff {
  my $r = shift;
  
  my ($x1, $x2) = (to_object($r, shift), to_object($r, shift));
  
  Carp::croak "mode is diffrence" if $x1->get_type ne $x2->get_type;
  
  my $x1_elements = Rstats::Func::decompose($r, $x1);
  my $x2_elements = Rstats::Func::decompose($r, $x2);
  my $x3_elements = [];
  for my $x1_element (@$x1_elements) {
    my $match;
    for my $x2_element (@$x2_elements) {
      if ($x1_element == $x2_element) {
        $match = 1;
        last;
      }
    }
    push @$x3_elements, $x1_element unless $match;
  }

  return Rstats::Func::c_($r, @$x3_elements);
}

sub intersect {
  my $r = shift;
  
  my ($x1, $x2) = (to_object($r, shift), to_object($r, shift));
  
  Carp::croak "mode is diffrence" if $x1->get_type ne $x2->get_type;
  
  my $x1_elements = Rstats::Func::decompose($r, $x1);
  my $x2_elements = Rstats::Func::decompose($r, $x2);
  my $x3_elements = [];
  for my $x1_element (@$x1_elements) {
    for my $x2_element (@$x2_elements) {
      if ($x1_element == $x2_element) {
        push @$x3_elements, $x1_element;
      }
    }
  }
  
  return Rstats::Func::c_($r, @$x3_elements);
}

sub union {
  my $r = shift;
  
  my ($x1, $x2) = (to_object($r, shift), to_object($r, shift));

  Carp::croak "mode is diffrence" if $x1->get_type ne $x2->get_type;
  
  my $x3 = Rstats::Func::c_($r, $x1, $x2);
  my $x4 = unique($r, $x3);
  
  return $x4;
}

sub diff {
  my $r = shift;
  
  my $x1 = to_object($r, shift);
  
  my $x2_elements = [];
  my $x1_elements = Rstats::Func::decompose($r, $x1);
  for (my $i = 0; $i < Rstats::Func::get_length($r, $x1) - 1; $i++) {
    my $x1_element1 = $x1_elements->[$i];
    my $x1_element2 = $x1_elements->[$i + 1];
    my $x2_element = $x1_element2 - $x1_element1;
    push @$x2_elements, $x2_element;
  }
  my $x2 = Rstats::Func::c_($r, @$x2_elements);
  Rstats::Func::copy_attrs_to($r, $x1, $x2);
  
  return $x2;
}

sub nchar {
  my $r = shift;
  my $x1 = to_object($r, shift);
  
  if ($x1->get_type eq 'character') {
    my $x2_elements = [];
    for my $x1_element (@{Rstats::Func::decompose($r, $x1)}) {
      if (Rstats::Func::is_na($r, $x1_element)) {
        push @$x2_elements, $x1_element;
      }
      else {
        my $x2_element = Rstats::Func::c_integer($r, CORE::length Rstats::Func::value($r, $x1_element));
        push @$x2_elements, $x2_element;
      }
    }
    my $x2 = Rstats::Func::c_($r, @$x2_elements);
    Rstats::Func::copy_attrs_to($r, $x1, $x2);
    
    return $x2;
  }
  else {
    Carp::croak "Error in nchar() : Not implemented";
  }
}

sub tolower {
  my $r = shift;
  
  my $x1 = to_object($r, shift);
  
  if ($x1->get_type eq 'character') {
    my $x2_elements = [];
    for my $x1_element (@{Rstats::Func::decompose($r, $x1)}) {
      if (Rstats::Func::is_na($r, $x1_element)) {
        push @$x2_elements, $x1_element;
      }
      else {
        my $x2_element = Rstats::Func::c_character($r, lc Rstats::Func::value($r, $x1_element));
        push @$x2_elements, $x2_element;
      }
    }
    my $x2 = Rstats::Func::c_($r, @$x2_elements);
    Rstats::Func::copy_attrs_to($r, $x1, $x2);
    
    return $x2;
  }
  else {
    return $x1;
  }
}

sub toupper {
  my $r = shift;
  
  my $x1 = to_object($r, shift);
  
  if ($x1->get_type eq 'character') {
    my $x2_elements = [];
    for my $x1_element (@{Rstats::Func::decompose($r, $x1)}) {
      if (Rstats::Func::is_na($r, $x1_element)) {
        push @$x2_elements, $x1_element;
      }
      else {
        my $x2_element = Rstats::Func::c_character($r, uc Rstats::Func::value($r, $x1_element));
        push @$x2_elements, $x2_element;
      }
    }
    my $x2 = Rstats::Func::c_($r, @$x2_elements);
    Rstats::Func::copy_attrs_to($r, $x1, $x2);
    
    return $x2;
  }
  else {
    return $x1;
  }
}

sub match {
  my $r = shift;
  
  my ($x1, $x2) = (to_object($r, shift), to_object($r, shift));
  
  my $x1_elements = Rstats::Func::decompose($r, $x1);
  my $x2_elements = Rstats::Func::decompose($r, $x2);
  my @matches;
  for my $x1_element (@$x1_elements) {
    my $i = 1;
    my $match;
    for my $x2_element (@$x2_elements) {
      if ($x1_element == $x2_element) {
        $match = 1;
        last;
      }
      $i++;
    }
    if ($match) {
      push @matches, $i;
    }
    else {
      push @matches, undef;
    }
  }
  
  return Rstats::Func::c_double($r, @matches);
}



sub append {
  my $r = shift;
  
  my ($x1, $x2, $x_after) = args_array($r, ['x1', 'x2', 'after'], @_);
  
  # Default
  $x_after = NULL($r) unless defined $x_after;
  
  my $x1_length = Rstats::Func::get_length($r, $x1);
  $x_after = Rstats::Func::c_($r, $x1_length) if Rstats::Func::is_null($r, $x_after);
  my $after = $x_after->value;
  
  my $x1_elements = Rstats::Func::decompose($r, $x1);
  my $x2_elements = Rstats::Func::decompose($r, $x2);
  my @x3_elements = @$x1_elements;
  splice @x3_elements, $after, 0, @$x2_elements;
  
  my $x3 = Rstats::Func::c_($r, @x3_elements);
  
  return $x3;
}



sub cbind {
  my $r = shift;
  
  my @xs = @_;

  return Rstats::Func::NULL($r) unless @xs;
  
  if (Rstats::Func::is_data_frame($r, $xs[0])) {
    # Check row count
    my $first_row_length;
    my $different;
    for my $x (@xs) {
      if ($first_row_length) {
        $different = 1 if $x->{row_length} != $first_row_length;
      }
      else {
        $first_row_length = $x->{row_length};
      }
    }
    Carp::croak "cbind need same row count data frame"
      if $different;
    
    # Create new data frame
    my @data_frame_args;
    for my $x (@xs) {
      my $names = Rstats::Func::names($r, $x)->values;
      for my $name (@$names) {
        push @data_frame_args, $name, $x->getin($name);
      }
    }
    my $data_frame = Rstats::Func::data_frame($r, @data_frame_args);
    
    return $data_frame;
  }
  else {
    my $row_count_needed;
    my $col_count_total;
    my $x2_elements = [];
    for my $_x (@xs) {
      
      my $x1 = to_object($r, $_x);
      my $x1_dim_elements = Rstats::Func::decompose($r, Rstats::Func::dim($r, $x1));
      
      my $row_count;
      if (Rstats::Func::is_matrix($r, $x1)) {
        $row_count = $x1_dim_elements->[0];
        $col_count_total += $x1_dim_elements->[1];
      }
      elsif (Rstats::Func::is_vector($r, $x1)) {
        $row_count = $x1->dim_as_array->values->[0];
        $col_count_total += 1;
      }
      else {
        Carp::croak "cbind or rbind can only receive matrix and vector";
      }
      
      $row_count_needed = $row_count unless defined $row_count_needed;
      Carp::croak "Row count is different" if $row_count_needed ne $row_count;
      
      push @$x2_elements, @{Rstats::Func::decompose($r, $x1)};
    }
    my $matrix = matrix($r, c_($r, @$x2_elements), $row_count_needed, $col_count_total);
    
    return $matrix;
  }
}

sub ceiling {
  my $r = shift;
  my $_x1 = shift;
  
  my $x1 = to_object($r, $_x1);
  my @x2_elements
    = map { Rstats::Func::c_double($r, POSIX::ceil Rstats::Func::value($r, $_)) }
    @{Rstats::Func::decompose($r, $x1)};
  
  my $x2 = Rstats::Func::c_($r, @x2_elements);
  Rstats::Func::copy_attrs_to($r, $x1, $x2);
  
  Rstats::Func::mode($r, $x2, 'double');
  
  return $x2;
}

sub colMeans {
  my $r = shift;
  my $x1 = shift;
  
  my $dim_values = Rstats::Func::dim($r, $x1)->values;
  if (@$dim_values == 2) {
    my $x1_values = [];
    for my $row (1 .. $dim_values->[0]) {
      my $x1_value = 0;
      $x1_value += $x1->value($row, $_) for (1 .. $dim_values->[1]);
      push @$x1_values, $x1_value / $dim_values->[1];
    }
    return Rstats::Func::c_($r, @$x1_values);
  }
  else {
    Carp::croak "Can't culculate colSums";
  }
}

sub colSums {
  my $r = shift;
  my $x1 = shift;
  
  my $dim_values = Rstats::Func::dim($r, $x1)->values;
  if (@$dim_values == 2) {
    my $x1_values = [];
    for my $row (1 .. $dim_values->[0]) {
      my $x1_value = 0;
      $x1_value += $x1->value($row, $_) for (1 .. $dim_values->[1]);
      push @$x1_values, $x1_value;
    }
    return Rstats::Func::c_($r, @$x1_values);
  }
  else {
    Carp::croak "Can't culculate colSums";
  }
}





sub cummax {
  my $r = shift;
  
  my $x1 = to_object($r, shift);
  
  unless (Rstats::Func::get_length($r, $x1)) {
    Carp::carp 'no non-missing arguments to max; returning -Inf';
    return -(Rstats::Func::Inf($r));
  }
  
  my @x2_elements;
  my $x1_elements = Rstats::Func::decompose($r, $x1);
  my $max = shift @$x1_elements;
  push @x2_elements, $max;
  for my $element (@$x1_elements) {
    
    if (Rstats::Func::is_na($r, $element)) {
      return Rstats::Func::NA($r);
    }
    elsif (Rstats::Func::is_nan($r, $element)) {
      $max = $element;
    }
    if ($element > $max && !Rstats::Func::is_nan($r, $max)) {
      $max = $element;
    }
    push @x2_elements, $max;
  }
  
  return Rstats::Func::c_($r, @x2_elements);
}

sub cummin {
  my $r = shift;
  
  my $x1 = to_object($r, shift);
  
  unless (Rstats::Func::get_length($r, $x1)) {
    Carp::carp 'no non-missing arguments to max; returning -Inf';
    return -(Rstats::Func::Inf($r));
  }
  
  my @x2_elements;
  my $x1_elements = Rstats::Func::decompose($r, $x1);
  my $min = shift @$x1_elements;
  push @x2_elements, $min;
  for my $element (@$x1_elements) {
    if (Rstats::Func::is_na($r, $element)) {
      return Rstats::Func::NA($r);
    }
    elsif (Rstats::Func::is_nan($r, $element)) {
      $min = $element;
    }
    if ($element < $min && !Rstats::Func::is_nan($r, $min)) {
      $min = $element;
    }
    push @x2_elements, $min;
  }
  
  return Rstats::Func::c_($r, @x2_elements);
}



sub args_array {
  my $r = shift;
  
  my $names = shift;
  my $opt = ref $_[-1] eq 'HASH' ? pop @_ : {};
  my @args;
  for (my $i = 0; $i < @$names; $i++) {
    my $name = $names->[$i];
    my $arg;
    if (exists $opt->{$name}) {
      $arg = to_object($r, delete $opt->{$name});
    }
    elsif ($i < @_) {
      $arg = to_object($r, $_[$i]);
    }
    push @args, $arg;
  }
  
  Carp::croak "unused argument ($_)" for keys %$opt;
  
  return @args;
}

sub complex {
  my $r = shift;

  my ($x1_re, $x1_im, $x1_mod, $x1_arg) = args_array($r, ['re', 'im', 'mod', 'arg'], @_);
  
  $x1_mod = Rstats::Func::NULL($r) unless defined $x1_mod;
  $x1_arg = Rstats::Func::NULL($r) unless defined $x1_arg;

  my $x2_elements = [];
  # Create complex from mod and arg
  if (Rstats::Func::get_length($r, $x1_mod) || Rstats::Func::get_length($r, $x1_arg)) {
    my $x1_mod_length = Rstats::Func::get_length($r, $x1_mod);
    my $x1_arg_length = Rstats::Func::get_length($r, $x1_arg);
    my $longer_length = $x1_mod_length > $x1_arg_length ? $x1_mod_length : $x1_arg_length;
    
    my $x1_mod_elements = Rstats::Func::decompose($r, $x1_mod);
    my $x1_arg_elements = Rstats::Func::decompose($r, $x1_arg);
    for (my $i = 0; $i < $longer_length; $i++) {
      my $x_mod = $x1_mod_elements->[$i];
      $x_mod = Rstats::Func::c_double($r, 1) unless defined $x_mod;
      my $x_arg = $x1_arg_elements->[$i];
      $x_arg = Rstats::Func::c_double($r, 0) unless defined $x_arg;
      
      my $x_re = $x_mod * Rstats::Func::cos($r, $x_arg);
      my $x_im = $x_mod * Rstats::Func::sin($r, $x_arg);
      
      my $x2_element = Rstats::Func::complex($r, $x_re, $x_im);
      push @$x2_elements, $x2_element;
    }
  }
  # Create complex from re and im
  else {
    Carp::croak "mode should be numeric"
      unless Rstats::Func::is_numeric($r, $x1_re) && Rstats::Func::is_numeric($r, $x1_im);
    
    my $x1_re_elements = Rstats::Func::decompose($r, $x1_re);
    my $x1_im_elements = Rstats::Func::decompose($r, $x1_im);
    for (my $i = 0; $i <  Rstats::Func::get_length($r, $x1_im); $i++) {
      my $x_re;
      if (defined $x1_re_elements->[$i]) {
        $x_re = $x1_re_elements->[$i];
      }
      else {
        $x_re = Rstats::Func::c_double($r, 0);
      }
      my $x_im = $x1_im_elements->[$i];
      my $x2_element = Rstats::Func::c_complex(
        $r,
        {re => Rstats::Func::value($r, $x_re), im => Rstats::Func::value($r, $x_im)}
      );
      push @$x2_elements, $x2_element;
    }
  }
  
  return Rstats::Func::c_($r, @$x2_elements);
}


sub floor {
  my $r = shift;
  
  my $_x1 = shift;
  
  my $x1 = to_object($r, $_x1);
  
  my @x2_elements
    = map { Rstats::Func::c_double($r, POSIX::floor Rstats::Func::value($r, $_)) }
    @{Rstats::Func::decompose($r, $x1)};

  my $x2 = Rstats::Func::c_($r, @x2_elements);
  Rstats::Func::copy_attrs_to($r, $x1, $x2);
  Rstats::Func::mode($r, $x2, 'double');
  
  return $x2;
}

sub head {
  my $r = shift;
  
  my ($x1, $x_n) = args_array($r, ['x1', 'n'], @_);
  
  my $n = defined $x_n ? $x_n->value : 6;
  
  if (Rstats::Func::is_data_frame($r, $x1)) {
    my $max = $x1->{row_length} < $n ? $x1->{row_length} : $n;
    
    my $x_range = Rstats::Func::C_($r, "1:$max");
    my $x2 = $x1->get($x_range, Rstats::Func::NULL($r));
    
    return $x2;
  }
  else {
    my $x1_elements = Rstats::Func::decompose($r, $x1);
    my $max = Rstats::Func::get_length($r, $x1) < $n ? Rstats::Func::get_length($r, $x1) : $n;
    my @x2_elements;
    for (my $i = 0; $i < $max; $i++) {
      push @x2_elements, $x1_elements->[$i];
    }
    
    my $x2 = Rstats::Func::c_($r, @x2_elements);
    Rstats::Func::copy_attrs_to($r, $x1, $x2);
  
    return $x2;
  }
}

sub i_ {
  my $r = shift;
  
  my $i = Rstats::Func::c_complex($r, {re => 0, im => 1});
  
  return Rstats::Func::c_($r, $i);
}

sub ifelse {
  my $r = shift;
  
  my ($_x1, $value1, $value2) = @_;
  
  my $x1 = to_object($r, $_x1);
  my $x1_values = $x1->values;
  my @x2_values;
  for my $x1_value (@$x1_values) {
    local $_ = $x1_value;
    if ($x1_value) {
      push @x2_values, $value1;
    }
    else {
      push @x2_values, $value2;
    }
  }
  
  return Rstats::Func::array($r, c_($r, @x2_values));
}



sub max {
  my $r = shift;

  my @args = grep { !Rstats::Func::is_null($r, $_) } @_;
  
  my $x1 = Rstats::Func::c_($r, @args);
  
  unless (Rstats::Func::get_length($r, $x1)) {
    Carp::carp 'no non-missing arguments to max; returning -Inf';
    return -(Rstats::Func::Inf($r));
  }
  
  my $x1_elements = Rstats::Func::decompose($r, $x1);
  my $max = shift @$x1_elements;
  for my $element (@$x1_elements) {
    
    if (Rstats::Func::is_na($r, $element)) {
      return Rstats::Func::NA($r);
    }
    elsif (Rstats::Func::is_nan($r, $element)) {
      $max = $element;
    }
    if (!Rstats::Func::is_nan($r, $max) && Rstats::Func::value($r, $element > $max)) {
      $max = $element;
    }
  }
  
  return Rstats::Func::c_($r, $max);
}

sub mean {
  my $r = shift;
  
  my $x1 = to_object($r, shift);
  
  my $x2 = divide($r, sum($r, $x1), Rstats::Func::get_length($r, $x1));
  
  return $x2;
}

sub min {
  my $r = shift;
  
  my @args = grep { !Rstats::Func::is_null($r, $_) } @_;
  
  my $x1 = Rstats::Func::c_($r, @args);
  
  unless (Rstats::Func::get_length($r, $x1)) {
    Carp::carp 'no non-missing arguments to min; returning Inf';
    return Rstats::Func::Inf($r);
  }
  
  my $x1_elements = Rstats::Func::decompose($r, $x1);
  my $min = shift @$x1_elements;
  for my $element (@$x1_elements) {
    
    if (Rstats::Func::is_na($r, $element)) {
      return Rstats::Func::NA($r);
    }
    elsif (Rstats::Func::is_nan($r, $element)) {
      $min = $element;
    }
    if (!Rstats::Func::is_nan($r, $min) && Rstats::Func::value($r, $element < $min)) {
      $min = $element;
    }
  }
  
  return Rstats::Func::c_($r, $min);
}

sub order {
  my $r = shift;
  my $opt = ref $_[-1] eq 'HASH' ? pop @_ : {};
  my @xs = map { to_object($r, $_) } @_;
  
  my @xs_values;
  for my $x (@xs) {
    push @xs_values, $x->values;
  }

  my $decreasing = $opt->{decreasing} || Rstats::Func::FALSE($r);
  
  my @pos_vals;
  for my $i (0 .. @{$xs_values[0]} - 1) {
    my $pos_val = {pos => $i + 1};
    $pos_val->{val} = [];
    push @{$pos_val->{val}}, $xs_values[$_][$i] for (0 .. @xs_values);
    push @pos_vals, $pos_val;
  }
  
  my @sorted_pos_values = !$decreasing
    ? sort {
        my $comp;
        for (my $i = 0; $i < @xs_values; $i++) {
          $comp = $a->{val}[$i] <=> $b->{val}[$i];
          last if $comp != 0;
        }
        $comp;
      } @pos_vals
    : sort {
        my $comp;
        for (my $i = 0; $i < @xs_values; $i++) {
          $comp = $b->{val}[$i] <=> $a->{val}[$i];
          last if $comp != 0;
        }
        $comp;
      } @pos_vals;
  my @orders = map { $_->{pos} } @sorted_pos_values;
  
  return Rstats::Func::c_($r, @orders);
}

# TODO
# na.last
sub rank {
  my $r = shift;
  
  my $opt = ref $_[-1] eq 'HASH' ? pop @_ : {};
  my $x1 = to_object($r, shift);
  my $decreasing = $opt->{decreasing};
  
  my $x1_values = $x1->values;
  
  my @pos_vals;
  push @pos_vals, {pos => $_ + 1, value => $x1_values->[$_]} for (0 .. @$x1_values - 1);
  my @sorted_pos_values = sort { $a->{value} <=> $b->{value} } @pos_vals;
  
  # Rank
  for (my $i = 0; $i < @sorted_pos_values; $i++) {
    $sorted_pos_values[$i]{rank} = $i + 1;
  }
  
  # Average rank
  my $element_info = {};
  for my $sorted_pos_value (@sorted_pos_values) {
    my $value = $sorted_pos_value->{value};
    $element_info->{$value} ||= {};
    $element_info->{$value}{rank_total} += $sorted_pos_value->{rank};
    $element_info->{$value}{rank_count}++;
  }
  
  for my $sorted_pos_value (@sorted_pos_values) {
    my $value = $sorted_pos_value->{value};
    $sorted_pos_value->{rank_average}
      = $element_info->{$value}{rank_total} / $element_info->{$value}{rank_count};
  }
  
  my @sorted_pos_values2 = sort { $a->{pos} <=> $b->{pos} } @sorted_pos_values;
  my @rank = map { $_->{rank_average} } @sorted_pos_values2;
  
  return Rstats::Func::c_($r, @rank);
}

sub paste {
  my $r = shift;
  
  my $opt = ref $_[-1] eq 'HASH' ? pop @_ : {};
  my $sep = $opt->{sep};
  $sep = ' ' unless defined $sep;
  
  my $str = shift;
  my $x1 = shift;
  
  my $x1_values = $x1->values;
  my $x2_values = [];
  push @$x2_values, "$str$sep$_" for @$x1_values;
  
  return Rstats::Func::c_($r, @$x2_values);
}

sub pmax {
  my $r = shift;
  
  my @vs = @_;
  
  my @maxs;
  for my $v (@vs) {
    my $elements = Rstats::Func::decompose($r, $v);
    for (my $i = 0; $i <@$elements; $i++) {
      $maxs[$i] = $elements->[$i]
        if !defined $maxs[$i] || $elements->[$i] > $maxs[$i]
    }
  }
  
  return  Rstats::Func::c_($r, @maxs);
}

sub pmin {
  my $r = shift;
  
  my @vs = @_;
  
  my @mins;
  for my $v (@vs) {
    my $elements = Rstats::Func::decompose($r, $v);
    for (my $i = 0; $i <@$elements; $i++) {
      $mins[$i] = $elements->[$i]
        if !defined $mins[$i] || $elements->[$i] < $mins[$i];
    }
  }
  
  return Rstats::Func::c_($r, @mins);
}



sub range {
  my $r = shift;
  
  my $x1 = shift;
  
  my $min = min($r, $x1);
  my $max = max($r, $x1);
  
  return Rstats::Func::c_($r, $min, $max);
}

sub rbind {
  my $r = shift;
  my (@xs) = @_;
  
  return Rstats::Func::NULL($r) unless @xs;
  
  if (Rstats::Func::is_data_frame($r, $xs[0])) {
    
    # Check names
    my $first_names;
    for my $x (@xs) {
      if ($first_names) {
        my $names = Rstats::Func::names($r, $x)->values;
        my $different;
        $different = 1 if @$first_names != @$names;
        for (my $i = 0; $i < @$first_names; $i++) {
          $different = 1 if $names->[$i] ne $first_names->[$i];
        }
        Carp::croak "rbind require same names having data frame"
          if $different;
      }
      else {
        $first_names = Rstats::Func::names($r, $x)->values;
      }
    }
    
    # Create new vectors
    my @new_vectors;
    for my $name (@$first_names) {
      my @vectors;
      for my $x (@xs) {
        my $v = $x->getin($name);
        if (Rstats::Func::is_factor($r, $v)) {
          push @vectors, Rstats::Func::as_character($r, $v);
        }
        else {
          push @vectors, $v;
        }
      }
      my $new_vector = Rstats::Func::c_($r, @vectors);
      push @new_vectors, $new_vector;
    }
    
    # Create new data frame
    my @data_frame_args;
    for (my $i = 0; $i < @$first_names; $i++) {
      push @data_frame_args, $first_names->[$i], $new_vectors[$i];
    }
    my $data_frame = Rstats::Func::data_frame($r, @data_frame_args);
    
    return $data_frame;
  }
  else {
    my $matrix = cbind($r, @xs);
    
    return Rstats::Func::t($r, $matrix);
  }
}

sub rep {
  my $r = shift;
  
  my ($x1, $x_times) = args_array($r, ['x1', 'times'], @_);
  
  my $times = defined $x_times ? $x_times->value : 1;
  
  my $elements = [];
  push @$elements, @{Rstats::Func::decompose($r, $x1)} for 1 .. $times;
  my $x2 = Rstats::Func::c_($r, @$elements);
  
  return $x2;
}

sub replace {
  my $r = shift;
  
  my $x1 = to_object($r, shift);
  my $x2 = to_object($r, shift);
  my $x3 = to_object($r, shift);
  
  my $x1_elements = Rstats::Func::decompose($r, $x1);
  my $x2_elements = Rstats::Func::decompose($r, $x2);
  my $x2_elements_h = {};
  for my $x2_element (@$x2_elements) {
    my $x2_element_hash = Rstats::Func::to_string($r, $x2_element);
    
    $x2_elements_h->{$x2_element_hash}++;
    Carp::croak "replace second argument can't have duplicate number"
      if $x2_elements_h->{$x2_element_hash} > 1;
  }
  my $x3_elements = Rstats::Func::decompose($r, $x3);
  my $x3_length = @{$x3_elements};
  
  my $x4_elements = [];
  my $replace_count = 0;
  for (my $i = 0; $i < @$x1_elements; $i++) {
    my $hash = Rstats::Func::to_string($r, Rstats::Func::c_double($r, $i + 1));
    if ($x2_elements_h->{$hash}) {
      push @$x4_elements, $x3_elements->[$replace_count % $x3_length];
      $replace_count++;
    }
    else {
      push @$x4_elements, $x1_elements->[$i];
    }
  }
  
  return Rstats::Func::array($r, c_($r, @$x4_elements));
}

sub rev {
  my $r = shift;
  
  my $x1 = shift;
  
  # Reverse elements
  my @x2_elements = reverse @{Rstats::Func::decompose($r, $x1)};
  my $x2 = Rstats::Func::c_($r, @x2_elements);
  Rstats::Func::copy_attrs_to($r, $x1, $x2);
  
  return $x2;
}

sub rnorm {
  my $r = shift;
  
  # Option
  my $opt = ref $_[-1] eq 'HASH' ? pop @_ : {};
  
  # Count
  my ($count, $mean, $sd) = @_;
  Carp::croak "rnorm count should be bigger than 0"
    if $count < 1;
  
  # Mean
  $mean = 0 unless defined $mean;
  
  # Standard deviation
  $sd = 1 unless defined $sd;
  
  # Random numbers(standard deviation)
  my @x1_elements;
  
  my $pi = $r->pi->value;
  for (1 .. $count) {
    my ($rand1, $rand2) = (rand, rand);
    while ($rand1 == 0) { $rand1 = rand(); }
    
    my $rnorm = ($sd * CORE::sqrt(-2 * CORE::log($rand1))
      * CORE::sin(2 * $pi * $rand2))
      + $mean;
    
    push @x1_elements, $rnorm;
  }
  
  return Rstats::Func::c_($r, @x1_elements);
}

sub round {
  my $r = shift;
  
  my $opt = ref $_[-1] eq 'HASH' ? pop @_ : {};
  my ($_x1, $digits) = @_;
  $digits = $opt->{digits} unless defined $digits;
  $digits = 0 unless defined $digits;
  
  my $x1 = to_object($r, $_x1);

  my $ro = 10 ** $digits;
  my @x2_elements = map { Rstats::Func::c_double($r, Math::Round::round_even(Rstats::Func::value($r, $_) * $ro) / $ro) } @{Rstats::Func::decompose($r, $x1)};
  my $x2 = Rstats::Func::c_($r, @x2_elements);
  Rstats::Func::copy_attrs_to($r, $x1, $x2);
  Rstats::Func::mode($r, $x2, 'double');
  
  return $x2;
}

sub rowMeans {
  my $r = shift;
  
  my $x1 = shift;
  
  my $dim_values = Rstats::Func::dim($r, $x1)->values;
  if (@$dim_values == 2) {
    my $x1_values = [];
    for my $col (1 .. $dim_values->[1]) {
      my $x1_value = 0;
      $x1_value += $x1->value($_, $col) for (1 .. $dim_values->[0]);
      push @$x1_values, $x1_value / $dim_values->[0];
    }
    return Rstats::Func::c_($r, @$x1_values);
  }
  else {
    Carp::croak "Can't culculate rowMeans";
  }
}

sub rowSums {
  my $r = shift;
  
  my $x1 = shift;
  
  my $dim_values = Rstats::Func::dim($r, $x1)->values;
  if (@$dim_values == 2) {
    my $x1_values = [];
    for my $col (1 .. $dim_values->[1]) {
      my $x1_value = 0;
      $x1_value += $x1->value($_, $col) for (1 .. $dim_values->[0]);
      push @$x1_values, $x1_value;
    }
    return Rstats::Func::c_($r, @$x1_values);
  }
  else {
    Carp::croak "Can't culculate rowSums";
  }
}

# TODO: prob option
sub sample {
  my $r = shift;
  
  my $opt = ref $_[-1] eq 'HASH' ? pop @_ : {};
  
  my ($_x1, $length) = @_;
  my $x1 = to_object($r, $_x1);
  
  # Replace
  my $replace = $opt->{replace};
  
  my $x1_length = Rstats::Func::get_length($r, $x1);
  $length = $x1_length unless defined $length;
  
  Carp::croak "second argument element must be bigger than first argument elements count when you specify 'replace' option"
    if $length > $x1_length && !$replace;
  
  my @x2_elements;
  my $x1_elements = Rstats::Func::decompose($r, $x1);
  for my $i (0 .. $length - 1) {
    my $rand_num = int(rand @$x1_elements);
    my $rand_element = splice @$x1_elements, $rand_num, 1;
    push @x2_elements, $rand_element;
    push @$x1_elements, $rand_element if $replace;
  }
  
  return Rstats::Func::c_($r, @x2_elements);
}

sub sequence {
  my $r = shift;
  
  my $_x1 = shift;
  
  my $x1 = to_object($r, $_x1);
  my $x1_values = $x1->values;
  
  my @x2_values;
  for my $x1_value (@$x1_values) {
    push @x2_values, @{seq($r, 1, $x1_value)->values};
  }
  
  return Rstats::Func::c_($r, @x2_values);
}


sub tail {
  my $r = shift;
  
  my ($x1, $x_n) = Rstats::Func::args_array($r, ['x1', 'n'], @_);
  
  my $n = defined $x_n ? $x_n->value : 6;
  
  my $e1 = Rstats::Func::decompose($r, $x1);
  my $max = Rstats::Func::get_length($r, $x1) < $n ? Rstats::Func::get_length($r, $x1) : $n;
  my @e2;
  for (my $i = 0; $i < $max; $i++) {
    unshift @e2, $e1->[Rstats::Func::get_length($r, $x1) - ($i  + 1)];
  }
  
  my $x2 = Rstats::Func::c_($r, @e2);
  Rstats::Func::copy_attrs_to($r, $x1, $x2);
  
  return $x2;
}

sub trunc {
  my $r = shift;
  
  my ($_x1) = @_;
  
  my $x1 = to_object($r, $_x1);
  
  my @x2_elements
    = map { Rstats::Func::c_double($r, int Rstats::Func::value($r, $_)) } @{Rstats::Func::decompose($r, $x1)};

  my $x2 = Rstats::Func::c_($r, @x2_elements);
  Rstats::Func::copy_attrs_to($r, $x1, $x2);
  Rstats::Func::mode($r, $x2, 'double');
  
  return $x2;
}

sub unique {
  my $r = shift;
  
  my $x1 = to_object($r, shift);
  
  if (Rstats::Func::is_vector($r, $x1)) {
    my $x2_elements = [];
    my $elements_count = {};
    my $na_count;
    for my $x1_element (@{Rstats::Func::decompose($r, $x1)}) {
      if (Rstats::Func::is_na($r, $x1_element)) {
        unless ($na_count) {
          push @$x2_elements, $x1_element;
        }
        $na_count++;
      }
      else {
        my $str = Rstats::Func::to_string($r, $x1_element);
        unless ($elements_count->{$str}) {
          push @$x2_elements, $x1_element;
        }
        $elements_count->{$str}++;
      }
    }

    return Rstats::Func::c_($r, @$x2_elements);
  }
  else {
    return $x1;
  }
}

sub median {
  my $r = shift;
  
  my $x1 = to_object($r, shift);
  
  my $x2 = unique($r, $x1);
  my $x3 = Rstats::Func::sort($r, $x2);
  my $x3_length = Rstats::Func::get_length($r, $x3);
  
  if ($x3_length % 2 == 0) {
    my $middle = $x3_length / 2;
    my $x4 = $x3->get($middle);
    my $x5 = $x3->get($middle + 1);
    
    return ($x4 + $x5) / 2;
  }
  else {
    my $middle = int($x3_length / 2) + 1;
    return $x3->get($middle);
  }
}

sub quantile {
  my $r = shift;
  
  my $x1 = to_object($r, shift);
  
  my $x2 = Rstats::Func::unique($r, $x1);
  my $x3 = Rstats::Func::sort($r, $x2);
  my $x3_length = Rstats::Func::get_length($r, $x3);
  
  my $quantile_elements = [];
  
  # Min
  push @$quantile_elements , $x3->get(1);
  
  # 1st quoter
  if ($x3_length % 4 == 0) {
    my $first_quoter = $x3_length * (1 / 4);
    my $x4 = $x3->get($first_quoter);
    my $x5 = $x3->get($first_quoter + 1);
    
    push @$quantile_elements, ((($x4 + $x5) / 2) + $x5) / 2;
  }
  else {
    my $first_quoter = int($x3_length * (1 / 4)) + 1;
    push @$quantile_elements, $x3->get($first_quoter);
  }
  
  # middle
  if ($x3_length % 2 == 0) {
    my $middle = $x3_length / 2;
    my $x4 = $x3->get($middle);
    my $x5 = $x3->get($middle + 1);
    
    push @$quantile_elements, (($x4 + $x5) / 2);
  }
  else {
    my $middle = int($x3_length / 2) + 1;
    push @$quantile_elements, $x3->get($middle);
  }
  
  # 3rd quoter
  if ($x3_length % 4 == 0) {
    my $third_quoter = $x3_length * (3 / 4);
    my $x4 = $x3->get($third_quoter);
    my $x5 = $x3->get($third_quoter + 1);
    
    push @$quantile_elements, (($x4 + (($x4 + $x5) / 2)) / 2);
  }
  else {
    my $third_quoter = int($x3_length * (3 / 4)) + 1;
    push @$quantile_elements, $x3->get($third_quoter);
  }
  
  # Max
  push @$quantile_elements , $x3->get($x3_length);
  
  my $x4 = Rstats::Func::c_($r, @$quantile_elements);
  Rstats::Func::names($r, $x4, Rstats::Func::c_($r, qw/0%  25%  50%  75% 100%/));
  
  return $x4;
}

sub sd {
  my $r = shift;
  
  my $x1 = to_object($r, shift);
  
  my $sd = Rstats::Func::sqrt($r, var($r, $x1));
  
  return $sd;
}

sub var {
  my $r = shift;
  
  my $x1 = to_object($r, shift);
  
  my $var = sum($r, ($x1 - Rstats::Func::mean($r, $x1)) ** 2) / (Rstats::Func::get_length($r, $x1) - 1);
  
  return $var;
}

sub which {
  my $r = shift;
  
  my ($_x1, $cond_cb) = @_;
  
  my $x1 = to_object($r, $_x1);
  my $x1_values = $x1->values;
  my @x2_values;
  for (my $i = 0; $i < @$x1_values; $i++) {
    local $_ = $x1_values->[$i];
    if ($cond_cb->($x1_values->[$i])) {
      push @x2_values, $i + 1;
    }
  }
  
  return Rstats::Func::c_($r, @x2_values);
}

sub inner_product {
  my $r = shift;
  
  my ($x1, $x2) = @_;
  
  if (Rstats::Func::is_null($r, $x1) || Rstats::Func::is_null($r, $x2)) {
    Carp::croak "requires numeric/complex matrix/vector arguments";
  }
  
  # Convert to matrix
  $x1 = Rstats::Func::t($r, Rstats::Func::as_matrix($r, $x1))
    if Rstats::Func::is_vector($r, $x1);
  $x2 = Rstats::Func::as_matrix($r, $x2) if Rstats::Func::is_vector($r, $x2);
  
  # Calculate
  if (Rstats::Func::is_matrix($r, $x1) && Rstats::Func::is_matrix($r, $x2)) {
    
    Carp::croak "requires numeric/complex matrix/vector arguments"
      if Rstats::Func::get_length($r, $x1) == 0 || Rstats::Func::get_length($r, $x2) == 0;
    Carp::croak "Error in a x b : non-conformable arguments"
      unless Rstats::Func::dim($r, $x1)->values->[1] == Rstats::Func::dim($r, $x2)->values->[0];
    
    my $row_max = Rstats::Func::dim($r, $x1)->values->[0];
    my $col_max = Rstats::Func::dim($r, $x2)->values->[1];
    
    my $x3_elements = [];
    for (my $col = 1; $col <= $col_max; $col++) {
      for (my $row = 1; $row <= $row_max; $row++) {
        my $x1_part = Rstats::Func::get($r, $x1, $row);
        my $x2_part = Rstats::Func::get($r, $x2, Rstats::Func::NULL($r), $col);
        my $x3_part = sum($r, $x1 * $x2);
        push @$x3_elements, $x3_part;
      }
    }
    
    my $x3 = Rstats::Func::matrix($r, c_($r, @$x3_elements), $row_max, $col_max);
    
    return $x3;
  }
  else {
    Carp::croak "inner_product should be dim < 3."
  }
}

sub row {
  my $r = shift;
  
  my $x1 = shift;
  
  my $nrow = Rstats::Func::nrow($r, $x1)->value;
  my $ncol = Rstats::Func::ncol($r, $x1)->value;
  
  my @values = (1 .. $nrow) x $ncol;
  
  return Rstats::Func::array($r, Rstats::Func::c_($r, @values), Rstats::Func::c_($r, $nrow, $ncol));
}



sub ncol {
  my $r = shift;
  
  my $x1 = shift;
  
  if (Rstats::Func::is_data_frame($r, $x1)) {
    return Rstats::Func::c_($r, Rstats::Func::get_length($r, $x1));
  }
  elsif (Rstats::Func::is_list($r, $x1)) {
    return Rstats::Func::NULL($r);
  }
  else {
    return Rstats::Func::c_($r, Rstats::Func::dim($r, $x1)->values->[1]);
  }
}

sub seq {
  my $r = shift;
  
  # Option
  my $opt = ref $_[-1] eq 'HASH' ? pop @_ : {};
  
  # Along
  my $_along = $opt->{along};
  if (defined $_along) {
    my $along = to_object($r, $_along);
    my $length = Rstats::Func::get_length($r, $along);
    return seq($r, 1, $length);
  }
  else {
    my ($from, $to) = @_;
    
    # From
    $from = $opt->{from} unless defined $from;
    Carp::croak "seq function need from option" unless defined $from;
    
    # To
    $to = $opt->{to} unless defined $to;
    Carp::croak "seq function need to option" unless defined $to;

    # Length
    my $length = $opt->{length};
    
    # By
    my $by = $opt->{by};
    
    if (defined $length && defined $by) {
      Carp::croak "Can't use by option and length option as same time";
    }
    
    unless (defined $by) {
      if ($to >= $from) {
        $by = 1;
      }
      else {
        $by = -1;
      }
    }
    Carp::croak "by option should be except for 0" if $by == 0;
    
    $to = $from unless defined $to;
    
    if (defined $length && $from ne $to) {
      $by = ($to - $from) / ($length - 1);
    }
    
    my $elements = [];
    if ($to == $from) {
      $elements->[0] = $to;
    }
    elsif ($to > $from) {
      if ($by < 0) {
        Carp::croak "by option is invalid number(seq function)";
      }
      
      my $element = $from;
      while ($element <= $to) {
        push @$elements, $element;
        $element += $by;
      }
    }
    else {
      if ($by > 0) {
        Carp::croak "by option is invalid number(seq function)";
      }
      
      my $element = $from;
      while ($element >= $to) {
        push @$elements, $element;
        $element += $by;
      }
    }
    
    return Rstats::Func::c_($r, @$elements);
  }
}

sub numeric {
  my $r = shift;
  
  my $num = shift;
  
  return Rstats::Func::c_($r, (0) x $num);
}

sub _fix_pos {
  my $r = shift;
  
  my ($data1, $datx2, $reverse) = @_;
  
  my $x1;
  my $x2;
  if (ref $datx2) {
    $x1 = $data1;
    $x2 = $datx2;
  }
  else {
    if ($reverse) {
      $x1 = Rstats::Func::c_($r, $datx2);
      $x2 = $data1;
    }
    else {
      $x1 = $data1;
      $x2 = Rstats::Func::c_($r, $datx2);
    }
  }
  
  return ($x1, $x2);
}

sub bool {
  my $r = shift;
  
  my $x1 = shift;
  
  my $length = Rstats::Func::get_length($r, $x1);
  if ($length == 0) {
    Carp::croak 'Error in if (a) { : argument is of length zero';
  }
  elsif ($length > 1) {
    Carp::carp 'In if (a) { : the condition has length > 1 and only the first element will be used';
  }
  
  my $type = $x1->get_type;
  my $value = $x1->value;

  my $is;
  if ($type eq 'character' || $type eq 'complex') {
    Carp::croak 'Error in -a : invalid argument to unary operator ';
  }
  elsif ($type eq 'double') {
    if ($value eq 'Inf' || $value eq '-Inf') {
      $is = 1;
    }
    elsif ($value eq 'NaN') {
      Carp::croak 'argument is not interpretable as logical';
    }
    else {
      $is = $value;
    }
  }
  elsif ($type eq 'integer' || $type eq 'logical') {
    $is = $value;
  }
  else {
    Carp::croak "Invalid type";
  }
  
  if (!defined $value) {
    Carp::croak "Error in bool context (a) { : missing value where TRUE/FALSE needed"
  }

  return $is;
}

sub set {
  my ($r, $x1) = @_;
  
  if ($x1->{object_type} eq 'NULL' || $x1->{object_type} eq 'array' || $x1->{object_type} eq 'factor') {
    return Rstats::Func::set_array(@_);
  }
  elsif ($x1->{object_type} eq 'list') {
    return Rstats::Func::set_list(@_);
  }
  elsif ($x1->{object_type} eq 'data.frame') {
    return Rstats::Func::set_dataframe(@_);
  }
  else {
    croak "Error in set() : Not implemented";
  }
}



sub get_array {
  my $r = shift;
  
  my $x1 = shift;
  
  my $opt = ref $_[-1] eq 'HASH' ? pop @_ : {};
  my $dim_drop;
  my $level_drop;
  if (Rstats::Func::is_factor($r, $x1)) {
    $level_drop = $opt->{drop};
  }
  else {
    $dim_drop = $opt->{drop};
  }
  
  $dim_drop = 1 unless defined $dim_drop;
  $level_drop = 0 unless defined $level_drop;
  
  my @_indexs = @_;

  my $_indexs;
  if (@_indexs) {
    $_indexs = \@_indexs;
  }
  else {
    my $at = $x1->at;
    $_indexs = ref $at eq 'ARRAY' ? $at : [$at];
  }
  $x1->at($_indexs);
  
  my ($poss, $x2_dim, $new_indexes) = @{Rstats::Util::parse_index($r, $x1, $dim_drop, $_indexs)};
  
  my $x1_values = $x1->values;
  my @x2_values = map { $x1_values->[$_] } @$poss;
  
  # array
  my $x_matrix;
  if ($x1->get_type eq "character") {
    $x_matrix = c_character($r, \@x2_values);
  }
  elsif ($x1->get_type eq "complex") {
    $x_matrix = c_complex($r, \@x2_values);
  }
  elsif ($x1->get_type eq "double") {
    $x_matrix = c_double($r, \@x2_values);
  }
  elsif ($x1->get_type eq "integer") {
    $x_matrix = c_integer($r, \@x2_values);
  }
  elsif ($x1->get_type eq "logical") {
    $x_matrix = c_logical($r, \@x2_values);
  }
  else {
    croak("Invalid type " . $x1->get_type . " is passed");
  }
  
  my $x2 = Rstats::Func::array(
    $r,
    $x_matrix,
    Rstats::Func::c_($r, @$x2_dim)
  );
  
  # Copy attributes
  Rstats::Func::copy_attrs_to($r, $x1, $x2, {new_indexes => $new_indexes, exclude => ['dim']});

  # level drop
  if ($level_drop) {
    my $p = Rstats::Func::as_character($r, $x2);
    $x2 = Rstats::Func::factor($r, Rstats::Func::as_character($r, $x2));
  }
  
  return $x2;
}

sub getin_array { get(@_) }

sub to_string_array {
  my $r = shift;
  
  my $x1 = shift;
  
  my $is_factor = Rstats::Func::is_factor($r, $x1);
  my $is_ordered = Rstats::Func::is_ordered($r, $x1);
  my $levels;
  if ($is_factor) {
    $levels = Rstats::Func::levels($r, $x1)->values;
  }
  
  $x1 = Rstats::Func::as_character($r, $x1) if Rstats::Func::is_factor($r, $x1);
  
  my $is_character = Rstats::Func::is_character($r, $x1);

  my $values = $x1->values;
  my $type = $x1->get_type;
  
  my $dim_values = $x1->dim_as_array->values;
  
  my $dim_length = @$dim_values;
  my $dim_num = $dim_length - 1;
  my $poss = [];
  
  my $str;
  if (@$values) {
    if ($dim_length == 1) {
      my $names = Rstats::Func::names($r, $x1)->values;
      if (@$names) {
        $str .= join(' ', @$names) . "\n";
      }
      my @parts = map { Rstats::Func::_value_to_string($r, $x1, $_, $type, $is_factor) } @$values;
      $str .= '[1] ' . join(' ', @parts) . "\n";
    }
    elsif ($dim_length == 2) {
      $str .= '     ';
      
      my $colnames = Rstats::Func::colnames($r, $x1)->values;
      if (@$colnames) {
        $str .= join(' ', @$colnames) . "\n";
      }
      else {
        for my $d2 (1 .. $dim_values->[1]) {
          $str .= $d2 == $dim_values->[1] ? "[,$d2]\n" : "[,$d2] ";
        }
      }
      
      my $rownames = Rstats::Func::rownames($r, $x1)->values;
      my $use_rownames = @$rownames ? 1 : 0;
      for my $d1 (1 .. $dim_values->[0]) {
        if ($use_rownames) {
          my $rowname = $rownames->[$d1 - 1];
          $str .= "$rowname ";
        }
        else {
          $str .= "[$d1,] ";
        }
        
        my @parts;
        for my $d2 (1 .. $dim_values->[1]) {
          my $part = $x1->value($d1, $d2);
          push @parts, Rstats::Func::_value_to_string($r, $x1, $part, $type, $is_factor);
        }
        
        $str .= join(' ', @parts) . "\n";
      }
    }
    else {
      my $code;
      $code = sub {
        my (@dim_values) = @_;
        my $dim_value = pop @dim_values;
        
        for (my $i = 1; $i <= $dim_value; $i++) {
          $str .= (',' x $dim_num) . "$i" . "\n";
          unshift @$poss, $i;
          if (@dim_values > 2) {
            $dim_num--;
            $code->(@dim_values);
            $dim_num++;
          }
          else {
            $str .= '     ';
            
            my $l_dimnames = Rstats::Func::dimnames($r, $x1);
            my $dimnames;
            if (Rstats::Func::is_null($r, $l_dimnames)) {
              $dimnames = [];
            }
            else {
              my $x_dimnames = $l_dimnames->getin($i);
              $dimnames = defined $l_dimnames ? $l_dimnames->values : [];
            }
            
            if (@$dimnames) {
              $str .= join(' ', @$dimnames) . "\n";
            }
            else {
              for my $d2 (1 .. $dim_values[1]) {
                $str .= $d2 == $dim_values[1] ? "[,$d2]\n" : "[,$d2] ";
              }
            }

            for my $d1 (1 .. $dim_values[0]) {
              $str .= "[$d1,] ";
              
              my @parts;
              for my $d2 (1 .. $dim_values[1]) {
                my $part = $x1->value($d1, $d2, @$poss);
                push @parts, Rstats::Func::_value_to_string($r, $x1, $part, $type, $is_factor);
              }
              
              $str .= join(' ', @parts) . "\n";
            }
          }
          shift @$poss;
        }
      };
      $code->(@$dim_values);
    }

    if ($is_factor) {
      if ($is_ordered) {
        $str .= 'Levels: ' . join(' < ', @$levels) . "\n";
      }
      else {
        $str .= 'Levels: ' . join(' ', , @$levels) . "\n";
      }
    }
  }
  else {
    $str = 'NULL';
  }
  
  return $str;
}

sub _value_to_string {
  my $r = shift;
  
  my ($x1, $value, $type, $is_factor) = @_;
  
  my $string;
  if ($is_factor) {
    if (!defined $value) {
      $string = '<NA>';
    }
    else {
      $string = "$value";
    }
  }
  else {
    if (!defined $value) {
      $string = 'NA';
    }
    elsif ($type eq 'complex') {
      my $re = $value->{re} || 0;
      my $im = $value->{im} || 0;
      $string = "$re";
      $string .= $im >= 0 ? "+$im" : $im;
      $string .= 'i';
    }
    elsif ($type eq 'character') {
      $string = '"' . $value . '"';
    }
    elsif ($type eq 'logical') {
      $string = $value ? 'TRUE' : 'FALSE';
    }
    else {
      $string = "$value";
    }
  }
  
  return $string;
}

sub str {
  my $r = shift;
  
  my $x1 = shift;
  
  my @str;
  
  if (Rstats::Func::is_null($r, $x1)) {
    push @str, "NULL";
  }
  elsif (Rstats::Func::is_vector($r, $x1) || is_array($r, $x1)) {
    # Short type
    my $type = $x1->get_type;
    my $short_type;
    if ($type eq 'character') {
      $short_type = 'chr';
    }
    elsif ($type eq 'complex') {
      $short_type = 'cplx';
    }
    elsif ($type eq 'double') {
      $short_type = 'num';
    }
    elsif ($type eq 'integer') {
      $short_type = 'int';
    }
    elsif ($type eq 'logical') {
      $short_type = 'logi';
    }
    else {
      $short_type = 'Unkonown';
    }
    push @str, $short_type;
    
    # Dimention
    my @dim_str;
    my $length = Rstats::Func::get_length($r, $x1);
    if (exists $x1->{dim}) {
      my $dim_values = $x1->{dim}->values;
      for (my $i = 0; $i < $x1->{dim}->get_length; $i++) {
        my $d = $dim_values->[$i];
        my $d_str;
        if ($d == 1) {
          $d_str = "1";
        }
        else {
          $d_str = "1:$d";
        }
        
        if ($x1->{dim}->get_length == 1) {
          $d_str .= "(" . ($i + 1) . "d)";
        }
        push @dim_str, $d_str;
      }
    }
    else {
      if ($length != 1) {
        push @dim_str, "1:$length";
      }
    }
    if (@dim_str) {
      my $dim_str = join(', ', @dim_str);
      push @str, "[$dim_str]";
    }
    
    # Vector
    my @element_str;
    my $max_count = $length > 10 ? 10 : $length;
    my $is_character = is_character($r, $x1);
    my $values = $x1->values;
    for (my $i = 0; $i < $max_count; $i++) {
      push @element_str, Rstats::Func::_value_to_string($r, $x1, $values->[$i], $type);
    }
    if ($length > 10) {
      push @element_str, '...';
    }
    my $element_str = join(' ', @element_str);
    push @str, $element_str;
  }
  
  my $str = join(' ', @str);
  
  return $str;
}

sub at {
  my $r = shift;
  
  my $x1 = shift;
  
  if (@_) {
    $x1->{at} = [@_];
    
    return $x1;
  }
  
  return $x1->{at};
}

sub _name_to_index {
  my $r = shift;
  my $x1 = shift;
  my $x1_index = Rstats::Func::to_object($r, shift);
  
  my $e1_name = $x1_index->value;
  my $found;
  my $names = Rstats::Func::names($r, $x1)->values;
  my $index;
  for (my $i = 0; $i < @$names; $i++) {
    my $name = $names->[$i];
    if ($e1_name eq $name) {
      $index = $i + 1;
      $found = 1;
      last;
    }
  }
  croak "Not found $e1_name" unless $found;
  
  return $index;
}

sub nlevels {
  my $r = shift;
  
  my $x1 = shift;
  
  return Rstats::Func::c_($r, Rstats::Func::get_length($r, Rstats::Func::levels($r, $x1)));
}

sub getin_list {
  my ($r, $x1, $_index) = @_;
  
  unless (defined $_index) {
    $_index = $x1->at;
  }
  $x1->at($_index);
  
  my $x1_index = Rstats::Func::to_object($r, $_index);
  my $index;
  if (Rstats::Func::is_character($r, $x1_index)) {
    $index = Rstats::Func::_name_to_index($r, $x1, $x1_index);
  }
  else {
    $index = $x1_index->values->[0];
  }
  my $elements = $x1->list;
  my $element = $elements->[$index - 1];
  
  return $element;
}

sub get_list {
  my $r = shift;
  my $x1 = shift;
  my $x_index = Rstats::Func::to_object($r, shift);
  
  my $elements = $x1->list;
  
  my $class = ref $x1;
  my $list = Rstats::Func::list($r);;
  my $list_elements = $list->list;
  
  my $index_values;
  if (Rstats::Func::is_character($r, $x_index)) {
    $index_values = [];
    for my $value (@{$x_index->values}) {
      push @$index_values, Rstats::Func::_name_to_index($r, $x1, $value);
    }
  }
  else {
    $index_values = $x_index->values;
  }
  for my $i (@{$index_values}) {
    push @$list_elements, $elements->[$i - 1];
  }
  
  Rstats::Func::copy_attrs_to(
    $r, $x1, $list, {new_indexes => [Rstats::Func::c_($r, @$index_values)]}
  );

  return $list;
}

sub set_list {
  my $r = shift;
  my ($x1, $v1) = @_;
  
  my $_index = $x1->at;
  my $x1_index = Rstats::Func::to_object($r, @$_index);
  my $index;
  if (Rstats::Func::is_character($r, $x1_index)) {
    $index = Rstats::Func::_name_to_index($r, $x1, $x1_index);
  }
  else {
    $index = $x1_index->values->[0];
  }
  $v1 = Rstats::Func::to_object($r, $v1);
  
  if (Rstats::Func::is_null($r, $v1)) {
    splice @{$x1->list}, $index - 1, 1;
    if (exists $x1->{names}) {
      my $new_names_values = $x1->{names}->values;
      splice @$new_names_values, $index - 1, 1;
      $x1->{names} = Rstats::Func::c_character($r, @$new_names_values);
    }
    
    if (exists $x1->{dimnames}) {
      my $new_dimname_values = $x1->{dimnames}[1]->values;
      splice @$new_dimname_values, $index - 1, 1;
      $x1->{dimnames}[1] = Rstats::Func::c_character($r, @$new_dimname_values);
    }
  }
  else {
    if (Rstats::Func::is_data_frame($r, $x1)) {
      my $x1_length = $x1->get_length;
      my $v1_length = $v1->get_length;
      if ($x1_length != $v1_length) {
        croak "Error in data_frame set: replacement has $v1_length rows, data has $x1_length";
      }
    }
    
    $x1->list->[$index - 1] = $v1;
  }
  
  return $x1;
}

sub to_string_list {
  my $r = shift;
  my $x1 = shift;
  
  my $poses = [];
  my $str = '';
  _to_string_list($r, $x1, $poses, \$str);
  
  return $str;
}

sub _to_string_list {
  my ($r, $list, $poses, $str_ref) = @_;
  
  my $elements = $list->list;
  for (my $i = 0; $i < @$elements; $i++) {
    push @$poses, $i + 1;
    $$str_ref .= join('', map { "[[$_]]" } @$poses) . "\n";
    
    my $element = $elements->[$i];
    if ($element->{object_type} eq 'list') {
      _to_string_list($r, $element, $poses, $str_ref);
    }
    else {
      $$str_ref .= Rstats::Func::to_string($r, $element) . "\n";
    }
    pop @$poses;
  }
}

sub set_dataframe { Rstats::Func::set_list(@_) }

sub getin_dataframe { Rstats::Func::getin_list(@_) }

sub get_dataframe {
  my $r = shift;
  
  my $x1 = shift;
  my $_row_index = shift;
  my $_col_index = shift;
  
  # Fix column index and row index
  unless (defined $_col_index) {
    $_col_index = $_row_index;
    $_row_index = Rstats::Func::NULL($r);
  }
  my $row_index = Rstats::Func::to_object($r, $_row_index);
  my $col_index = Rstats::Func::to_object($r, $_col_index);
  
  # Convert name index to number index
  my $col_index_values;
  if (Rstats::Func::is_null($r, $col_index)) {
    $col_index_values = [1 .. Rstats::Func::names($r, $x1)->get_length];
  }
  elsif (Rstats::Func::is_character($r, $col_index)) {
    $col_index_values = [];
    for my $col_index_value (@{$col_index->values}) {
      push @$col_index_values, Rstats::Func::_name_to_index($r, $x1, $col_index_value);
    }
  }
  elsif (Rstats::Func::is_logical($r, $col_index)) {
    my $tmp_col_index_values = $col_index->values;
    for (my $i = 0; $i < @$tmp_col_index_values; $i++) {
      push @$col_index_values, $i + 1 if $tmp_col_index_values->[$i];
    }
  }
  else {
    my $col_index_values_tmp = $col_index->values;
    
    if ($col_index_values_tmp->[0] < 0) {
      my $delete_col_index_values_h = {};
      for my $index (@$col_index_values_tmp) {
        croak "Can't contain both plus and minus index" if $index > 0;
        $delete_col_index_values_h->{-$index} = 1;
      }
      
      $col_index_values = [];
      for (my $index = 1; $index <= Rstats::Func::names($r, $x1)->get_length; $index++) {
        push @$col_index_values, $index unless $delete_col_index_values_h->{$index};
      }
    }
    else {
      $col_index_values = $col_index_values_tmp;
    }
  }
  
  # Extract columns
  my $elements = $x1->list;
  my $new_elements = [];
  for my $i (@{$col_index_values}) {
    push @$new_elements, $elements->[$i - 1];
  }
  
  # Extract rows
  for my $new_element (@$new_elements) {
    $new_element = $new_element->get($row_index)
      unless Rstats::Func::is_null($r, $row_index);
  }
  
  # Create new data frame
  my $data_frame = Rstats::Func::new_data_frame($r);;
  $data_frame->list($new_elements);
  Rstats::Func::copy_attrs_to(
    $r,
    $x1,
    $data_frame,
    {new_indexes => [$row_index, Rstats::Func::c_($r, @$col_index_values)]}
  );
  $data_frame->{dimnames}[0] = Rstats::Func::c_character($r,
    1 .. Rstats::Func::getin_dataframe($r, $data_frame, 1)->get_length
  );
  
  return $data_frame;
}

sub to_string_dataframe {
  my $r = shift;
  
  my $x1 = shift;

  my $t = Text::UnicodeTable::Simple->new(border => 0, alignment => 'right');
  
  # Names
  my $column_names = Rstats::Func::names($r, $x1)->values;
  $t->set_header('', @$column_names);
  
  # columns
  my $columns = [];
  for (my $i = 1; $i <= @$column_names; $i++) {
    my $x = $x1->getin($i);
    $x = Rstats::Func::as_character($r, $x) if Rstats::Func::is_factor($r, $x);
    push @$columns, $x->values;
  }
  my $col_count = @{$columns};
  my $row_count = @{$columns->[0]};
  
  for (my $i = 0; $i < $row_count; $i++) {
    my @row;
    push @row, $i + 1;
    for (my $k = 0; $k < $col_count; $k++) {
      push @row, $columns->[$k][$i];
    }
    $t->add_row(@row);
  }
  
  return "$t";
}

sub sweep {
  my $r = shift;
  
  my ($x1, $x_margin, $x2, $x_func)
    = Rstats::Func::args_array($r, ['x1', 'margin', 'x2', 'FUN'], @_);
  
  my $x_margin_values = $x_margin->values;
  my $func = defined $x_func ? $x_func->value : '-';
  
  my $x2_dim_values = Rstats::Func::dim($r, $x2)->values;
  my $x1_dim_values = Rstats::Func::dim($r, $x1)->values;
  
  my $x1_length = Rstats::Func::get_length($r, $x1);
  
  my $x_result_elements = [];
  for (my $x1_pos = 0; $x1_pos < $x1_length; $x1_pos++) {
    my $x1_index = Rstats::Util::pos_to_index($x1_pos, $x1_dim_values);
    
    my $new_index = [];
    for my $x_margin_value (@$x_margin_values) {
      push @$new_index, $x1_index->[$x_margin_value - 1];
    }
    
    my $e1 = $x2->value(@{$new_index});
    push @$x_result_elements, $e1;
  }
  my $x3 = Rstats::Func::c_($r, @$x_result_elements);
  
  my $x4;
  if ($func eq '+') {
    $x4 = $x1 + $x3;
  }
  elsif ($func eq '-') {
    $x4 = $x1 - $x3;
  }
  elsif ($func eq '*') {
    $x4 = $x1 * $x3;
  }
  elsif ($func eq '/') {
    $x4 = $x1 / $x3;
  }
  elsif ($func eq '**') {
    $x4 = $x1 ** $x3;
  }
  elsif ($func eq '%') {
    $x4 = $x1 % $x3;
  }
  
  Rstats::Func::copy_attrs_to($r, $x1, $x4);
  
  return $x4;
}

sub set_seed {
  my ($r, $seed) = @_;
  
  $r->{seed} = $seed;
}

sub runif {
  my $r = shift;

  my ($x_count, $x_min, $x_max)
    =  Rstats::Func::args_array($r, ['count', 'min', 'max'], @_);
  
  my $count = $x_count->value;
  my $min = defined $x_min ? $x_min->value : 0;
  my $max = defined $x_max ? $x_max->value : 1;
  Carp::croak "runif third argument must be bigger than second argument"
    if $min > $max;
  
  my $diff = $max - $min;
  my @x1_elements;
  if (defined $r->{seed}) {
    srand $r->{seed};
  }
  
  for (1 .. $count) {
    my $rand = rand($diff) + $min;
    push @x1_elements, $rand;
  }
  
  $r->{seed} = undef;
  
  return Rstats::Func::c_($r, @x1_elements);
}

sub apply {
  my $r = shift;
  
  my $func_name = splice(@_, 2, 1);
  my $func = ref $func_name ? $func_name : $r->helpers->{$func_name};

  my ($x1, $x_margin)
    = Rstats::Func::args_array($r, ['x1', 'margin'], @_);

  my $dim_values = Rstats::Func::dim($r, $x1)->values;
  my $margin_values = $x_margin->values;
  my $new_dim_values = [];
  for my $i (@$margin_values) {
    push @$new_dim_values, $dim_values->[$i - 1];
  }
  
  my $x1_length = Rstats::Func::get_length($r, $x1);
  my $new_elements_array = [];
  for (my $i = 0; $i < $x1_length; $i++) {
    my $index = Rstats::Util::pos_to_index($i, $dim_values);
    my $e1 = $x1->value(@$index);
    my $new_index = [];
    for my $i (@$margin_values) {
      push @$new_index, $index->[$i - 1];
    }
    my $new_pos = Rstats::Util::index_to_pos($new_index, $new_dim_values);
    $new_elements_array->[$new_pos] ||= [];
    push @{$new_elements_array->[$new_pos]}, $e1;
  }
  
  my $new_elements = [];
  for my $element_array (@$new_elements_array) {
    push @$new_elements, $func->($r, Rstats::Func::c_($r, @$element_array));
  }

  my $x2 = Rstats::Func::c_($r, @$new_elements);
  Rstats::Func::copy_attrs_to($r, $x1, $x2);
  $x2->{dim} = Rstats::Func::c_integer($r, @$new_dim_values);
  
  if ($x2->{dim}->get_length == 1) {
    delete $x2->{dim};
  }
  
  return $x2;

}
  
sub mapply {
  my $r = shift;
  
  my $func_name = splice(@_, 0, 1);
  my $func = ref $func_name ? $func_name : $r->helpers->{$func_name};

  my @xs = @_;
  @xs = map { Rstats::Func::c_($r, $_) } @xs;
  
  # Fix length
  my @xs_length = map { Rstats::Func::get_length($r, $_) } @xs;
  my $max_length = List::Util::max @xs_length;
  for my $x (@xs) {
    if (Rstats::Func::get_length($r, $x) < $max_length) {
      $x = Rstats::Func::array($r, $x, $max_length);
    }
  }
  
  # Apply
  my $new_xs = [];
  for (my $i = 0; $i < $max_length; $i++) {
    my @args = map { $_->value($i + 1) } @xs;
    my $x = $func->($r, @args);
    push @$new_xs, $x;
  }
  
  if (@$new_xs == 1) {
    return $new_xs->[0];
  }
  else {
    return Rstats::Func::list($r, @$new_xs);
  }
}
  
sub tapply {
  my $r = shift;
  
  my $func_name = splice(@_, 2, 1);
  my $func = ref $func_name ? $func_name : $r->helpers->{$func_name};

  my ($x1, $x2)
    = Rstats::Func::args_array($r, ['x1', 'x2'], @_);
  
  my $new_values = [];
  my $x1_values = $x1->values;
  my $x2_values = $x2->values;
  
  # Group values
  for (my $i = 0; $i < Rstats::Func::get_length($r, $x1); $i++) {
    my $x1_value = $x1_values->[$i];
    my $index = $x2_values->[$i];
    $new_values->[$index] ||= [];
    push @{$new_values->[$index]}, $x1_value;
  }
  
  # Apply
  my $new_values2 = [];
  for (my $i = 1; $i < @$new_values; $i++) {
    my $x = $func->($r, Rstats::Func::c_($r, @{$new_values->[$i]}));
    push @$new_values2, $x;
  }
  
  my $x4_length = @$new_values2;
  my $x4 = Rstats::Func::array($r, Rstats::Func::c_($r, @$new_values2), $x4_length);
  Rstats::Func::names($r, $x4, Rstats::Func::levels($r, $x2));
  
  return $x4;
}

sub lapply {
  my $r = shift;
  
  my $func_name = splice(@_, 1, 1);
  my $func = ref $func_name ? $func_name : $r->helpers->{$func_name};

  my ($x1) = Rstats::Func::args_array($r, ['x1'], @_);
  
  my $new_elements = [];
  for my $element (@{$x1->list}) {
    push @$new_elements, $func->($r, $element);
  }
  
  my $x2 = Rstats::Func::list($r, @$new_elements);
  Rstats::Func::copy_attrs_to($r, $x1, $x2);
  
  return $x2;
}
  
sub sapply {
  my $r = shift;
  my $x1 = $r->lapply(@_);
  
  my $x2 = Rstats::Func::c_($r, @{$x1->list});
  
  return $x2;
}

sub to_string {
  my ($r, $x1) = @_;
  
  if ($x1->{object_type} eq 'NULL') {
    return "NULL";
  }
  elsif ($x1->{object_type} eq 'array' || $x1->{object_type} eq 'factor') {
    return Rstats::Func::to_string_array(@_);
  }
  elsif ($x1->{object_type} eq 'list') {
    return Rstats::Func::to_string_list(@_);
  }
  elsif ($x1->{object_type} eq 'data.frame') {
    return Rstats::Func::to_string_dataframe(@_);
  }
  else {
    my $class = ref $x1;
    croak "Error in to_string() : $class not implemented(Rstats::Func::to_string)";
  }
}

sub get {
  my ($r, $x1) = @_;
  
  if ($x1->{object_type} eq 'array' || $x1->{object_type} eq 'factor') {
    return Rstats::Func::get_array(@_);
  }
  elsif ($x1->{object_type} eq 'list') {
    return Rstats::Func::get_list(@_);
  }
  elsif ($x1->{object_type} eq 'data.frame') {
    return Rstats::Func::get_dataframe(@_);
  }
  else {
    croak "Error in get() : Not implemented";
  }
}

sub getin {
  my ($r, $x1) = @_;
  
  if ($x1->{object_type} eq 'array') {
    return Rstats::Func::getin_array(@_);
  }
  elsif ($x1->{object_type} eq 'list') {
    return Rstats::Func::getin_list(@_);
  }
  elsif ($x1->{object_type} eq 'data.frame') {
    return Rstats::Func::getin_dataframe(@_);
  }
  else {
    croak "Error in getin() : Not implemented";
  }
}

sub _levels_h {
  my $r = shift;
  
  my $x1 = shift;
  
  my $levels_h = {};
  my $levels = Rstats::Func::levels($r, $x1)->values;
  for (my $i = 1; $i <= @$levels; $i++) {
    $levels_h->{$levels->[$i - 1]} = Rstats::Func::c_integer($r, $i);
  }
  
  return $levels_h;
}

sub set_array {
  my $r = shift;
  
  my $x1 = shift;
  my $x2 = Rstats::Func::to_object($r, shift);
  
  my $at = $x1->at;
  my $_indexs = ref $at eq 'ARRAY' ? $at : [$at];
  my ($poss, $x2_dim) = @{Rstats::Util::parse_index($r, $x1, 0, $_indexs)};
  
  my $type;
  my $x1_elements;
  if (Rstats::Func::is_factor($r, $x1)) {
    $x1_elements = Rstats::Func::decompose($r, $x1);
    $x2 = Rstats::Func::as_character($r, $x2) unless Rstats::Func::is_character($r, $x2);
    my $x2_elements = Rstats::Func::decompose($r, $x2);
    my $levels_h = Rstats::Func::_levels_h($r, $x1);
    for (my $i = 0; $i < @$poss; $i++) {
      my $pos = $poss->[$i];
      my $element = $x2_elements->[(($i + 1) % @$poss) - 1];
      if (Rstats::Func::is_na($r, $element)) {
        $x1_elements->[$pos] = Rstats::Func::c_logical($r, undef);
      }
      else {
        my $value = Rstats::Func::value($r, $element);
        if ($levels_h->{$value}) {
          $x1_elements->[$pos] = $levels_h->{$value};
        }
        else {
          Carp::carp "invalid factor level, NA generated";
          $x1_elements->[$pos] = Rstats::Func::c_logical($r, undef);
        }
      }
    }
    $type = $x1->get_type;
  }
  else {
    # Upgrade mode if type is different
    if ($x1->get_type ne $x2->get_type) {
      my $x1_tmp;
      ($x1_tmp, $x2) = @{Rstats::Func::upgrade_type($r, [$x1, $x2])};
      Rstats::Func::copy_attrs_to($r, $x1_tmp, $x1);
      $x1->vector($x1_tmp->vector);
      
      $type = $x1_tmp->get_type;
    }
    else {
      $type = $x1->get_type;
    }

    $x1_elements = Rstats::Func::decompose($r, $x1);

    my $x2_elements = Rstats::Func::decompose($r, $x2);
    for (my $i = 0; $i < @$poss; $i++) {
      my $pos = $poss->[$i];
      $x1_elements->[$pos] = $x2_elements->[(($i + 1) % @$poss) - 1];
    }
  }
  
  $DB::single = 1;
  my $x1_tmp = Rstats::Func::compose($r, $type, $x1_elements);
  $x1->vector($x1_tmp->vector);
  $x1->{type} = $x1_tmp->{type};
  $x1->{object_type} = $x1_tmp->{object_type};
  
  return $x1;
}

sub sort {
  my $r = shift;
  
  my ($x1, $x_decreasing) = Rstats::Func::args_array($r, ['x1', 'decreasing', 'na.last'], @_);
  
  my $decreasing = defined $x_decreasing ? $x_decreasing->value : 0;
  
  my @x2_elements = grep { !Rstats::Func::is_na($r, $_) && !Rstats::Func::is_nan($r, $_) } @{Rstats::Func::decompose($r, $x1)};
  
  my $x3_elements = $decreasing
    ? [reverse sort { ($a > $b) ? 1 : ($a == $b) ? 0 : -1 } @x2_elements]
    : [sort { ($a > $b) ? 1 : ($a == $b) ? 0 : -1 } @x2_elements];

  return Rstats::Func::c_($r, @$x3_elements);
}

sub value {
  my $r = shift;
  my $x1 = shift;
  
  my $e1;
  my $dim_values = Rstats::Func::values($r, $x1->dim_as_array);
  my $x1_elements = Rstats::Func::decompose($r, $x1);
  if (@_) {
    if (@$dim_values == 1) {
      $e1 = $x1_elements->[$_[0] - 1];
    }
    elsif (@$dim_values == 2) {
      $e1 = $x1_elements->[($_[0] + $dim_values->[0] * ($_[1] - 1)) - 1];
    }
    else {
      $e1 = Rstats::Func::decompose($r, $x1->get(@_))->[0];
    }
    
  }
  else {
    $e1 = $x1_elements->[0];
  }
  
  return defined $e1 ? Rstats::Func::first_value($r, $e1) : undef;
}

1;

=head1 NAME

Rstats::Func - Functions

