package Statistics::Lmoments;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT %EXPORT_TAGS @EXPORT_OK
	    @distributions %parameters);

$VERSION = '0.04';

@distributions = ('EXP',#     Exponential distribution
		  'GAM',#     Gamma distribution
		  'GEV',#     Generalized extreme-value distribution
		  'GLO',#     Generalized logistic distribution
		  'GNO',#     Generalized Normal (lognormal) distribution
		  'GPA',#     Generalized Pareto distribution
		  'GUM',#     Gumbel distribution
		  'KAP',#     Kappa distribution
		  'NOR',#     Normal distribution
		  'PE3',#     Pearson type III distribution
		  'WAK' #     Wakeby distribution
		  );

%parameters = ('EXP' => ['xi','alpha'],
	       'GAM' => ['alpha','beta'],
	       'GEV' => ['xi','alpha','k'],
	       'GLO' => ['xi','alpha','k'],
	       'GNO' => ['xi','alpha','k'],
	       'GPA' => ['xi','alpha','k'],
	       'GUM' => ['xi','alpha'],
	       'KAP' => ['xi','alpha','k','h'],
	       'NOR' => ['mu','sigma'],
	       'PE3' => ['mu','sigma','gamma'],
	       'WAK' => ['xi','alpha','beta','gamma','delta']
	       );


require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw();

%EXPORT_TAGS = (all  => [ qw ( @distributions %parameters &sam &lrm &pel &cdf &qua &analysis ) ]);
@EXPORT_OK = qw(@distributions %parameters &sam &lrm &pel &cdf &qua &analysis);

bootstrap Statistics::Lmoments $VERSION;

=pod

=head1 NAME

Statistics::Lmoments

=head1 SYNOPSIS

use Statistics::Lmoments qw(:all);

    my @x = (..data here..);

# data needs to be sorted from smallest to largest

    @x = sort {$a<=>$b} @x;

# calculate the "unbiased" first 5 L-moments

    $xmom = sam('lmu',\@x, 5);

    foreach (@distributions) {
        next if /^KAP/;
        my $para = pel($_,$xmom);
    #   @$para is now the estimated parameter vector
    #   for the specified distribution 
        my $x = 100;
        my $F = cdf($_,$x,$para);
    #   $F is now the value of the cdf at 100 for this distribution
    }

=head1 DESCRIPTION

This module is a thin wrapper around J. R. M. Hosking's FORTRAN library.
For more information please see lmoments.ps in this distribution.

=head1 METHODS

=head2 sam

=cut

sub sam {
    my($method,$x,$nmom,$a,$b,$kind) = @_;
    my $xmom;
  SWITCH: {
      if ($method =~ /^lmr/i) { $a = 0 unless defined $a; 
			       $b = 0 unless defined $b; 
			       $xmom = csamlmr($x,$#$x+1,$nmom,$a,$b); 
			   }
      if ($method =~ /^lmu/i) { $xmom = csamlmu($x,$#$x+1,$nmom); }
      if ($method =~ /^pwm/i) { $a = 0 unless defined $a; 
			       $b = 0 unless defined $b; 
			       $kind = 1 unless defined $kind; 
			       $xmom = csampwm($x,$#$x+1,$nmom,$a,$b,$kind);
			   }
  }
    return $xmom;
}

=pod

=head2 lmr

=cut

sub lmr {
    my($distr,$para,$n) = @_;
    croak("unknown distribution: $distr\n") 
	unless defined $parameters{$distr};
    croak("parameters for $distr are: @{$parameters{$distr}}") 
	unless $#$para == $#{$parameters{$distr}};
    $_ = $distr;
    my $xmom;
  SWITCH: {
      if (/^EXP/i) { $xmom = clmrexp($para); }
      if (/^GAM/i) { $xmom = clmrgam($para); }
      if (/^GEV/i) { $xmom = clmrgev($para); }
      if (/^GLO/i) { $xmom = clmrglo($para); }
      if (/^GNO/i) { $xmom = clmrgno($para); }
      if (/^GPA/i) { $xmom = clmrgpa($para); }
      if (/^GUM/i) { $xmom = clmrgum($para); }
      if (/^KAP/i) { $xmom = clmrkap($para); }
      if (/^NOR/i) { $xmom = clmrnor($para); }
      if (/^PE3/i) { $xmom = clmrpe3($para); }
      if (/^WAK/i) { $xmom = clmrwak($para); }
  }
    return $xmom;
}

=pod

=head2 pel

=cut

sub pel {
    my($distr,$xmom) = @_;
    croak("unknown distribution: $distr\n") 
	unless defined $parameters{$distr};
    croak("need at least ",$#{$parameters{$distr}}+1," L-Moment ratios") 
	if $#$xmom < $#{$parameters{$distr}};
    $_ = $distr;
    my $para;
    my $ifail = 0;
  SWITCH: {
      if (/^EXP/i) { $para = cpelexp($xmom); }
      if (/^GAM/i) { $para = cpelgam($xmom); }
      if (/^GEV/i) { $para = cpelgev($xmom); }
      if (/^GLO/i) { $para = cpelglo($xmom); }
      if (/^GNO/i) { $para = cpelgno($xmom); }
      if (/^GPA/i) { $para = cpelgpa($xmom); }
      if (/^GUM/i) { $para = cpelgum($xmom); }
      if (/^KAP/i) { $para = cpelkap($xmom); $ifail = pop @{$para}; }
      if (/^NOR/i) { $para = cpelnor($xmom); }
      if (/^PE3/i) { $para = cpelpe3($xmom); }
      if (/^WAK/i) { $para = cpelwak($xmom); $ifail = pop @{$para}; }
  }
    croak("subroutine failed with code IFAIL=$ifail\n") unless $ifail == 0;
    return $para;
}

=pod

=head2 cdf

=cut

sub cdf {
    my($distr,$x,$para) = @_;
    croak("unknown distribution: $distr\n") 
	unless defined $parameters{$distr};
    croak("parameters for $distr are: @{$parameters{$distr}}") 
	unless $#$para == $#{$parameters{$distr}};
    $_ = $distr;
  SWITCH: {
      if (/^EXP/i) { return ccdfexp($x, $para); }
      if (/^GAM/i) { return ccdfgam($x, $para); }
      if (/^GEV/i) { return ccdfgev($x, $para); }
      if (/^GLO/i) { return ccdfglo($x, $para); }
      if (/^GNO/i) { return ccdfgno($x, $para); }
      if (/^GPA/i) { return ccdfgpa($x, $para); }
      if (/^GUM/i) { return ccdfgum($x, $para); }
      if (/^KAP/i) { return ccdfkap($x, $para); }
      if (/^NOR/i) { return ccdfnor($x, $para); }
      if (/^PE3/i) { return ccdfpe3($x, $para); }
      if (/^WAK/i) { return ccdfwak($x, $para); }
  }
}

=pod

=head2 cua

=cut

sub qua {
    my($distr,$F,$para) = @_;
    croak("unknown distribution: $distr\n") 
	unless defined $parameters{$distr};
    croak("parameters for $distr are: @{$parameters{$distr}}") 
	unless $#$para == $#{$parameters{$distr}};
    $_ = $distr;
  SWITCH: {
      if (/^EXP/i) { return cquaexp($F, $para); }
      if (/^GAM/i) { return cquagam($F, $para); }
      if (/^GEV/i) { return cquagev($F, $para); }
      if (/^GLO/i) { return cquaglo($F, $para); }
      if (/^GNO/i) { return cquagno($F, $para); }
      if (/^GPA/i) { return cquagpa($F, $para); }
      if (/^GUM/i) { return cquagum($F, $para); }
      if (/^KAP/i) { return cquakap($F, $para); }
      if (/^NOR/i) { return cquanor($F, $para); }
      if (/^PE3/i) { return cquape3($F, $para); }
      if (/^WAK/i) { return cquawak($F, $para); }
  }
}

=pod

=head2 analysis

=cut

sub analysis {
    my($distr,$data,$pp_a,%options) = @_;
    croak "data has to be a reference to a list or to a lol\n" unless ref($data) eq 'ARRAY';
    my @x; # observations
    if (ref($data->[0])) { # to accommodate data in struct [[year,hq],[year,hq],...]
	for my $i (0..$#$data) {
	    push @x, $data->[$i]->[1];
	}
    } else {
	for my $i (0..$#$data) {
	    push @x, $data->[$i];
	}
    }
    @x = sort {$a<=>$b} @x;
    $pp_a = 0 unless defined $pp_a;
    my $sam = 'lmu';
    $sam = $options{sam} if $options{sam};
    my $xmom = &Statistics::Lmoments::sam($sam, \@x, 5);
    my $para = &Statistics::Lmoments::pel($distr, $xmom);
    my $pp; # probability paper
    @x = sort {$b<=>$a} @x;
    for my $i (0..$#x){
	my $p = ($i+1 - $pp_a)/($#x+1 + 1 - 2 * $pp_a);
	$pp->[$i]->[0] = $x[$i];
	$pp->[$i]->[1] = Statistics::Lmoments::qua($distr, 1-$p, $para);
    }
    return $pp;
}

=pod
    
=head1 AUTHOR

Ari Jolma L<https://github.com/ajolma>

=head1 REPOSITORY

L<https://github.com/ajolma/Statistics-Lmoments>

=cut

1;
__END__
