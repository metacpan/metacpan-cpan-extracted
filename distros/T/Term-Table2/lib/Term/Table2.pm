package Term::Table2;

use v5.14;
use warnings FATAL => qw(all);

use List::Util       qw(max min);
use Module::Load     qw(load);
use Params::Validate qw(ARRAYREF CODEREF SCALAR validate);
use POSIX            qw(floor ceil);
use Term::ReadKey    qw(GetTerminalSize);

use Class::XSAccessor
  getters => {
    map { $_ => $_; }
        qw(
          broad_column
          broad_header
          broad_row
          collapse
          column_width
          current_row
          end_of_table
          header
          pad
          page_height
          rows
          separate_rows
          table_width
        )
  };

sub _override_length {                                      # Consider wide Unicode characters if possible i.e.
  no warnings qw(redefine once);                            # if Unicode::GCString can be used.
  use subs qw(length);                                      # Otherwise table content can be twisted
  eval {
    load('Unicode::GCString');                              # Try to load Unicode::GCString, then check if Perl was
    my $dummy = 1 / length(!$^D);                           # compiled without -DDEBUGGING
  };
  *length = $@ ? sub { return CORE::length($_[0]) } : sub { return Unicode::GCString->new($_[0])->columns() };
  return;
}

BEGIN { _override_length() }

use constant {                                              # Boolean values
  FALSE => 0,
  TRUE  => 1,
};
use constant {                                              # Table flags
  ADJUST  => 0,
  CUT     => 0,
  SPLIT   => 1,
  WRAP    => 2,
};
use constant {                                              # Integer that hopefully can never be exceeded
  BIG_INT => ~0,
};
use constant {                                              # Valid option combinations in form required by
  ALL_OPTIONS => {                                          # Params::Validate::validate
    header        => {
      default      => [],
      optional     => 1,
    },
    rows          => {
      default      => [],
      optional     => 1,
    },
    broad_column  => {
      default      => [WRAP],
      optional     => 1,
    },
    broad_header  => {
      default      => [WRAP],
      optional     => 1,
    },
    broad_row     => {
      default      => WRAP,
      optional     => 1,
    },
    collapse      => {
      default      => [FALSE],
      optional     => 1,
    },
    column_width  => {
      default      => [ADJUST],
      optional     => 1,
    },
    pad           => {
      default      => 1,
      optional     => 1,
    },
    page_height   => {
      default      => \&_screen_height,
      optional     => 1,
    },
    separate_rows => {
      default      => FALSE,
      optional     => 1,
    },
    table_width   => {
      default      => \&_screen_width,
      optional     => 1,
    },
  },
};
use constant {
  OPTIONS_ARRAY => {
    %{ALL_OPTIONS()},
    rows         => {
      type        => ARRAYREF,
      callbacks   => {
        q('rows' element is an array reference)                              => \&_is_each_row_array,
        q(all 'rows' elements have same length)                              => \&_are_all_rows_of_equal_length,
        q('rows' elements contain defined scalars only)                      => \&_is_each_cell_scalar,
      },
    },
    broad_row    => {
      type        => SCALAR,
      optional    => 1,
      callbacks   => { q('broad_row' is either 'CUT', or 'SPLIT', or 'WRAP') => \&_is_cut_or_split_or_wrap },
    },
    collapse     => {
      type        => ARRAYREF | SCALAR,
      optional    => 1,
    },
    column_width => {
      type        => ARRAYREF | SCALAR,
      optional    => 1,
      callbacks   => { q('column_width' is undefined or a positive integer)  => \&_is_each_column_width_undef_or_int },
    },
  },
  OPTIONS_CALLBACK => {
    %{ALL_OPTIONS()},
    broad_row   => {
      type        => SCALAR,
      optional    => 1,
      callbacks   => { q('broad_row' is either 'CUT' or 'WRAP') => \&_is_cut_or_wrap },
    },
    column_width => {
      type        => ARRAYREF | SCALAR,
      optional    => 1,
      callbacks   => { q('column_width' is a positive integer)  => \&_is_each_column_width_int },
    },
  },
  OPTIONS_GENERAL => {
    %{ALL_OPTIONS()},
    header        => {
      type         => ARRAYREF,
      optional     => 1,
      callbacks    => { q('header' element is a scalar)                        => \&_is_scalar },
    },
    broad_column  => {
      type         => ARRAYREF | SCALAR,
      optional     => 1,
      callbacks    => { q('broad_column' contains either 'CUT' or 'WRAP' only) => \&_is_each_column_flag_cut_or_wrap },
    },
    broad_header  => {
      type         => ARRAYREF | SCALAR,
      optional     => 1,
      callbacks    => { q('broad_header' contains either 'CUT' or 'WRAP' only) => \&_is_each_column_flag_cut_or_wrap },
    },
    column_width  => {
      type         => ARRAYREF | SCALAR,
      optional     => 1,
      callbacks    => { q('column_width' is a positive integer)                => \&_is_each_column_width_int },
    },
    pad           => {
      type         => ARRAYREF | SCALAR,
      optional     => 1,
      callbacks    => { q('pad' is undefined or a positive integer)            => \&_is_undef_or_int },
    },
    page_height   => {
      type         => SCALAR,
      optional     => 1,
      callbacks    => { q('page_height' is undefined or a positive integer)    => \&_is_undef_or_int },
    },
    separate_rows => {
      type         => SCALAR,
      optional     => 1,
    },
    table_width   => {
      type         => SCALAR,
      optional     => 1,
      callbacks    => { q('table_width' is undefined or a positive integer)    => \&_is_undef_or_int },
    },
  },
};

use Exporter qw(import);
our @EXPORT_OK = qw(ADJUST CUT SPLIT WRAP);

our $VERSION = '1.0.3';

sub fetch {                                                 # Provides current line
  my ($self) = @_;

  return if $self->{'end_of_table'} && !@{$self->{':row_lines'}};

  $self->_get_next_lines() unless @{$self->{':row_lines'}} && $self->{':line_on_page'};
  $self->{':line_on_page'}++;
  $self->{':line_on_page'} = 0 if $self->{':line_on_page'} == $self->{':lines_per_page'};

  my $row = shift(@{$self->{':row_lines'}});
  $self->{':row_buffer'} = [] unless @{$self->{':row_lines'}};

  return $_ = $row;
}

sub fetch_all {                                             # Provides all table lines at once
  my ($self) = @_;

  my @lines;
  push(@lines, $_) while $self->fetch();

  return \@lines;
}

sub new {                                                   # Instantiate table object
  my ($class, @params) = @_;

  my $self = bless(
    {
      ':end_of_chunk'      => FALSE,                        # End of vertical chunk in case of horizontal splitting
      ':header_lines'      => [],                           # One array element per header line
      ':line_format'       => '|',                          # Row line format
      ':line_on_page'      => 0,                            # Line number relative to the current page
      ':lines_per_page'    => 1,                            # Considers multiple lines per page depending on 'broad_row'
      ':lines_per_row'     => 1,                            # Considers multiple lines per row depending on 'broad_row'
      ':number_of_columns' => undef,                        # Number of columns as supplied via 'rows' array
      ':row_buffer'        => [],                           # Current row content
      ':row_lines'         => [],                           # One array element per row line
      ':separating_added'  => FALSE,                        # Separating line is among ':row_lines'
      ':separating_line'   => '+',                          # Line separating table / header content
      ':split_offset'      => 0,                            # Horizontal offset from the table left side
      ':total_width'       => 0,                            # Table width independently of possible horizontal splitting
      'current_row'        => 0,                            # Order No. of current row
      'end_of_table'       => FALSE,                        # End of table in general (end of last chunk)
    },
    $class,
  )->_validate(\@params);

  return ref($self->{'rows'}) eq 'ARRAY' ? $self->_set_defaults()->_init()
                                         : $self->_copy_options(OPTIONS_CALLBACK, \@params);
}

sub _are_all_rows_of_equal_length {                         # Checks if all rows have the same length as the 1st one
  my ($rows) = @_;

  return !grep { @$_ != @{$rows->[0]} } @$rows;
}

sub _copy_options {                                          # Takes over values of required options into object
  my ($self, $options, $params) = @_;

  my %params = @$params;

  $self //= {};
  foreach my $option (keys(%$options)) {
    $self->{$option} = $params{$option} if exists($params{$option});
  }

  return $self;
}

sub _cut_or_wrap_line {
  my ($self, $line) = @_;

  $line = substr($line, $self->{':split_offset'}) if $self->{':split_offset'};

  my $line_too_long = length($line) > $self->{'table_width'};
                                                            # Wrap is required and line is long enough to be wrapped
  return unpack('(A' . $self->{'table_width'} . ')*', $line) if $self->{'broad_row'} == WRAP && $line_too_long;
                                                            # Wrap is not required and line is too long
  return substr($line, 0, $self->{'table_width'}) if $line_too_long;

  return $line;                                             # Line is too short for any change
}

sub _extract_line {                                         # Extract 1st remaining line from current table row
  my ($self, $row, $broad_flags) = @_;

  my @line;

  foreach my $column_no (0 .. $self->{':number_of_columns'} - 1) {
    my $column_width = $self->{'column_width'}[$column_no];
    my $field        = $row->[$column_no];

    $row->[$column_no] = do {
      if (length($field) > $column_width) {
        push(@line, substr($field, 0, $column_width));
        $broad_flags->[$column_no] == CUT ? '' : substr($field, $column_width);
      }
      else {
        push(@line, $field);
        '';
      }
    };
  }

  return \@line;
}

sub _extract_lines {                                        # Converts table row to array of output cell arrays
  my ($self, $row, $broad_flags) = @_;

  my @row = @$row;

  my @lines;
  if (@row) {
    do {push(@lines, $self->_extract_line(\@row, $broad_flags))} while grep { $_ ne '' } @row;
  }

  return \@lines;
}

sub _get_next_lines {                                       # Provides next lines from the current row
  my ($self) = @_;

  if (!@{$self->{':row_lines'}} && @{$self->_get_next_row()}) {
    push(@{$self->{':row_lines'}},
         map { $self->_cut_or_wrap_line($_) } @{$self->_prepare_row($self->{':row_buffer'}, $self->{'broad_column'})});
    $self->{':separating_added'} = FALSE;
  }

  unshift(@{$self->{':row_lines'}}, map { $self->_cut_or_wrap_line($_) } @{$self->{':header_lines'}})
    if (ref($self->{'rows'}) eq 'ARRAY' && $self->{'current_row'} == 1 || !$self->{':line_on_page'})
    && !$self->{'end_of_table'};

  if (($self->{':end_of_chunk'}                             # Ends up the table or separates two rows if required
  ||   $self->{'separate_rows'} && $self->{':line_on_page'} + @{$self->{':row_lines'}} < $self->{'page_height'} - 1)
  && !$self->{':separating_added'}) {
    push(@{$self->{':row_lines'}}, $self->_cut_or_wrap_line($self->{':separating_line'}));
    $self->{':separating_added'} = TRUE;
  }

  return;
}

sub _get_next_row {                                         # Takes over next row
  my ($self) = @_;

  if ($self->{'end_of_table'}                               # End of table already reached or being reached just now
  ||  ref($self->{'rows'}) eq 'ARRAY' && !$self->_get_next_row_from_array()
  ||  ref($self->{'rows'}) eq 'CODE'  && !$self->_get_next_row_from_callback()) {
    $self->{':row_buffer'} = [];
  }
  else {
    $self->{'current_row'}++;
  }

  return $self->{':row_buffer'};
}

sub _get_next_row_from_array {                              # Takes over next row from array
  my ($self) = @_;

  my $current_row = $self->{'current_row'};

  $self->{':end_of_chunk'} = $current_row == $#{$self->{'rows'}};

  if ($current_row > $#{$self->{'rows'}}) {
    if ($self->{'broad_row'} != SPLIT || $self->{':split_offset'} + $self->{'table_width'} >= $self->{':total_width'}) {
      $self->{'end_of_table'} = TRUE;
      return FALSE;
    }

    $self->{'current_row'}    = $current_row = 0;
    $self->{':split_offset'} += $self->{'table_width'};
  }

  $self->{':row_buffer'}  = $self->{'rows'}[$current_row];
  $self->{'end_of_table'} = FALSE;

  return TRUE;
}

sub _get_next_row_from_callback {                           # Takes over next row delivered by callback function
  my ($self) = @_;

  my $row = &{$self->{'rows'}};

  unless (defined($self->{':number_of_columns'})) {
    $self->{':number_of_columns'} = ref($row) eq 'ARRAY' ? @$row : 0;
    die("Row $self->{'current_row'}: not an array reference") if ref($row) ne 'ARRAY';
    $self->_validate_for_callback()->_set_defaults()->_init();
  }

  unless (defined($row)) {
    $self->{':end_of_chunk'} = $self->{'end_of_table'} = TRUE;
    return FALSE;
  }

  my $number_of_columns = $self->{':number_of_columns'};

  die("Row $self->{'current_row'}: not an array reference") if ref($row) ne 'ARRAY';
  die("Row $self->{'current_row'}: wrong number of elements (", scalar(@$row), " instead of $number_of_columns)")
    if scalar(@$row) != $number_of_columns;
  foreach (0 .. $number_of_columns - 1) {
    die("Row $self->{'current_row'}: element No. $_ is ", ref($row->[$_]), ' not a scalar') if ref($row->[$_]);
  }

  $self->{':row_buffer'} = _strip_trailing_blanks($row);

  return TRUE;
}

sub _init {                                                 # Set remaining attributes during object instantiating
  my ($self) = @_;

  $self->{'page_height'} ||= BIG_INT;
  $self->{'table_width'} ||= BIG_INT;

  $self->{'pad'} = [($self->{'pad'}) x max(scalar(@{$self->{'column_width'}}), 1)] unless ref($self->{'pad'});

  die(
    "Table width ($self->{'table_width'}) is lower than the width of the narrowest possible column i.e. 1 character, ",
    'left-side column separator, and the lowest left-side padding (', min(@{$self->{'pad'}}), ')'
  ) if $self->{'table_width'} < 1 + 1 + min(@{$self->{'pad'}});

  $self->{'column_width'} = [map { $self->{'column_width'}[$_] == ADJUST ? $self->_max_column_width($_)
                                                                         : $self->{'column_width'}[$_] }
                             0 .. $#{$self->{'column_width'}}];

  $self->_set_line_format();
  $self->{':header_lines'} = $self->_prepare_row($self->{'header'}, $self->{'broad_header'});
  if (@{$self->{':header_lines'}}) {
    unshift(@{$self->{':header_lines'}}, $self->{':separating_line'});
    push   (@{$self->{':header_lines'}}, $self->{':separating_line'});
  }

  $self->{':lines_per_row'}  = $self->{'broad_row'} == WRAP
                             ? ceil(length($self->{':separating_line'}) / $self->{'table_width'})
                             : 1;
  my $header_height          = @{$self->{':header_lines'}} * $self->{':lines_per_row'};
  $self->{':lines_per_page'} = min(BIG_INT,
                                   $header_height
                                 + floor(($self->{'page_height'} - $header_height) / $self->{':lines_per_row'})
                                 * $self->{':lines_per_row'});

  if (@{$self->{':header_lines'}}) {                        # At least one row or one separating line under the header
    my $page_height = $header_height + $self->{':lines_per_row'};
    die("Page height ($self->{'page_height'}) is lower than the minimum possible page height ($page_height)")
      if $self->{'page_height'} < $page_height;
  }

  $self->{'current_row'} = 0;

  return $self;
}

sub _is_cut_or_split_or_wrap {                              # Check if each column flag is CUT, or SPLIT, or WRAP
  my ($flag) = @_;

  return FALSE unless _is_int($flag);                       # This split-up in 2 "returns" is only necessary due to
  return $flag == CUT || $flag == SPLIT || $flag == WRAP;   # a weakness of Devel::Cover
}

sub _is_cut_or_wrap {                                       # Check if flag is CUT or WRAP
  my ($flag) = @_;

  return FALSE unless _is_int($flag);                       # This split-up in 2 "returns" is only necessary due to
  return $flag == CUT || $flag == WRAP;                     # a weakness of Devel::Cover
}

sub _is_each_cell_scalar {                                  # Check if each cell in each row is a defined scalar
  my ($rows) = @_;

  return !grep { !_is_scalar($_) } @$rows;
}

sub _is_each_column_flag_cut_or_wrap {                      # Check if each column flag is CUT or WRAP
  my ($flag) = @_;

  return ref($flag) ? !grep { !_is_cut_or_wrap($_) } @$flag : _is_cut_or_wrap($flag);
}

sub _is_each_column_width_int {                             # Check if each column width is positive integer
  my ($width) = @_;

  return ref($width) ? !grep { !$_ || !_is_int($_) } @$width : $width && _is_int($width);
}

sub _is_each_column_width_undef_or_int {                    # Check if each column width is udefined or positive integer
  my ($width) = @_;

  return ref($width) ? !grep { !_is_undef_or_int($_) } @$width : _is_undef_or_int($width);
}

sub _is_each_row_array {                                    # Check if each row is an array
  my ($rows) = @_;

  return !grep { ref ne 'ARRAY' } @$rows;
}

sub _is_int {                                               # Check if defined value is an integer
  my ($value) = @_;

  return !ref($value) && $value =~ /^\d+$/;
}

sub _is_scalar {                                            # Check if each cell in a row is a defined scalar
  my ($value) = @_;

  return !grep { !defined || ref } @$value;
}

sub _is_undef_or_int {                                      # Check if value is defined or an integer
  my ($value) = @_;

  return !defined($value) || _is_int($value);
}

sub _max_column_width {                                     # Estimates maximum length of text in column
  my ($self, $column_no) = @_;

  my $width = @{$self->{'header'}} ? length($self->{'header'}[$column_no]) : 0;

  return max($width, map { length($_->[$column_no]) } @{$self->{'rows'}});
}

sub _prepare_row {                                          # Converts table row to array of output strings
  my ($self, $row, $broad_flags) = @_;
                                                            # Ignore possible redundant columns in header
  @$row = @$row[0 .. $self->{':number_of_columns'} - 1] if $#$row >= $self->{':number_of_columns'};

  return [map { sprintf($self->{':line_format'}, @$_) } @{$self->_extract_lines($row, $broad_flags)}];
}

sub _screen_height { return (GetTerminalSize())[1] }

sub _screen_width  { return (GetTerminalSize())[0] }

sub _set_defaults {                                         # Set default attributes if they are omitted
  my ($self) = @_;

  for my $option (keys(%{ALL_OPTIONS()})) {
    if (ref(ALL_OPTIONS->{$option}{'default'}) eq 'ARRAY') {
      my $default = defined($self->{$option}) && !ref($self->{$option}) ? $self->{$option}
                                                                        : ALL_OPTIONS->{$option}{'default'}[0];
      $self->{$option}       = [] unless ref($self->{$option});
      next if $option eq 'header' || $option eq 'rows';
      $self->{$option}[$_] //= $default foreach 0 .. $self->{':number_of_columns'} - 1;
    }
    else {
      my $default = ALL_OPTIONS->{$option}{'default'};
      $self->{$option} = ref($default) eq 'CODE' ? &$default() : $default unless defined($self->{$option});
    }
  }

  return $self;
}

sub _set_line_format {
  my ($self) = @_;

  my $table_width = 1;

  foreach my $column_no (0 .. $self->{':number_of_columns'} - 1) {
    my $column_width = $self->{'column_width'}[$column_no];
    if ($self->{'collapse'}[$column_no] && !$column_width) {
      $self->{':line_format'} .= '%s';
    }
    else {
      my $pad = $self->{'pad'}[$column_no];
      $self->{':line_format'}     .= ' ' x  $pad . '%-' . $column_width . 's' . ' ' x $pad  . '|';
      $self->{':separating_line'} .= '-' x ($pad +        $column_width +             $pad) . '+';
      $table_width                +=        $pad +        $column_width +             $pad  + 1;
    }

    last if $self->{'broad_row'} == CUT && $table_width >= $self->{'table_width'};
  }

  $self->{':total_width'} = $table_width;
  $self->{'current_row'}  = 0 if $table_width == 1;         # This table has no content

  return $self;
}

sub _strip_trailing_blanks {                                # Strips down trailing blanks from all cell values in row
  my ($row) = @_;

  return [map { s/\s+$//r } @$row];
}

sub _validate {
  my ($self, $params) = @_;

  validate(@$params, {%{ALL_OPTIONS()}, rows => {'optional' => TRUE, 'type' => ARRAYREF | CODEREF}});

  my %params      = @$params;
  $self->{'rows'} = $params{'rows'} // [];
  return ref($params{'rows'}) eq 'ARRAY' ? $self->_validate_for_array([%{_copy_options(undef, OPTIONS_ARRAY, $params)}])
                                         : $self;
}

sub _validate_for_array {
  my ($self, $params) = @_;

  $self->{'rows'}               = [map { _strip_trailing_blanks($_) } @{$self->{'rows'}}];
  $self->{':number_of_columns'} = @{$self->{'rows'}} ? @{$self->{'rows'}[0]} : 0;

  validate(@$params, OPTIONS_ARRAY);

  return $self->_copy_options(OPTIONS_ARRAY, $params)->_validate_general($params);
}

sub _validate_for_callback {
  my ($self, $params) = @_;

  validate(@$params, OPTIONS_CALLBACK);

  return $self->_copy_options(OPTIONS_CALLBACK, $params)->_validate_general($params);
}

sub _validate_general {
  my ($self, $params) = @_;

  validate(@$params, OPTIONS_GENERAL);

  my %params = @$params;
  die("The 'header' parameter contains less elements than an element of the 'rows' parameter")
    if exists($params{'header'}) && exists($params{'rows'}) && @{$params{'header'}} < $self->{':number_of_columns'};

  return $self->_copy_options(OPTIONS_GENERAL, $params);
}

1;