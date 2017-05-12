package Statistics::Cook;
use Modern::Perl;
use Data::Dumper;
use List::Util qw/sum/;
use Carp;
use Moo;
use Types::Standard qw/Str Num Int ArrayRef/;

our $VERSION = '0.0.6'; # VERSION
# ABSTRACT: Statistics::Cook - calculate cook distance of Least squares line fit



has x => (
  is => 'rw',
  isa => ArrayRef,
  lazy => 1,
  default => sub { [] },
  trigger => 1,
);


has y => (
  is => 'rw',
  isa => ArrayRef,
  default => sub { [] },
  lazy => 1,
  trigger => 1,
);


has weight => (
  is => 'rw',
  isa => ArrayRef
);


has slope => (
  is => 'rw',
  isa => Num,
);


has intercept=> (
  is => 'rw',
  isa => Num,
);


has regress_done => (
  is => 'rw',
  isa => Int,
  default => 0,
  lazy => 1,
);



sub _trigger_x {
  shift->regress_done(0);
}

sub _trigger_y {
  shift->regress_done(0);
}


sub regress {
  my $self = shift;
  my ($x, $y) = ($self->x, $self->y);
  confess "have not got data or x y length is not same" unless(@$x and @$y and @$x == @$y);
  my $sums = $self->computeSums;
  my $sqdevx = $sums->{xx} - $sums->{x} ** 2 / scalar(@$x);
  if ($sqdevx != 0) {
    my $sqdevy = $sums->{yy} - $sums->{y} ** 2 / scalar(@$y);
    my $sqdevxy = $sums->{xy} - $sums->{x} * $sums->{y} / scalar(@$x);
    my $slope = $sqdevxy / $sqdevx;
    my $intercept = ($sums->{y} - $slope * $sums->{x}) / @$x;
    $self->slope($slope);
    $self->intercept( $intercept);
    $self->regress_done(1);
    return ($intercept, $slope);
  } else {
    confess "Can't fit line when x values are all equal";
  }
}


sub computeSums {
  my $self = shift;
  my @x = @{$self->x};
  my @y = @{$self->y};
  my ($sums, @weights);
  if (defined (my $weight = $self->weight)) {
    confess "weights does not have same length with x" unless (@$weight == @x);
    @weights = @$weight;
  } else {
    @weights = (1) x scalar(@x);
  }
  for my $i (0..$#x) {
    my $w = $weights[$i];
    $sums->{x} += $w * $x[$i];
    $sums->{y} += $w * $y[$i];
    $sums->{xx} += $w * $x[$i] ** 2;
    $sums->{yy} += $w * $y[$i] ** 2;
    $sums->{xy} += $w * $x[$i] * $y[$i];
  }
  return $sums;
}


sub coefficients {
  my $self = shift;
  if ($self->regress_done) {
    return ($self->intercept, $self->slope);
  } else {
    return $self->regress;
  }
}


sub fitted {
  my $self = shift;
  if ($self->regress_done) {
    return map {$self->intercept + $self->slope * $_ } @{$self->x};
  } else {
    my ($a, $b) = $self->regress;
    return map {$a + $b * $_} @{$self->x};
  }
}


sub residuals {
  my $self = shift;
  my @y = @{$self->y};
  my @yf = $self->fitted;
  return map { $y[$_] - $yf[$_] } 0..$#y;
}


sub cooks_distance {
  my ($self, @cooks) = shift;
  my @yr = $self->residuals;
  my @y = @{$self->y};
  my @x = @{$self->x};
  my $statis = Statistics::Cook->new();
  for my $i (0..$#y) {
    my @xi = @x;
    my @yi = @y;
    splice(@xi, $i, 1);
    splice(@yi, $i, 1);
    $statis->x(\@xi);
    $statis->y(\@yi);
    my ($a, $b) = $statis->coefficients;
    my @yf_new = map {$a + $b * $_ } @x;
    my @yf = $self->fitted;
    my ($sum1, $sum2) = (0, 0);
    for my $j (0..$#yf) {
      $sum1 += ($yf[$j] - $yf_new[$j]) ** 2;
      $sum2 += $yr[$j] ** 2;
    }
    my $cook = $sum1 * (@y - 2) / $sum2 / 2;
    push @cooks, $cook;
  }
  return @cooks;
}


sub N {
  my ($self, $num, $N) = @_;
  $N ||= 50;
  my @nums = sort { $b <=> $a } @$num;
  my $sum = sum(@nums);
  my $tmp = 0;
  for my $i (0..$#nums) {
    $tmp += $nums[$i];
    return ($nums[$i], $i+1) if ($tmp > $sum * $N / 100);
  }
}


sub mean {
  my $self = shift;
  my @arr = ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;
  my $sum = 0;
  $sum += $_ for @arr;
  return $sum / @arr;
}


sub var {
  my $self = shift;
  my @arr = ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;
  my $m = $self->mean(@arr);
  my $sum = 0;
  $sum += ($_ - $m) ** 2 for (@arr);
  return $sum / $#arr;
}


sub sd {
  my $self = shift;
  my @arr = ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;
  my $var = $self->var(@arr);
  return sqrt($var);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statistics::Cook - Statistics::Cook - calculate cook distance of Least squares line fit

=head1 VERSION

version 0.0.6

=head1 SYNOPSIS

  use Statistics::Cook;
  my @x = qw/1 2 3 4 5 6/;
  my @y = qw/1 2.1 3.2 4 7 6/;
  my $sc = Statistics::Cook->new(x => \@x, y => \@y);
  ($intercept, $slope) = $sc->coefficients;
  my @predictedYs = $sc->fitted;
  my @residuals = $sc->residuals;
  my @cooks = $sc->cooks_distance;

=head1 DESCRIPTION

The Statistics::Cook module is used to calculate cook distance of Least squares line fit to
two-dimensional data (y = a + b * x). (This is also called linear regression.)
In addition to the slope and y-intercept, the module, the predicted y values and the
residuals of the y values. (See the METHODS section for a description of these statistics.)

The module accepts input data in separate x and y arrays. The optional weights are input in a separate array
The module is state-oriented and caches its results. you can call the other methods in any order
or call a method several times without invoking redundant calculations.

=head1 LIMITATIONS

The purpose of I write this module is that I could not find a module to calculate cook distance in CPAN,
Therefore I just realized this module with  a minimized function consists of least squares and cook distance

=head1 ATTRIBUTES

=head2 x

x coordinate that used to linear regression and cook distance, is a ArrayRef

=head2 y

y coordinate that used to linear regression and cook distance, is a ArrayRef

=head2 weight

weights that used to linear regression and cook distance, is a ArrayRef

=head2 slope

slope value of linear model

=head2 intercept

intercept of y in linear model

=head2 regress_done

the status whether has done linear regress

=head1 METHODS

The module is state-oriented and caches its results. Once you have done regress, you can call
the other methods in any order or call a method several times without invoking redundant calculations.

The regression fails if the x values are all the same. In this case, the module issues an error message

=head2 regress

Do the least squares line fit, but you don't need to call this method because it is invoked by the
other methods as needed,  you can call regress() at any time to get the status of the regression
for the current data.

=head2 computeSums

Computing some value that used by regress, that you usually need not use it.

=head2 coefficients

Return the slope and y intercept

=head2 fitted

Return the fitted y values

=head2 residuals

Return residuals of y values

=head2 cooks_distance

Calculate cook distance of linear model

=head2 N

default is get N50 of a ArrayRef
$self->N([1,2,3,4], 90), you will get N90
$self->N([1,2,3,4], 80), you will get N80

=head2 mean

mean value of an array

=head2 var

The variance of a set of samples

=head2 sd

The standard deviation of a set of samples

=head1 AUTHOR

Yan Xueqing <yanxueqing621@163.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yan Xueqing.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
