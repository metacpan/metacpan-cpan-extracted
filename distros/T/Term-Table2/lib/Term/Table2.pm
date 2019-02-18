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

sub _overrideLength {                                       # Consider wide Unicode characters if possible i.e.
  no warnings qw(redefine once);                            # if Unicode::GCString can be used.
  use subs qw(length);
  eval { load('Unicode::GCString') };                       # Otherwise table content can be twisted
  *length = $@ ? sub { return CORE::length($_[0]) } : sub { return Unicode::GCString->new($_[0])->columns() };
  return;
}

BEGIN { _overrideLength() }

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
      default      => \&_screenHeight,
      optional     => 1,
    },
    separate_rows => {
      default      => FALSE,
      optional     => 1,
    },
    table_width   => {
      default      => \&_screenWidth,
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
        q('rows' element is an array reference)                                    => \&_isEachRowArray,
        q(all 'rows' elements have same length)                                    => \&_areAllRowsOfEqualLength,
        q('rows' elements contain defined scalars only)                            => \&_isEachCellScalar,
      },
    },
    broad_row    => {
      type        => SCALAR,
      optional    => 1,
      callbacks   => { q('broad_row' is either 'CUT', or 'SPLIT', or 'WRAP')       => \&_isCutOrSplitOrWrap },
    },
    collapse     => {
      type        => ARRAYREF | SCALAR,
      optional    => 1,
    },
    column_width => {
      type        => ARRAYREF | SCALAR,
      optional    => 1,
      callbacks   => { q('column_width' is undefined or a positive integer)        => \&_isEachColumnWidthUndefOrInt },
    },
  },
  OPTIONS_CALLBACK => {
    %{ALL_OPTIONS()},
    broad_row   => {
      type        => SCALAR,
      optional    => 1,
      callbacks   => { q('broad_row' is either 'CUT' or 'WRAP')                    => \&_isCutOrWrap },
    },
    column_width => {
      type        => ARRAYREF | SCALAR,
      optional    => 1,
      callbacks   => { q('column_width' is a positive integer)                     => \&_isEachColumnWidthInt },
    },
  },
  OPTIONS_GENERAL => {
    %{ALL_OPTIONS()},
    header        => {
      type         => ARRAYREF,
      optional     => 1,
      callbacks    => { q('header' element is a scalar)                             => \&_isScalar },
    },
    broad_column  => {
      type         => ARRAYREF | SCALAR,
      optional     => 1,
      callbacks    => { q('broad_column' is / contains either 'CUT' or 'WRAP' only) => \&_isEachColumnFlagCutOrWrap },
    },
    broad_header  => {
      type         => ARRAYREF | SCALAR,
      optional     => 1,
      callbacks    => { q('broad_header' is / contains either 'CUT' or 'WRAP' only) => \&_isEachColumnFlagCutOrWrap },
    },
    column_width  => {
      type         => ARRAYREF | SCALAR,
      optional     => 1,
      callbacks    => { q('column_width' is a positive integer)                     => \&_isEachColumnWidthInt },
    },
    pad           => {
      type         => ARRAYREF | SCALAR,
      optional     => 1,
      callbacks    => { q('pad' is undefined or a positive integer)                 => \&_isUndefOrInt },
    },
    page_height   => {
      type         => SCALAR,
      optional     => 1,
      callbacks    => { q('page_height' is undefined or a positive integer)         => \&_isUndefOrInt },
    },
    separate_rows => {
      type         => SCALAR,
      optional     => 1,
    },
    table_width   => {
      type         => SCALAR,
      optional     => 1,
      callbacks    => { q('table_width' is undefined or a positive integer)         => \&_isUndefOrInt },
    },
  },
};

use Exporter qw(import);
our @EXPORT_OK = qw(ADJUST CUT SPLIT WRAP);

our $VERSION = '1.0.1';

sub fetch {                                                 # Provides current line
  my ($self) = @_;

  return if $self->{'end_of_table'} && !@{$self->{':rowLines'}};

  $self->_getNextLines() unless @{$self->{':rowLines'}} && $self->{':lineOnPage'};
  $self->{':lineOnPage'}++;
  $self->{':lineOnPage'} = 0 if $self->{':lineOnPage'} == $self->{':linesPerPage'};

  my $row = shift(@{$self->{':rowLines'}});
  $self->{':rowBuffer'} = [] unless @{$self->{':rowLines'}};

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
      ':endOfChunk'      => FALSE,                          # End of vertical chunk in case of horizontal splitting
      ':headerLines'     => [],                             # One array element per header line
      ':lineFormat'      => '|',                            # Row line format
      ':lineOnPage'      => 0,                              # Line number relative to the current page
      ':linesPerPage'    => 1,                              # Considers multiple lines per page depending on 'broad_row'
      ':linesPerRow'     => 1,                              # Considers multiple lines per row depending on 'broad_row'
      ':numberOfColumns' => undef,                          # Number of columns as supplied via 'rows' array
      ':rowBuffer'       => [],                             # Current row content
      ':rowLines'        => [],                             # One array element per row line
      ':separatingAdded' => FALSE,                          # Separating line is among ':rowLines'
      ':separatingLine'  => '+',                            # Line separating table / header content
      ':splitOffset'     => 0,                              # Horizontal offset from the table left side
      ':totalWidth'      => 0,                              # Table width independently of possible horizontal splitting
      'current_row'      => 0,                              # Order No. of current row
      'end_of_table'     => FALSE,                          # End of table in general (end of last chunk)
    },
    $class,
  )->_validate(\@params);

  return ref($self->{'rows'}) eq 'ARRAY' ? $self->_setDefaults()->_init()
                                         : $self->_copyOptions(OPTIONS_CALLBACK, \@params);
}

sub _areAllRowsOfEqualLength {
  my ($rows) = @_;

  return !grep { @$_ != @{$rows->[0]} } @$rows;
}

sub _copyOptions {                                          # Takes over values of required options into object
  my ($self, $options, $params) = @_;

  my %params = @$params;

  $self //= {};
  foreach my $option (keys(%$options)) {
    $self->{$option} = $params{$option} if exists($params{$option});
  }

  return $self;
}

sub _cutOrWrapLine {
  my ($self, $line) = @_;

  $line = substr($line, $self->{':splitOffset'}) if $self->{':splitOffset'};

  my $lineTooLong = length($line) > $self->{'table_width'};
                                                            # Wrap is required and line is long enough to be wrapped
  return unpack('(A' . $self->{'table_width'} . ')*', $line) if $self->{'broad_row'} == WRAP && $lineTooLong;

  return substr($line, 0, $self->{'table_width'})           # Wrap is not required and line is too long
    if $lineTooLong;

  return $line;                                             # Line is too short for any change
}

sub _extractLine {                                          # Extract 1st remaining line from current table row
  my ($self, $row, $broadFlags) = @_;

  my @line;

  foreach my $columnNo (0 .. $self->{':numberOfColumns'} - 1) {
    my $column_width  = $self->{'column_width'}[$columnNo];
    my $field         = $row->[$columnNo];

    $row->[$columnNo] = do {
      if (length($field) > $column_width) {
        push(@line, substr($field, 0, $column_width));
        $broadFlags->[$columnNo] == CUT ? '' : substr($field, $column_width);
      }
      else {
        push(@line, $field);
        '';
      }
    };
  }

  return \@line;
}

sub _extractLines {                                         # Converts table row to array of output cell arrays
  my ($self, $row, $broadFlags) = @_;

  my @row = @$row;

  my @lines;
  if (@row) {
    do {push(@lines, $self->_extractLine(\@row, $broadFlags))} while grep { $_ ne '' } @row;
  }

  return \@lines;
}

sub _getNextLines {                                         # Provides next lines from the current row
  my ($self) = @_;

  if (!@{$self->{':rowLines'}} && @{$self->_getNextRow()}) {
    push(@{$self->{':rowLines'}},
         map { $self->_cutOrWrapLine($_) } @{$self->_prepareRow($self->{':rowBuffer'}, $self->{'broad_column'})});
    $self->{':separatingAdded'} = FALSE;
  }

  my $headerAdded;
  if ((ref($self->{'rows'}) eq 'ARRAY' && $self->{'current_row'} == 1 || !$self->{':lineOnPage'})
  &&  !$self->{'end_of_table'}) {
    unshift(@{$self->{':rowLines'}}, map { $self->_cutOrWrapLine($_) } @{$self->{':headerLines'}});
    $headerAdded = TRUE;
  }

  if (($self->{':endOfChunk'}                               # Ends up the table or separates two rows if required
  ||   $self->{'separate_rows'} && $self->{':lineOnPage'} + @{$self->{':rowLines'}} < $self->{'page_height'} - 1)
  && !$self->{':separatingAdded'}) {
    push(@{$self->{':rowLines'}}, $self->_cutOrWrapLine($self->{':separatingLine'}));
    $self->{':separatingAdded'} = TRUE;
  }

  return;
}

sub _getNextRow {                                           # Takes over next row
  my ($self) = @_;

  if ($self->{'end_of_table'}                               # End of table already reached or being reached just now
  ||  ref($self->{'rows'}) eq 'ARRAY' && !$self->_getNextRowFromArray()
  ||  ref($self->{'rows'}) eq 'CODE'  && !$self->_getNextRowFromCallback()) {
    $self->{':rowBuffer'} = [];
  }
  else {
    $self->{'current_row'}++;
  }

  return $self->{':rowBuffer'};
}

sub _getNextRowFromArray {                                  # Takes over next row from array
  my ($self) = @_;

  my $current_row = $self->{'current_row'};

  $self->{':endOfChunk'} = $current_row == $#{$self->{'rows'}};

  if ($current_row > $#{$self->{'rows'}}) {
    if ($self->{'broad_row'} != SPLIT || $self->{':splitOffset'} + $self->{'table_width'} >= $self->{':totalWidth'}) {
      $self->{'end_of_table'} = TRUE;
      return FALSE;
    }

    $self->{'current_row'}   = $current_row = 0;
    $self->{':splitOffset'} += $self->{'table_width'};
  }

  $self->{':rowBuffer'} = $self->{'rows'}[$current_row];
  $self->{'end_of_table'} = FALSE;

  return TRUE;
}

sub _getNextRowFromCallback {                               # Takes over next row delivered by callback function
  my ($self) = @_;

  my $row = &{$self->{'rows'}};

  unless (defined($self->{':numberOfColumns'})) {
    $self->{':numberOfColumns'} = ref($row) eq 'ARRAY' ? @$row : 0;
    die("Row $self->{'current_row'}: not an array reference") if ref($row) ne 'ARRAY';
    $self->_validateForCallback()->_setDefaults()->_init();
  }

  unless (defined($row)) {
    $self->{':endOfChunk'} = $self->{'end_of_table'} = TRUE;
    return FALSE;
  }

  my $numberOfColumns = $self->{':numberOfColumns'};

  die("Row $self->{'current_row'}: not an array reference") if ref($row) ne 'ARRAY';
  die("Row $self->{'current_row'}: wrong number of elements (", scalar(@$row), " instead of $numberOfColumns)")
    if scalar(@$row) != $numberOfColumns;
  foreach (0 .. $numberOfColumns - 1) {
    die("Row $self->{'current_row'}: element No. $_ is ", ref($row->[$_]), ' not a scalar') if ref($row->[$_]);
  }

  $self->{':rowBuffer'} = _stripTrailingBlanks($row);

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

  $self->{'column_width'} = [map { $self->{'column_width'}[$_] == ADJUST ? $self->_maxColumnWidth($_)
                                                                         : $self->{'column_width'}[$_] }
                            0 .. $#{$self->{'column_width'}}];

  $self->_setLineFormat();
  $self->{':headerLines'} = $self->_prepareRow($self->{'header'}, $self->{'broad_header'});
  if (@{$self->{':headerLines'}}) {
    unshift(@{$self->{':headerLines'}}, $self->{':separatingLine'});
    push   (@{$self->{':headerLines'}}, $self->{':separatingLine'});
  }

  $self->{':linesPerRow'}  = $self->{'broad_row'} == WRAP
                           ? ceil(length($self->{':separatingLine'}) / $self->{'table_width'})
                           : 1;
  my $headerHeight         = @{$self->{':headerLines'}} * $self->{':linesPerRow'};
  $self->{':linesPerPage'} = $headerHeight
                           + floor(($self->{'page_height'} - $headerHeight) / $self->{':linesPerRow'})
                           * $self->{':linesPerRow'};

  if (@{$self->{':headerLines'}}) {                         # At least one row or one separating line under the header
    my $page_height = $headerHeight + $self->{':linesPerRow'};
    die("Page height ($self->{'page_height'}) is lower than the minimum possible page height ($page_height)")
      if $self->{'page_height'} < $page_height;
  }

  $self->{'current_row'} = 0;

  return $self;
}

sub _isCutOrSplitOrWrap {                                   # Check if each column flag is CUT, or SPLIT, or WRAP
  my ($flag) = @_;

  return FALSE unless _isInt($flag);                        # This split-up in 2 "returns" is only necessary due to
  return $flag == CUT || $flag == SPLIT || $flag == WRAP;   # a weakness of Devel::Cover
}

sub _isCutOrWrap {                                          # Check if flag is CUT or WRAP
  my ($flag) = @_;

  return FALSE unless _isInt($flag);                        # This split-up in 2 "returns" is only necessary due to
  return $flag == CUT || $flag == WRAP;                     # a weakness of Devel::Cover
}

sub _isEachCellScalar {                                     # Check if each cell in each row is a defined scalar
  my ($rows) = @_;

  return !grep { !_isScalar($_) } @$rows;
}

sub _isEachColumnFlagCutOrWrap {                            # Check if each column flag is CUT or WRAP
  my ($flag) = @_;

  return ref($flag) ? !grep { !_isCutOrWrap($_) } @$flag : _isCutOrWrap($flag);
}

sub _isEachColumnWidthInt {                                 # Check if each column width is positive integer
  my ($width) = @_;

  return ref($width) ? !grep { !$_ || !_isInt($_) } @$width : $width && _isInt($width);
}

sub _isEachColumnWidthUndefOrInt {                          # Check if each column width is udefined or positive integer
  my ($width) = @_;

  return ref($width) ? !grep { !_isUndefOrInt($_) } @$width : _isUndefOrInt($width);
}

sub _isEachRowArray {                                       # Check if each row is an array
  my ($rows) = @_;

  return !grep { ref ne 'ARRAY' } @$rows;
}

sub _isInt {                                                # Check if defined value is an integer
  my ($value) = @_;

  return !ref($value) && $value =~ /^\d+$/;
}

sub _isScalar {                                             # Check if each cell in a row is a defined scalar
  my ($value) = @_;

  return !grep { !defined || ref } @$value;
}

sub _isUndefOrInt {                                         # Check if value is defined or an integer
  my ($value) = @_;

  return !defined($value) || _isInt($value);
}

sub _maxColumnWidth {                                       # Estimates maximum length of text in column
  my ($self, $columnNo) = @_;

  my $width = @{$self->{'header'}} ? length($self->{'header'}[$columnNo]) : 0;

  return max($width, map { length($_->[$columnNo]) } @{$self->{'rows'}});
}

sub _prepareRow {                                           # Converts table row to array of output strings
  my ($self, $row, $broadFlags) = @_;
                                                            # Ignore possible redundant columns in header
  @$row = @$row[0 .. $self->{':numberOfColumns'} - 1] if $#$row >= $self->{':numberOfColumns'};

  return [map { sprintf($self->{':lineFormat'}, @$_) } @{$self->_extractLines($row, $broadFlags)}];
}

sub _screenHeight { return (GetTerminalSize())[1] }

sub _screenWidth  { return (GetTerminalSize())[0] }

sub _setDefaults {                                          # Set default attributes if they are omitted
  my ($self) = @_;

  for my $option (keys(%{ALL_OPTIONS()})) {
    if (ref(ALL_OPTIONS->{$option}{'default'}) eq 'ARRAY') {
      my $default = defined($self->{$option}) && !ref($self->{$option}) ? $self->{$option}
                                                                        : ALL_OPTIONS->{$option}{'default'}[0];
      $self->{$option}       = [] unless ref($self->{$option});
      next if $option eq 'header' || $option eq 'rows';
      $self->{$option}[$_] //= $default foreach 0 .. $self->{':numberOfColumns'} - 1;
    }
    else {
      my $default = ALL_OPTIONS->{$option}{'default'};
      $self->{$option} = ref($default) eq 'CODE' ? &$default() : $default unless defined($self->{$option});
    }
  }

  return $self;
}

sub _setLineFormat {
  my ($self) = @_;

  my $table_width = 1;

  foreach my $columnNo (0 .. $self->{':numberOfColumns'} - 1) {
    my $column_width = $self->{'column_width'}[$columnNo];
    if ($self->{'collapse'}[$columnNo] && !$column_width) {
      $self->{':lineFormat'} .= '%s';
    }
    else {
      my $pad = $self->{'pad'}[$columnNo];
      $self->{':lineFormat'}     .= ' ' x  $pad . '%-' . $column_width . 's' . ' ' x $pad  . '|';
      $self->{':separatingLine'} .= '-' x ($pad +        $column_width +             $pad) . '+';
      $table_width               +=        $pad +        $column_width +             $pad  + 1;
    }

    last if $self->{'broad_row'} == CUT && $table_width >= $self->{'table_width'};
  }

  $self->{':totalWidth'} = $table_width;
  $self->{'current_row'} = 0 if $table_width == 1;          # This table has no content

  return $self;
}

sub _stripTrailingBlanks {                                  # Strips down trailing blanks from all cell values in row
  my ($row) = @_;

  return [map { s/\s+$//r } @$row];
}

sub _validate {
  my ($self, $params) = @_;

  validate(@$params, {%{ALL_OPTIONS()}, rows => {'optional' => TRUE, 'type' => ARRAYREF | CODEREF}});

  my %params      = @$params;
  $self->{'rows'} = $params{'rows'} // [];
  return ref($params{'rows'}) eq 'ARRAY' ? $self->_validateForArray([%{_copyOptions(undef, OPTIONS_ARRAY, $params)}])
                                         : $self;
}

sub _validateForArray {
  my ($self, $params) = @_;

  $self->{'rows'}             = [map { _stripTrailingBlanks($_) } @{$self->{'rows'}}];
  $self->{':numberOfColumns'} = @{$self->{'rows'}} ? @{$self->{'rows'}[0]} : 0;

  validate(@$params, OPTIONS_ARRAY);

  return $self->_copyOptions(OPTIONS_ARRAY, $params)->_validateGeneral($params);
}

sub _validateForCallback {
  my ($self, $params) = @_;

  validate(@$params, OPTIONS_CALLBACK);

  return $self->_copyOptions(OPTIONS_CALLBACK, $params)->_validateGeneral($params);
}

sub _validateGeneral {
  my ($self, $params) = @_;

  validate(@$params, OPTIONS_GENERAL);

  my %params = @$params;
  die("The 'header' parameter contains less elements than an element of the 'rows' parameter")
    if exists($params{'header'}) && exists($params{'rows'}) && @{$params{'header'}} < $self->{':numberOfColumns'};

  return $self->_copyOptions(OPTIONS_GENERAL, $params);
}

1;