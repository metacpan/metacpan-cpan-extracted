package Rstats::Class;

use Object::Simple -base;
require Rstats::Func;
use Carp 'croak';
use Rstats::Util ();
use Digest::MD5 'md5_hex';
use Rstats::Object;

has helpers => sub { {} };

sub get_helper {
  my ($self, $name,) = @_;
  
  if ($self->{proxy}{$name}) {
    return bless {r => $self}, $self->{proxy}{$name};
  }
  elsif (my $h = $self->helpers->{$name}) {
    return $h;
  }

  my $found;
  my $class = 'Rstats::Helpers::' . md5_hex "$name:$self";
  my $re = $name eq '' ? qr/^(([^.]+))/ : qr/^(\Q$name\E\.([^.]+))/;
  for my $key (keys %{$self->helpers}) {
    $key =~ $re ? ($found, my $method) = (1, $2) : next;
    my $sub = $self->get_helper($1);
    Rstats::Util::monkey_patch $class, $method => sub {
      my $proxy = shift;
      return $sub->($proxy->{r}, @{$proxy->{args} || []}, @_);
    }
  }

  $found ? push @{$self->{namespaces}}, $class : return undef;
  $self->{proxy}{$name} = $class;
  return $self->get_helper($name);
}

# TODO
# logp1x
# gamma
# lgamma
# complete_cases
# cor
# pmatch regexpr
# substr substring
# strsplit  strwrap
# outer(x, y, f)
# reorder()
# relevel()
# read.csv()
# read.csv2()
# read.delim()
# read.delim2()
# read.fwf()
# merge
# replicate
# split
# by
# aggregate
# reshape

my @func_names = qw/
  sd
  sin
  sweep
  set_seed
  runif
  apply
  mapply
  tapply
  lapply
  sapply
  abs
  acos
  acosh
  append
  Arg
  asin
  asinh
  atan
  atanh
  atan2
  c_
  c_double
  c_character
  c_complex
  c_integer
  c_logical
  C_
  charmatch
  chartr
  cbind
  ceiling
  col
  colMeans
  colSums
  Conj
  cos
  cosh
  cummax
  cummin
  cumsum
  cumprod
  data_frame
  diag
  diff
  exp
  expm1
  factor
  F
  F_
  FALSE
  floor
  gl
  grep
  gsub
  head
  i_
  ifelse
  interaction
  I
  Im
  Re
  intersect
  kronecker
  list
  log
  logb
  log2
  log10
  lower_tri
  match
  median
  merge
  Mod
  NA
  NaN
  na_omit
  ncol
  nrow
  NULL
  numeric
  matrix
  max
  mean
  min
  nchar
  order
  ordered
  outer
  paste
  pi
  pmax
  pmin
  prod
  range
  rank
  rbind
  quantile
  rep
  replace
  rev
  rnorm
  round
  row
  rowMeans
  rowSums
  sample
  seq
  sequence
  set_diag
  setdiff
  setequal
  sinh
  sum
  sqrt
  sort
  sub
  subset
  t
  tail
  tan
  tanh
  tolower
  toupper
  T_
  TRUE
  transform
  trunc
  unique
  union
  upper_tri
  var
  which
  labels
  levels
  names
  nlevels
  dimnames
  colnames
  rownames
  mode
  str
  typeof
  pi
  complex
  array
  length
  clone
  equal
  not_equal
  less_than
  less_than_or_equal
  more_than
  more_than_or_equal
  add
  subtract
  multiply
  divide
  pow
  negate
  dim
  Inf
  NaN
  NA
  to_string
  get
  set
  getin
  value
  values
  dim_as_array
  class
  type
  get_type
  at
  get_length
/;

sub new {
  my $self = shift->SUPER::new(@_);
  
  for my $func_name (@func_names) {
    no strict 'refs';
    my $func = \&{"Rstats::Func::$func_name"};
    $self->helper($func_name => $func);
  }

  no strict 'refs';
  $self->helper('is.array' => \&Rstats::Func::is_array);
  $self->helper('is.character' => \&Rstats::Func::is_character);
  $self->helper('is.complex' => \&Rstats::Func::is_complex);
  $self->helper('is.finite' => \&Rstats::Func::is_finite);
  $self->helper('is.infinite' => \&Rstats::Func::is_infinite);
  $self->helper('is.list' => \&Rstats::Func::is_list);
  $self->helper('is.matrix' => \&Rstats::Func::is_matrix);
  $self->helper('is.na' => \&Rstats::Func::is_na);
  $self->helper('is.nan' => \&Rstats::Func::is_nan);
  $self->helper('is.null' => \&Rstats::Func::is_null);
  $self->helper('is.numeric' => \&Rstats::Func::is_numeric);
  $self->helper('is.double' => \&Rstats::Func::is_double);
  $self->helper('is.integer' => \&Rstats::Func::is_integer);
  $self->helper('is.vector' => \&Rstats::Func::is_vector);
  $self->helper('is.factor' => \&Rstats::Func::is_factor);
  $self->helper('is.ordered' => \&Rstats::Func::is_ordered);
  $self->helper('is.data_frame' => \&Rstats::Func::is_data_frame);
  $self->helper('is.logical' => \&Rstats::Func::is_logical);
  $self->helper('is.element' => \&Rstats::Func::is_element);

  $self->helper('as.array' => \&Rstats::Func::as_array);
  $self->helper('as.character' => \&Rstats::Func::as_character);
  $self->helper('as.complex' => \&Rstats::Func::as_complex);
  $self->helper('as.integer' => \&Rstats::Func::as_integer);
  $self->helper('as.double' => \&Rstats::Func::as_double);
  $self->helper('as.list' => \&Rstats::Func::as_list);
  $self->helper('as.logical' => \&Rstats::Func::as_logical);
  $self->helper('as.matrix' => \&Rstats::Func::as_matrix);
  $self->helper('as.numeric' => \&Rstats::Func::as_numeric);
  $self->helper('as.vector' => \&Rstats::Func::as_vector);

  $self->helper('read.table' => \&Rstats::Func::read_table);

  return $self;
}

sub AUTOLOAD {
  my $self = shift;

  my ($package, $method) = split /::(\w+)$/, our $AUTOLOAD;
  Carp::croak "Undefined subroutine &${package}::$method called"
    unless Scalar::Util::blessed $self && $self->isa(__PACKAGE__);

  # Call helper with current controller
  Carp::croak qq{Can't locate object method "$method" via package "$package"}
    unless my $helper = $self->get_helper($method);
  
  # Helper
  if (ref $helper eq 'CODE') {
    return $helper->($self, @_);
  }
  #Proxy
  else {
    return $helper;
  }
}

sub DESTROY { }

sub helper {
  my $self = shift;
  
  # Merge
  my $helpers = ref $_[0] eq 'HASH' ? $_[0] : {@_};
  $self->helpers({%{$self->helpers}, %$helpers});
  
  return $self;
}

1;

=head1 NAME

Rstats::Class - Rstats Object-Oriented interface

=head1 SYNOPSYS
  
  use Rstats::Class;
  my $r = Rstats::Class->new;
  
  # Array
  my $v1 = $r->c_(1, 2, 3);
  my $v2 = $r->c_(2, 3, 4);
  my $v3 = $v1 + v2;
  print $v3;
