package Rstats;
use strict;
use warnings;

our $VERSION = '0.0148';

use Rstats::Class;

sub import {
  my $self = shift;
  
  my $class = caller;
  
  my $r = Rstats::Class->new;
  
  # Export primary methods
  no strict 'refs';
  my @methods = qw/c_ C_ array matrix list data_frame factor ordered/;
  for my $method (@methods) {
    no strict 'refs';
    my $func = \&{"Rstats::Func::$method"};

    *{"${class}::$method"} = sub { $func->($r, @_) }
  }
  *{"${class}::r"} = sub { $r };
  
  # Export none argument methods
  my @methods_no_args = qw/i_ T_ F_ TRUE FALSE NA NaN Inf NULL pi/;
  for my $method (@methods_no_args) {
    no strict 'refs';
    my $func = \&{"Rstats::Func::$method"};

    *{"${class}::$method"} = sub () { $func->($r, @_) };
  }
  
  warnings->unimport('ambiguous');
}

require XSLoader;
XSLoader::load('Rstats', $VERSION);

1;

=head1 NAME

Rstats - R language build on Perl

B<Rstats is yet experimental release. Incompatible change will occur without warning.>

=head1 SYNOPSYS
  
  use Rstats;
  
  # Vector
  my $v1 = c_(1, 2, 3);
  my $v2 = c_(3, 4, 5);
  
  my $v3 = $v1 + v2;
  print $v3;
  
  # Sequence m:n
  my $v1 = C_("1:3");

  # Matrix
  my $m1 = matrix(C_("1:12"), 4, 3);
  
  # Array
  my $a1 = array(C_("1:24"), c_(4, 3, 2));

  # Complex
  my $z1 = 1 + 2 * i_;
  my $z2 = 3 + 4 * i_;
  my $z3 = $z1 * $z2;
  
  # Special value
  my $true = TRUE;
  my $false = FALSE;
  my $na = NA;
  my $nan = NaN;
  my $inf = Inf;
  my $null = NULL;
  
  # all methods are called from r
  my $x1 = r->sum(c_(1, 2, 3));
  
  # Register helper
  r->helper(my_sum => sub {
    my ($r, $x1) = @_;
    
    my $total = 0;
    for my $value (@{$x1->values}) {
      $total += $value;
    }
    
    return c_($total);
  });
  my $x2 = r->my_sum(c_(1, 2, 3));

=head1 FUNCTIONS

=head2 c_

  # c(1, 2, 3)
  c_(1, 2, 3)

Create vector. C<c_> function is equal to C<c> of R.

=head2 C_

  # 1:24
  C_("1:24")

C_ function is equal to C<m:n> of R.

=head2 array

  # array(1:24, c(4, 3, 2))
  array(C_("1:24"), c_(4, 3, 2))

=head2 TRUE

  # TRUE
  TRUE

=head2 T_

  # T
  T_

Alias of TRUE

=head2 FALSE
  
  # FALSE
  FALSE

=head2 F_
  
  # F
  F_

Alias of FALSE

=head2 NA

  # NA
  NA

=head2 NaN
  
  # NaN
  NaN

=head2 Inf

  # Inf
  Inf

=head2 NULL
  
  # NULL
  NULL

=head2 matrix

  # matrix(1:12, 4, 3)
  matrix(C_("1:12"), 4, 3)
  
  # matrix(1:12, nrow=4, ncol=3)
  matrix(C_("1:12"), {nrow => 4, ncol => 3});
  
  # matrix(1:12, 4, 3, byrow=TRUE)
  matrix(C_("1:12"), 4, 3, {byrow => TRUE});

=head1 VECTOR ACCESS

=head2 Getter

  # x1[1]
  $x1->get(1)

  # x1[1, 2]
  $x1->get(1, 2)
  
  # x1[c(1,2), c(3,4)]
  $x1->get(c_(1,2), c_(3,4))
  
  # x1[,2]
  $x1->get(NULL, 2)
  
  # x1[-1]
  $x1->get(-1)
  
  # x1[TRUE, FALSE]
  $x1->get(TRUE, FALSE)
  
  # x1[c("id", "title")]
  $x1->get(c_("id", "title"))

=head2 Setter

  # x1[1] <- x2
  $x1->at(1)->set($x2)

  # x1[1, 2] <- x2
  $x1->at(1, 2)->set($x2)
  
  # x1[c(1,2), c(3,4)] <- x2
  $x1->at(c_(1,2), c_(3,4))->set($x2)
  
  # x1[,2] <- x2
  $x1->at(NULL, 2)->set($x2)
  
  # x1[-1] <- x2
  $x1->at(-1)->set($x2)
  
  # x1[TRUE, FALSE] <- x2
  $x1->at(TRUE, FALSE)->set($x2);
  
  # x1[c("id", "title")] <- x2
  $x1->at(c_("id", "title"))->set($x2);

=head1 OPERATORS

  # x1 + x2
  $x1 + $x2
  
  # x1 - x2
  $x1 - $x2
  
  # x1 * x2
  $x1 * $x2
  
  # x1 / x2
  $x1 / $x2
  
  # x1 ^ x2 (power)
  $x1 ** $x2
  
  # x1 %% x2 (remainder)
  $x1 % $x2

  # x1 %*% x2 (vector inner product or matrix product)
  $x1 x $x2
  
  # x1 %/% x2 (integer quotient)
  r->tranc($x1 / $x2)

=head1 METHODS

=head2 abs

  # abs(x1)
  r->abs($x1)

=head2 acos

  # acos(x1)
  r->acos($x1)

=head2 acosh

  # acosh(x1)
  r->acosh($x1)

=head2 append

=head2 apply

=head2 Arg

=head2 array

=head2 asin

  # asin(x1)
  r->asin($x1)

=head2 asinh

  # asinh(x1)
  r->asinh($x1)

=head2 atan2

=head2 atan

  # atan(x1)
  r->atan($x1)

=head2 atanh

  # atanh(x1)
  r->atanh($x1)

=head2 c

=head2 vec

=head2 charmatch

=head2 chartr

=head2 cbind

  # cbind(c(1, 2), c(3, 4), c(5, 6))
  r->cbind(c_(1, 2), c_(3, 4), c_(5, 6));

=head2 ceiling

  # ceiling(x1)
  r->ceiling($x1)

=head2 col

  # col(x1)
  r->col($x1)

=head2 colMeans

  # colMeans(x1)
  r->colMeans($x1)

=head2 colSums

=head2 Conj

=head2 cos

  # cos(x1)
  r->cos($x1)

=head2 cosh

  # cosh(x1)
  r->cosh($x1)

=head2 cummax

=head2 cummin

=head2 cumsum

=head2 cumprod

=head2 complex

=head2 data_frame

=head2 diag

=head2 diff

=head2 exp

  # exp(x1)
  r->exp($x1)

=head2 expm1

  # expm1(x1)
  r->expm1($x1)

=head2 factor

=head2 F

=head2 FALSE

=head2 floor

  # floor(x1)
  r->floor($x1)

=head2 gl

=head2 grep

=head2 gsub

=head2 head

=head2 i

=head2 ifelse

=head2 interaction

=head2 is->element

=head2 I

=head2 Im

=head2 Inf

=head2 intersect

=head2 kronecker

=head2 length

=head2 list

=head2 log

  # log(x1)
  r->log($x1)

=head2 logb

  # logb(x1)
  r->logb($x1)

=head2 log2

  # log2(x1)
  r->log2($x1)

=head2 log10

  # log10(x1)
  r->log10($x1)

=head2 lower_tri

=head2 match

=head2 median

=head2 merge

=head2 Mod

=head2 NA

=head2 NaN

=head2 na_omit

=head2 ncol

  # ncol(x1)
  r->ncol($x1)

=head2 nrow

  # nrow(x1)
  r->nrow($x1)

=head2 NULL

=head2 numeric

=head2 matrix

=head2 max

=head2 mean

=head2 min

=head2 nchar

=head2 order

=head2 ordered

=head2 outer

=head2 paste

=head2 pi

=head2 pmax

=head2 pmin

=head2 prod

=head2 range

=head2 rank

=head2 rbind

  # rbind(c(1, 2), c(3, 4), c(5, 6))
  r->rbind(c_(1, 2), c_(3, 4), c_(5, 6))

=head2 Re

=head2 quantile

=head2 read->table

  # read.table(...)
  r->read->table(...)

=head2 rep

=head2 replace

=head2 rev

=head2 rnorm

=head2 round

  # round(x1)
  r->round($x1)

  # round(x1, digit)
  r->round($x1, $digits)
  
  # round(x1, digits=1)
  r->round($x1, {digits => TRUE});

=head2 row

  # row(x1)
  r->row($x1)

=head2 rowMeans

  # rowMeans(x1)
  r->rowMeans($x1)

=head2 rowSums

  # rowSums(x1)
  r->rowSums($x1)

=head2 sample

=head2 seq

=head2 sequence

=head2 set_diag

=head2 setdiff

=head2 setequal

=head2 sin

  # sin(x1)
  r->sin($x1)

=head2 sinh

  # sinh(x1)
  r->sinh($x1)

=head2 sum

=head2 sqrt

  # sqrt(x1)
  r->sqrt($x1)

=head2 sort

=head2 sub

=head2 subset

=head2 sweep

=head2 t

  # t
  r->t($x1)

=head2 tail

=head2 tan

  # tan(x1)
  r->tan($x1)

=head2 tanh

  # tanh(x1)
  r->tanh($x1)

=head2 tapply

=head2 tolower

=head2 toupper

=head2 T

=head2 TRUE

=head2 transform

=head2 trunc

  # trunc(x1)
  r->trunc($x1)

=head2 unique

=head2 union

=head2 upper_tri

=head2 var

=head2 which

=head2 as->array

  # as.array(x1)
  r->as->array($x1)

=head2 as->character

  # as.character(x1)
  r->as->character($x1)

=head2 as->complex

  # as.complex(x1)
  r->as->complex($x1)

=head2 as->integer

  # as.integer(x1)
  r->as->integer($x1)

=head2 as->list

  # as.list
  r->as->list($x1)

=head2 as->logical

  # as.logical
  r->as->logical($x1)

=head2 as->matrix

  # as.matrix(x1)
  r->as->matrix($x1)

=head2 as->numeric

  # as.numeric(x1)
  r->as->numeric($x1)

=head2 as->vector

  # as.vector(x1)
  r->as->vector($x1)

=head2 is->array

  # is.array(x1)
  r->is->array($x1)

=head2 is->character

  # is.character(x1)
  r->is->character($x1)

=head2 is->complex

  # is.complex(x1)
  r->is->complex($x1)

=head2 is->finite

  # is.finite(x1)
  r->is->finite($x1)

=head2 is->infinite

  # is.infinite(x1)
  r->is->infinite($x1)

=head2 is->list

  # is.list(x1)
  r->is->list($x1)

=head2 is->matrix

  # is.matrix(x1)
  r->is->matrix($x1)

=head2 is->na

  # is.na(x1)
  r->is->na($x1)

=head2 is->nan

  # is.nan(x1)
  r->is->nan($x1)

=head2 is->null

  # is.null(x1)
  r->is->null($x1)

=head2 is->numeric

  # is.numeric(x1)
  r->is->numeric($x1)

=head2 is->double

  # is.double(x1)
  r->is->double($x1)

=head2 is->integer

  # is.integer(x1)
  r->is->integer($x1)

=head2 is->logical

  # is.logical(x1)
  r->is->logical($x1)

=head2 is->vector

  # is.vector(x1)
  r->is->vector($x1)

=head2 labels

  # labels(x1)
  r->labels($x1)

=head2 levels

  # levels(x1)
  r->levels($x1)
  
  # levels(x1) <- c("F", "M")
  r->levels($x1 => c_("F", "M"))

=head2 dim

  # dim(x1)
  r->dim($x1)
  
  # dim(x1) <- c(1, 2)
  r->dim($x1 => c_(1, 2))

=head2 names

  # names(x1)
  r->names($x1)

  # names(x1) <- c("n1", "n2")
  r->names($x1 =>  c_("n1", "n2"))

=head2 nlevels

  # nlevels(x1)
  r->nlevels($x1)

=head2 dimnames

  # dimnames(x1)
  r->dimnames($x1)
  
  # dimnames(x1) <- list(c("r1", "r2"), c("c1", "c2"))
  r->dimnames($x1 => list(c_("r1", "r2"), c_("c1", "c2")))

=head2 colnames

  # colnames(x1)
  r->colnames($x1)
  
  # colnames(x1) <- c("r1", "r2")
  r->colnames($x1 => c_("r1", "r2"))

=head2 rownames

  # rownames(x1)
  r->rownames($x1)
  
  # rownames(x1) <- c("r1", "r2")
  r->rownames($x1 => c_("r1", "r2"))

=head2 mode

  # mode(x1)
  r->mode($x1)
  
  # mode(x1) <- c("r1", "r2")
  r->mode($x1 => c_("r1", "r2"))

=head2 str

  # str(x1)
  r->str($x1)

=head2 typeof

  # typeof(x1)
  r->typeof($x1);
