package Rstats::Array;
use Object::Simple -base;

use Carp 'croak', 'carp';
use List::Util;
use Rstats;
use B;
use Rstats::Util;

our @CARP_NOT = ('Rstats');

my %types_h = map { $_ => 1 } qw/character complex numeric double integer logical/;

use overload
  bool => \&bool,
  '+' => sub { shift->_operation('add', @_) },
  '-' => sub { shift->_operation('subtract', @_) },
  '*' => sub { shift->_operation('multiply', @_) },
  '/' => sub { shift->_operation('divide', @_) },
  '%' => sub { shift->_operation('remainder', @_) },
  'neg' => \&negation,
  '**' => sub { shift->_operation('raise', @_) },
  '<' => sub { shift->_operation('less_than', @_) },
  '<=' => sub { shift->_operation('less_than_or_equal', @_) },
  '>' => sub { shift->_operation('more_than', @_) },
  '>=' => sub { shift->_operation('more_than_or_equal', @_) },
  '==' => sub { shift->_operation('equal', @_) },
  '!=' => sub { shift->_operation('not_equal', @_) },
  '""' => \&to_string,
  fallback => 1;

has 'elements';

sub values {
  my $self = shift;
  
  if (@_) {
    my @elements = map { Rstats::Util::element($_) } @{$_[0]};
    $self->{elements} = \@elements;
  }
  else {
    my @values = map { Rstats::Util::value($_) } @{$self->elements};
  
    return \@values;
  }
}

sub value { Rstats::Util::value(shift->element(@_)) }

sub typeof {
  my $self = shift;
  
  my $type = $self->{type};
  my $a1_elements = defined $type ? $type : "NULL";
  my $a1 = Rstats::Array->c([$a1_elements]);
  
  return $a1;
}

sub mode {
  my $self = shift;
  
  if (@_) {
    my $type = $_[0];
    croak qq/Error in eval(expr, envir, enclos) : could not find function "as_$type"/
      unless $types_h{$type};
    
    if ($type eq 'numeric') {
      $self->{type} = 'double';
    }
    else {
      $self->{type} = $type;
    }
    
    return $self;
  }
  else {
    my $type = $self->{type};
    my $mode;
    if (defined $type) {
      if ($type eq 'integer' || $type eq 'double') {
        $mode = 'numeric';
      }
      else {
        $mode = $type;
      }
    }
    else {
      croak qq/could not find function "as_$type"/;
    }

    return Rstats::Array->c([$mode]);
  }
}

sub bool {
  my $self = shift;
  
  my $length = @{$self->elements};
  if ($length == 0) {
    croak 'Error in if (a) { : argument is of length zero';
  }
  elsif ($length > 1) {
    carp 'In if (a) { : the condition has length > 1 and only the first element will be used';
  }
  
  my $element = $self->element;
  
  return Rstats::Util::bool($element);
}

sub clone_without_elements {
  my ($self, %opt) = @_;
  
  my $array = Rstats::Array->new;
  $array->{type} = $self->{type};
  $array->{names} = [@{$self->{names} || []}];
  $array->{rownames} = [@{$self->{rownames} || []}];
  $array->{colnames} = [@{$self->{colnames} || []}];
  $array->{dim} = [@{$self->{dim} || []}];
  $array->{elements} = $opt{elements} ? $opt{elements} : [];
  
  return $array;
}

sub row {
  my $self = shift;
  
  my $nrow = $self->nrow->value;
  my $ncol = $self->ncol->value;
  
  my @values = (1 .. $nrow) x $ncol;
  
  return Rstats::Array->array(\@values, [$nrow, $ncol]);
}

sub col {
  my $self = shift;
  
  my $nrow = $self->nrow->value;
  my $ncol = $self->ncol->value;
  
  my @values;
  for my $col (1 .. $ncol) {
    push @values, ($col) x $nrow;
  }
  
  return Rstats::Array->array(\@values, [$nrow, $ncol]);
}

sub nrow {
  my $self = shift;
  
  return Rstats::Array->array($self->dim->values->[0]);
}

sub ncol {
  my $self = shift;
  
  return Rstats::Array->array($self->dim->values->[1]);
}

sub names {
  my $self = shift;
  
  if (@_) {
    my $_names = shift;
    my $names;
    if (!defined $_names) {
      $names = [];
    }
    elsif (ref $_names eq 'ARRAY') {
      $names = $_names;
    }
    elsif (ref $_names eq 'Rstats::Array') {
      $names = $_names->elements;
    }
    else {
      $names = [$_names];
    }
    
    my $duplication = {};
    for my $name (@$names) {
      croak "Don't use same name in names arguments"
        if $duplication->{$name};
      $duplication->{$name}++;
    }
    $self->{names} = $names;
  }
  else {
    $self->{names} = [] unless exists $self->{names};
    return Rstats::Array->array($self->{names});
  }
}

sub colnames {
  my $self = shift;
  
  if (@_) {
    my $_colnames = shift;
    my $colnames;
    if (!defined $_colnames) {
      $colnames = [];
    }
    elsif (ref $_colnames eq 'ARRAY') {
      $colnames = $_colnames;
    }
    elsif (ref $_colnames eq 'Rstats::Array') {
      $colnames = $_colnames->elements;
    }
    else {
      $colnames = [$_colnames];
    }
    
    my $duplication = {};
    for my $name (@$colnames) {
      croak "Don't use same name in colnames arguments"
        if $duplication->{$name};
      $duplication->{$name}++;
    }
    $self->{colnames} = $colnames;
  }
  else {
    $self->{colnames} = [] unless exists $self->{colnames};
    return Rstats::Array->array($self->{colnames});
  }
}

sub rownames {
  my $self = shift;
  
  if (@_) {
    my $_rownames = shift;
    my $rownames;
    if (!defined $_rownames) {
      $rownames = [];
    }
    elsif (ref $_rownames eq 'ARRAY') {
      $rownames = $_rownames;
    }
    elsif (ref $_rownames eq 'Rstats::Array') {
      $rownames = $_rownames->elements;
    }
    else {
      $rownames = [$_rownames];
    }
    
    my $duplication = {};
    for my $name (@$rownames) {
      croak "Don't use same name in rownames arguments"
        if $duplication->{$name};
      $duplication->{$name}++;
    }
    $self->{rownames} = $rownames;
  }
  else {
    $self->{rownames} = [] unless exists $self->{rownames};
    return Rstats::Array->array($self->{rownames});
  }
}

sub dim {
  my $self = shift;
  
  if (@_) {
    my $a1 = $_[0];
    if (ref $a1 eq 'Rstats::Array') {
      $self->{dim} = $a1->elements;
    }
    elsif (ref $a1 eq 'ARRAY') {
      $self->{dim} = $a1;
    }
    elsif(!ref $a1) {
      $self->{dim} = [$a1];
    }
    else {
      croak "Invalid elements is passed to dim argument";
    }
  }
  else {
    $self->{dim} = [] unless exists $self->{dim};
    return Rstats::Array->new(elements => $self->{dim});
  }
}

sub length {
  my $self = shift;
  
  my $length = @{$self->elements};
  
  return $length;
}

sub seq {
  my $self = shift;
  
  # Option
  my $opt = ref $_[-1] eq 'HASH' ? pop @_ : {};
  
  # Along
  my $along = $opt->{along};
  
  if ($along) {
    my $length = $along->length;
    return $self->seq([1,$length]);
  }
  else {
    my $from_to = shift;
    my $from;
    my $to;
    if (ref $from_to eq 'ARRAY') {
      $from = $from_to->[0];
      $to = $from_to->[1];
    }
    elsif (defined $from_to) {
      $from = 1;
      $to = $from_to;
    }
    
    # From
    $from = $opt->{from} unless defined $from;
    croak "seq function need from option" unless defined $from;
    
    # To
    $to = $opt->{to} unless defined $to;

    # Length
    my $length = $opt->{length};
    
    # By
    my $by = $opt->{by};
    
    if (defined $length && defined $by) {
      croak "Can't use by option and length option as same time";
    }
    
    unless (defined $by) {
      if ($to >= $from) {
        $by = 1;
      }
      else {
        $by = -1;
      }
    }
    croak "by option should be except for 0" if $by == 0;
    
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
        croak "by option is invalid number(seq function)";
      }
      
      my $element = $from;
      while ($element <= $to) {
        push @$elements, $element;
        $element += $by;
      }
    }
    else {
      if ($by > 0) {
        croak "by option is invalid number(seq function)";
      }
      
      my $element = $from;
      while ($element >= $to) {
        push @$elements, $element;
        $element += $by;
      }
    }
    
    return $self->c($elements);
  }
}

sub C {
  my ($self, $seq_str) = @_;

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
  
  my $vector = $self->seq({from => $from, to => $to, by => $by});
  
  return $vector;
}

sub c {
  my ($self, $a1) = @_;
  
  # Array
  my $array = Rstats::Array->new;
  
  # Value
  my $elements = [];
  if (defined $a1) {
    if (ref $a1 eq 'ARRAY') {
      for my $a (@$a1) {
        if (ref $a eq 'ARRAY') {
          push @$elements, @$a;
        }
        elsif (ref $a eq 'Rstats::Array') {
          push @$elements, @{$a->elements};
        }
        else {
          push @$elements, $a;
        }
      }
    }
    elsif (ref $a1 eq 'Rstats::Array') {
      $elements = $a1->elements;
    }
    else {
      $elements = [$a1];
    }
  }
  else {
    croak "Invalid first argument";
  }
  
  # Check elements
  my $mode_h = {};
  for my $element (@$elements) {
    next if Rstats::Util::is_na($element);
    
    if (!defined $element) {
      croak "undef is invalid element";
    }
    elsif (Rstats::Util::is_character($element)) {
      $mode_h->{character}++;
    }
    elsif (Rstats::Util::is_complex($element)) {
      $mode_h->{complex}++;
    }
    elsif (Rstats::Util::is_double($element)) {
      $mode_h->{double}++;
    }
    elsif (Rstats::Util::is_integer($element)) {
      $element = Rstats::Util::double($element->value);
      $mode_h->{double}++;
    }
    elsif (Rstats::Util::is_logical($element)) {
      $mode_h->{logical}++;
    }
    elsif (Rstats::Util::is_perl_number($element)) {
      $element = Rstats::Util::double($element);
      $mode_h->{double}++;
    }
    else {
      $element = Rstats::Util::character("$element");
      $mode_h->{character}++;
    }
  }

  # Upgrade elements and type
  my @modes = keys %$mode_h;
  if (@modes > 1) {
    if ($mode_h->{character}) {
      my $a1 = Rstats::Array->new(elements => $elements)->as_character;
      $elements = $a1->elements;
      $array->mode('character');
    }
    elsif ($mode_h->{complex}) {
      my $a1 = Rstats::Array->new(elements => $elements)->as_complex;
      $elements = $a1->elements;
      $array->mode('complex');
    }
    elsif ($mode_h->{double}) {
      my $a1 = Rstats::Array->new(elements => $elements)->as_double;
      $elements = $a1->elements;
      $array->mode('double');
    }
    elsif ($mode_h->{logical}) {
      my $a1 = Rstats::Array->new(elements => $elements)->as_logical;
      $elements = $a1->elements;
      $array->mode('logical');
    }
  }
  else {
    $array->mode($modes[0] || 'logical');
  }
  
  $array->elements($elements);
  
  return $array;
}

sub array {
  my $self = shift;
  
  # Arguments
  my $opt = ref $_[-1] eq 'HASH' ? pop @_ : {};
  my ($a1, $_dim) = @_;
  $_dim = $opt->{dim} unless defined $_dim;
  
  my $array = Rstats::Array->c($a1);

  # Dimention
  my $elements = $array->elements;
  my $dim;
  if (defined $_dim) {
    if (ref $_dim eq 'Rstats::Array') {
      $dim = $_dim->elements;
    }
    elsif (ref $_dim eq 'ARRAY') {
      $dim = $_dim;
    }
    elsif(!ref $_dim) {
      $dim = [$_dim];
    }
  }
  else {
    $dim = [scalar @$elements]
  }
  $array->dim($dim);
  
  # Fix elements
  my $max_length = 1;
  $max_length *= $_ for @{$array->_real_dim_values || [scalar @$elements]};
  if (@$elements > $max_length) {
    @$elements = splice @$elements, 0, $max_length;
  }
  elsif (@$elements < $max_length) {
    my $repeat_count = int($max_length / @$elements) + 1;
    @$elements = (@$elements) x $repeat_count;
    @$elements = splice @$elements, 0, $max_length;
  }
  $array->elements($elements);
  
  return $array;
}

sub _real_dim_values {
  my $self = shift;
  
  my $dim = $self->dim;
  if (@{$dim->values}) {
    return $dim->values;
  }
  else {
    if (defined $self->elements) {
      my $length = @{$self->elements};
      return [$length];
    }
    else {
      return;
    }
  }
}

sub at {
  my $self = shift;
  
  if (@_) {
    $self->{at} = [@_];
    
    return $self;
  }
  
  return $self->{at};
}

sub element {
  my $self = shift;
  
  my $dim_values = $self->_real_dim_values;
  
  if (@_) {
    if (@$dim_values == 1) {
      return $self->elements->[$_[0] - 1];
    }
    elsif (@$dim_values == 2) {
      return $self->elements->[($_[0] + $dim_values->[0] * ($_[1] - 1)) - 1];
    }
    else {
      return $self->get(@_)->elements->[0];
    }
  }
  else {
    return $self->elements->[0];
  }
}

sub is_numeric {
  my $self = shift;
  
  my $is = ($self->{type} || '') eq 'double' || ($self->{type} || '') eq 'integer' ? Rstats::Util::TRUE : Rstats::Util::FALSE;
  
  return $self->c([$is]);
}

sub is_double {
  my $self = shift;
  
  my $is = ($self->{type} || '') eq 'double' ? Rstats::Util::TRUE : Rstats::Util::FALSE;
  
  return $self->c([$is]);
}

sub is_integer {
  my $self = shift;
  
  my $is = ($self->{type} || '') eq 'integer' ? Rstats::Util::TRUE : Rstats::Util::FALSE;
  
  return $self->c([$is]);
}

sub is_complex {
  my $self = shift;
  
  my $is = ($self->{type} || '') eq 'complex' ? Rstats::Util::TRUE : Rstats::Util::FALSE;
  
  return $self->c([$is]);
}

sub is_character {
  my $self = shift;
  
  my $is = ($self->{type} || '') eq 'character' ? Rstats::Util::TRUE : Rstats::Util::FALSE;
  
  return $self->c([$is]);
}

sub is_logical {
  my $self = shift;
  
  my $is = ($self->{type} || '') eq 'logical' ? Rstats::Util::TRUE : Rstats::Util::FALSE;
  
  return $self->c([$is]);
}

sub _as {
  my ($self, $mode) = @_;
  
  if ($mode eq 'character') {
    return $self->as_character;
  }
  elsif ($mode eq 'complex') {
    return $self->as_complex;
  }
  elsif ($mode eq 'double') {
    return $self->as_double;
  }
  elsif ($mode eq 'numeric') {
    return $self->as_numeric;
  }
  elsif ($mode eq 'integer') {
    return $self->as_integer;
  }
  elsif ($mode eq 'logical') {
    return $self->as_logical;
  }
  else {
    croak "Invalid mode is passed";
  }
}

sub as_complex {
  my $self = shift;
  
  my $a1 = $self;
  my $a1_elements = $a1->elements;
  my $a2 = $self->clone_without_elements;
  my @a2_elements = map {
    if (Rstats::Util::is_na($_)) {
      $_;
    }
    elsif (Rstats::Util::is_character($_)) {
      my $z = Rstats::Util::looks_like_complex($_->value);
      if (defined $z) {
        Rstats::Util::complex($z->{re}, $z->{im});
      }
      else {
        carp 'NAs introduced by coercion';
        Rstats::Util::NA;
      }
    }
    elsif (Rstats::Util::is_complex($_)) {
      $_;
    }
    elsif (Rstats::Util::is_double($_)) {
      if (Rstats::Util::is_nan($_)) {
        Rstats::Util::NA;
      }
      else {
        Rstats::Util::complex_double($_, Rstats::Util::double(0));
      }
    }
    elsif (Rstats::Util::is_integer($_)) {
      Rstats::Util::complex($_->value, 0);
    }
    elsif (Rstats::Util::is_logical($_)) {
      Rstats::Util::complex($_->value ? 1 : 0, 0);
    }
    else {
      croak "unexpected type";
    }
  } @$a1_elements;
  $a2->elements(\@a2_elements);
  $a2->{type} = 'complex';

  return $a2;
}

sub as_numeric { as_double(@_) }

sub as_double {
  my $self = shift;
  
  my $a1 = $self;
  my $a1_elements = $a1->elements;
  my $a2 = $self->clone_without_elements;
  my @a2_elements = map {
    if (Rstats::Util::is_na($_)) {
      $_;
    }
    elsif (Rstats::Util::is_character($_)) {
      if (my $num = Rstats::Util::looks_like_number($_->value)) {
        Rstats::Util::double($num + 0);
      }
      else {
        carp 'NAs introduced by coercion';
        Rstats::Util::NA;
      }
    }
    elsif (Rstats::Util::is_complex($_)) {
      carp "imaginary parts discarded in coercion";
      Rstats::Util::double($_->re->value);
    }
    elsif (Rstats::Util::is_double($_)) {
      $_;
    }
    elsif (Rstats::Util::is_integer($_)) {
      Rstats::Util::double($_->value);
    }
    elsif (Rstats::Util::is_logical($_)) {
      Rstats::Util::double($_->value ? 1 : 0);
    }
    else {
      croak "unexpected type";
    }
  } @$a1_elements;
  $a2->elements(\@a2_elements);
  $a2->{type} = 'double';

  return $a2;
}

sub as_integer {
  my $self = shift;
  
  my $a1 = $self;
  my $a1_elements = $a1->elements;
  my $a2 = $self->clone_without_elements;
  my @a2_elements = map {
    if (Rstats::Util::is_na($_)) {
      $_;
    }
    elsif (Rstats::Util::is_character($_)) {
      if (my $num = Rstats::Util::looks_like_number($_->value)) {
        Rstats::Util::integer(int $num);
      }
      else {
        carp 'NAs introduced by coercion';
        Rstats::Util::NA;
      }
    }
    elsif (Rstats::Util::is_complex($_)) {
      carp "imaginary parts discarded in coercion";
      Rstats::Util::integer(int($_->re->value));
    }
    elsif (Rstats::Util::is_double($_)) {
      if (Rstats::Util::is_nan($_) || Rstats::Util::is_infinite($_)) {
        Rstats::Util::NA;
      }
      else {
        Rstats::Util::integer($_->value);
      }
    }
    elsif (Rstats::Util::is_integer($_)) {
      $_; 
    }
    elsif (Rstats::Util::is_logical($_)) {
      Rstats::Util::integer($_->value ? 1 : 0);
    }
    else {
      croak "unexpected type";
    }
  } @$a1_elements;
  $a2->elements(\@a2_elements);
  $a2->{type} = 'integer';

  return $a2;
}

sub as_logical {
  my $self = shift;
  
  my $a1 = $self;
  my $a1_elements = $a1->elements;
  my $a2 = $self->clone_without_elements;
  my @a2_elements = map {
    if (Rstats::Util::is_na($_)) {
      $_;
    }
    elsif (Rstats::Util::is_character($_)) {
      Rstats::Util::NA;
    }
    elsif (Rstats::Util::is_complex($_)) {
      carp "imaginary parts discarded in coercion";
      my $re = $_->re->value;
      my $im = $_->im->value;
      if (defined $re && $re == 0 && defined $im && $im == 0) {
        Rstats::Util::FALSE;
      }
      else {
        Rstats::Util::TRUE;
      }
    }
    elsif (Rstats::Util::is_double($_)) {
      if (Rstats::Util::is_nan($_)) {
        Rstats::Util::NA;
      }
      elsif (Rstats::Util::is_infinite($_)) {
        Rstats::Util::TRUE;
      }
      else {
        $_->value == 0 ? Rstats::Util::FALSE : Rstats::Util::TRUE;
      }
    }
    elsif (Rstats::Util::is_integer($_)) {
      $_->value == 0 ? Rstats::Util::FALSE : Rstats::Util::TRUE;
    }
    elsif (Rstats::Util::is_logical($_)) {
      $_->value == 0 ? Rstats::Util::FALSE : Rstats::Util::TRUE;
    }
    else {
      croak "unexpected type";
    }
  } @$a1_elements;
  $a2->elements(\@a2_elements);
  $a2->{type} = 'logical';

  return $a2;
}

sub as_character {
  my $self = shift;

  my $a1_elements = $self->elements;
  my $a2 = $self->clone_without_elements;
  my @a2_elements = map {
    Rstats::Util::character(Rstats::Util::to_string($_))
  } @$a1_elements;
  $a2->elements(\@a2_elements);
  $a2->{type} = 'character';

  return $a2;
}

sub get {
  my $self = shift;

  my $opt = ref $_[-1] eq 'HASH' ? pop @_ : {};
  my $drop = $opt->{drop};
  $drop = 1 unless defined $drop;
  
  my @_indexs = @_;

  my $_indexs;
  if (@_indexs) {
    $_indexs = \@_indexs;
  }
  else {
    my $at = $self->at;
    $_indexs = ref $at eq 'ARRAY' ? $at : [$at];
  }
  $self->at($_indexs);
  
  if (ref $_indexs->[0] eq 'CODE') {
    my @elements2 = grep { $_indexs->[0]->() } @{$self->values};
    return Rstats::Array->c(\@elements2);
  }

  my ($positions, $a2_dim) = $self->_parse_index($drop, @$_indexs);
  
  my @a2_elements = map { $self->elements->[$_ - 1] } @$positions;
  
  return Rstats::Array->array(\@a2_elements, $a2_dim);
}

sub NULL {
  my $self = shift;
  
  return Rstats::Array->numeric(0);
}

sub numeric {
  my ($self, $num) = @_;
  
  return Rstats::Array->c([(0) x $num]);
}

sub _to_a {
  my ($self, $data) = @_;
  
  return $self->NULL unless defined $data;
  my $v;
  if (ref $data eq 'Rstats::Array') {
    $v = $data;
  }
  else {
    $v = Rstats::Array->c($data);
  }
  
  return $v;
}

sub set {
  my ($self, $_array) = @_;

  my $at = $self->at;
  my $_indexs = ref $at eq 'ARRAY' ? $at : [$at];

  my $code;
  my $array;
  if (ref $_array eq 'CODE') {
    $code = $_array;
  }
  else {
    $array = Rstats::Array->_to_a($_array);
  }
  
  my ($positions, $a2_dim) = $self->_parse_index(0, @$_indexs);
  
  my $self_elements = $self->elements;
  if ($code) {
    for (my $i = 0; $i < @$positions; $i++) {
      my $pos = $positions->[$i];
      local $_ = Rstats::Util::value($self_elements->[$pos - 1]);
      $self_elements->[$pos - 1] = Rstats::Util::element($code->());
    }
  }
  else {
    my $array_elements = $array->elements;
    for (my $i = 0; $i < @$positions; $i++) {
      my $pos = $positions->[$i];
      $self_elements->[$pos - 1] = $array_elements->[(($i + 1) % @$positions) - 1];
    }
  }
  
  return $self;
}


sub _parse_index {
  my ($self, $drop, @_indexs) = @_;
  
  my $a1_dim = $self->_real_dim_values;
  my @indexs;
  my @a2_dim;
  
  for (my $i = 0; $i < @$a1_dim; $i++) {
    my $_index = $_indexs[$i];
    
    my $index = Rstats::Array->_to_a($_index);
    my $index_values = $index->values;
    if (@$index_values && !$index->is_character && !$index->is_logical) {
      my $minus_count = 0;
      for my $index_value (@$index_values) {
        if ($index_value == 0) {
          croak "0 is invalid index";
        }
        else {
          $minus_count++ if $index_value < 0;
        }
      }
      croak "Can't min minus sign and plus sign"
        if $minus_count > 0 && $minus_count != @$index_values;
      $index->{_minus} = 1 if $minus_count > 0;
    }
    
    if (!@{$index->values}) {
      my $index_values_new = [1 .. $a1_dim->[$i]];
      $index = Rstats::Array->array($index_values_new);
    }
    elsif ($index->is_character) {
      if ($self->is_vector) {
        my $index_new_values = [];
        for my $name (@{$index->values}) {
          my $i = 0;
          my $value;
          for my $self_name (@{$self->names->values}) {
            if ($name eq $self_name) {
              $value = $self->values->[$i];
              last;
            }
            $i++;
          }
          croak "Can't find name" unless defined $value;
          push @$index_new_values, $value;
        }
        $indexs[$i] = Rstats::Array->array($index_new_values);
      }
      elsif ($self->is_matrix) {
        
      }
      else {
        croak "Can't support name except vector and matrix";
      }
    }
    elsif ($index->is_logical) {
      my $index_values_new = [];
      for (my $i = 0; $i < @{$index->values}; $i++) {
        push @$index_values_new, $i + 1 if Rstats::Util::bool($index->elements->[$i]);
      }
      $index = Rstats::Array->array($index_values_new);
    }
    elsif ($index->{_minus}) {
      my $index_value_new = [];
      
      for my $k (1 .. $a1_dim->[$i]) {
        push @$index_value_new, $k unless grep { $_ == -$k } @{$index->values};
      }
      $index = Rstats::Array->array($index_value_new);
    }

    push @indexs, $index;

    my $count = @{$index->elements};
    push @a2_dim, $count unless $count == 1 && $drop;
  }
  @a2_dim = (1) unless @a2_dim;
  
  my $index_values = [map { $_->values } @indexs];
  my $ords = $self->_cross_product($index_values);
  my @positions = map { $self->_pos($_, $a1_dim) } @$ords;
  
  return (\@positions, \@a2_dim);
}

sub _cross_product {
  my ($self, $values) = @_;

  my @idxs = (0) x @$values;
  my @idx_idx = 0..(@idxs - 1);
  my @array = map { $_->[0] } @$values;
  my $result = [];
  
  push @$result, [@array];
  my $end_loop;
  while (1) {
    foreach my $i (@idx_idx) {
      if( $idxs[$i] < @{$values->[$i]} - 1 ) {
        $array[$i] = $values->[$i][++$idxs[$i]];
        push @$result, [@array];
        last;
      }
      
      if ($i == $idx_idx[-1]) {
        $end_loop = 1;
        last;
      }
      
      $idxs[$i] = 0;
      $array[$i] = $values->[$i][0];
    }
    last if $end_loop;
  }
  
  return $result;
}

sub _pos {
  my ($self, $ord, $dim) = @_;
  
  my $pos = 0;
  for (my $d = 0; $d < @$dim; $d++) {
    if ($d > 0) {
      my $tmp = 1;
      $tmp *= $dim->[$_] for (0 .. $d - 1);
      $pos += $tmp * ($ord->[$d] - 1);
    }
    else {
      $pos += $ord->[$d];
    }
  }
  
  return $pos;
}

sub to_string {
  my $self = shift;

  my $elements = $self->elements;
  
  my $dim_values = $self->_real_dim_values;
  
  my $dim_length = @$dim_values;
  my $dim_num = $dim_length - 1;
  my $positions = [];
  
  my $str;
  if (@$elements) {
    if ($dim_length == 1) {
      my $names = $self->names->values;
      if (@$names) {
        $str .= join(' ', @$names) . "\n";
      }
      my @parts = map { Rstats::Util::to_string($_) } @$elements;
      $str .= '[1] ' . join(' ', @parts) . "\n";
    }
    elsif ($dim_length == 2) {
      $str .= '     ';
      
      my $colnames = $self->colnames->values;
      if (@$colnames) {
        $str .= join(' ', @$colnames) . "\n";
      }
      else {
        for my $d2 (1 .. $dim_values->[1]) {
          $str .= $d2 == $dim_values->[1] ? "[,$d2]\n" : "[,$d2] ";
        }
      }
      
      my $rownames = $self->rownames->values;
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
          push @parts, Rstats::Util::to_string($self->element($d1, $d2));
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
          unshift @$positions, $i;
          if (@dim_values > 2) {
            $dim_num--;
            $code->(@dim_values);
            $dim_num++;
          }
          else {
            $str .= '     ';
            for my $d2 (1 .. $dim_values[1]) {
              $str .= $d2 == $dim_values[1] ? "[,$d2]\n" : "[,$d2] ";
            }
            for my $d1 (1 .. $dim_values[0]) {
              $str .= "[$d1,] ";
              
              my @parts;
              for my $d2 (1 .. $dim_values[1]) {
                push @parts, Rstats::Util::to_string($self->element($d1, $d2, @$positions));
              }
              
              $str .= join(' ', @parts) . "\n";
            }
          }
          shift @$positions;
        }
      };
      $code->(@$dim_values);
    }
  }
  else {
    $str = 'NULL';
  }
  
  return $str;
}

sub negation {
  my $self = shift;
  
  my $a1_elements = [map { Rstats::Util::negation($_) } @{$self->elements}];
  my $a1 = $self->clone_without_elements;
  $a1->elements($a1_elements);
  
  return $a1;
}

sub _operation {
  my ($self, $op, $data, $reverse) = @_;
  
  my $a1;
  my $a2;
  if (ref $data eq 'Rstats::Array') {
    $a1 = $self;
    $a2 = $data;
  }
  else {
    if ($reverse) {
      $a1 = Rstats::Array->array([$data]);
      $a2 = $self;
    }
    else {
      $a1 = $self;
      $a2 = Rstats::Array->array([$data]);
    }
  }
  
  # Upgrade mode if mode is different
  ($a1, $a2) = $self->_upgrade_mode($a1, $a2)
    if $a1->{type} ne $a2->{type};
  
  # Calculate
  my $a1_length = @{$a1->elements};
  my $a2_length = @{$a2->elements};
  my $longer_length = $a1_length > $a2_length ? $a1_length : $a2_length;
  
  no strict 'refs';
  my $operation = "Rstats::Util::$op";
  my @a3_elements = map {
    &$operation($a1->elements->[$_ % $a1_length], $a2->elements->[$_ % $a2_length])
  } (0 .. $longer_length - 1);
  
  my $a3 = Rstats::Array->array(\@a3_elements);
  if ($op eq '/') {
    $a3->{type} = 'double';
  }
  else {
    $a3->{type} = $a1->{type};
  }
  
  return $a3;
}

sub _upgrade_mode {
  my ($self, @arrays) = @_;
  
  # Check elements
  my $mode_h = {};
  for my $array (@arrays) {
    my $type = $array->{type} || '';
    if ($type eq 'character') {
      $mode_h->{character}++;
    }
    elsif ($type eq 'complex') {
      $mode_h->{complex}++;
    }
    elsif ($type eq 'double') {
      $mode_h->{double}++;
    }
    elsif ($type eq 'integer') {
      $mode_h->{integer}++;
    }
    elsif ($type eq 'logical') {
      $mode_h->{logical}++;
    }
    else {
      croak "Invalid mode";
    }
  }

  # Upgrade elements and type if mode is different
  my @modes = keys %$mode_h;
  if (@modes > 1) {
    my $to_mode;
    if ($mode_h->{character}) {
      $to_mode = 'character';
    }
    elsif ($mode_h->{complex}) {
      $to_mode = 'complex';
    }
    elsif ($mode_h->{double}) {
      $to_mode = 'double';
    }
    elsif ($mode_h->{integer}) {
      $to_mode = 'integer';
    }
    elsif ($mode_h->{logical}) {
      $to_mode = 'logical';
    }
    $_ = $_->_as($to_mode) for @arrays;
  }
  
  return @arrays;
}


sub matrix {
  my $self = shift;
  
  my $opt = ref $_[-1] eq 'HASH' ? pop @_ : {};

  my ($_a1, $nrow, $ncol, $byrow, $dirnames) = @_;

  croak "matrix method need data as frist argument"
    unless defined $_a1;
  
  my $a1 = Rstats::Array->_to_a($_a1);
  
  # Row count
  $nrow = $opt->{nrow} unless defined $nrow;
  
  # Column count
  $ncol = $opt->{ncol} unless defined $ncol;
  
  # By row
  $byrow = $opt->{byrow} unless defined $byrow;
  
  my $a1_elements = $a1->elements;
  my $a1_length = @$a1_elements;
  if (!defined $nrow && !defined $ncol) {
    $nrow = $a1_length;
    $ncol = 1;
  }
  elsif (!defined $nrow) {
    $nrow = int($a1_length / $ncol);
  }
  elsif (!defined $ncol) {
    $ncol = int($a1_length / $nrow);
  }
  my $length = $nrow * $ncol;
  
  my $dim = [$nrow, $ncol];
  my $matrix;
  if ($byrow) {
    $matrix = $self->array(
      $a1_elements,
      [$dim->[1], $dim->[0]],
    );
    
    $matrix = $self->t($matrix);
  }
  else {
    $matrix = $self->array($a1_elements, $dim);
  }
  
  return $matrix;
}

sub t {
  my ($self, $m1) = @_;
  
  my $m1_row = $m1->dim->elements->[0];
  my $m1_col = $m1->dim->elements->[1];
  
  my $m2 = $self->matrix(0, $m1_col, $m1_row);
  
  for my $row (1 .. $m1_row) {
    for my $col (1 .. $m1_col) {
      my $element = $m1->element($row, $col);
      $m2->at($col, $row);
      $m2->set($element);
    }
  }
  
  return $m2;
}

sub is_array {
  my $self = shift;
  
  return $self->c([Rstats::Util::TRUE()]);
}

sub is_vector {
  my $self = shift;
  
  my $is = @{$self->dim->elements} == 0 ? Rstats::Util::TRUE() : Rstats::Util::FALSE();
  
  return $self->c([$is]);
}

sub is_matrix {
  my $self = shift;

  my $is = @{$self->dim->elements} == 2 ? Rstats::Util::TRUE() : Rstats::Util::FALSE();
  
  return $self->c([$is]);
}

sub as_matrix {
  my $self = shift;
  
  my $a1_dim_elements = $self->_real_dim_values;
  my $a1_dim_count = @$a1_dim_elements;
  my $a2_dim_elements = [];
  my $row;
  my $col;
  if ($a1_dim_count == 2) {
    $row = $a1_dim_elements->[0];
    $col = $a1_dim_elements->[1];
  }
  else {
    $row = 1;
    $row *= $_ for @$a1_dim_elements;
    $col = 1;
  }
  
  my $a2_elements = [@{$self->elements}];
  
  return $self->matrix($a2_elements, $row, $col);
}

sub as_array {
  my $self = shift;
  
  my $a1_elements = [@{$self->elements}];
  my $a1_dim_elements = [@{$self->_real_dim_values}];
  
  return $self->array($a1_elements, $a1_dim_elements);
}

sub as_vector {
  my $self = shift;
  
  my $a1_elements = [@{$self->elements}];
  
  return $self->c($a1_elements);
}

1;

