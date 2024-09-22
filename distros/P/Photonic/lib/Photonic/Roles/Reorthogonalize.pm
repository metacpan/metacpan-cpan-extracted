package Photonic::Roles::Reorthogonalize;
$Photonic::Roles::Reorthogonalize::VERSION = '0.022';

=encoding UTF-8

=head1 NAME

Photonic::Roles::ReorthogonalizeC

=head1 VERSION

version 0.022

=head1 COPYRIGHT NOTICE

Photonic - A perl package for calculations on photonics and
metamaterials.

Copyright (C) 2016 by W. Luis Mochán

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 1, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA  02110-1301 USA

    mochan@fis.unam.mx

    Instituto de Ciencias Físicas, UNAM
    Apartado Postal 48-3
    62251 Cuernavaca, Morelos
    México

=head1 SYNOPSIS

    package 'Mypackage';
    with 'Photonic::Roles::Reorthogonalize';
    .
    .
    .
    $self->_checkorthogonalize;

=head1 DESCRIPTION

Role consumed by AllH objects to be used in a Photonic
calculation. Estimates orthogonalization errors and makes a full
reorthogonalization of Haydock states when required. This version works
for both Hermitian operators with real Haydock coefficients, and
for non Hermitian operators with complex Haydock coefficients.

=head1 ATTRIBUTES

=over 4

=item * complexCoeffs

=item * previous_W, current_W, next_W

Vector of overlap estimates.

=item * accuracy

Desired accuracy. Default: machine precision.

=item * noise

Estimate of numerical noise added by each iteration. Default: machine
precision.

=item * normOp

Estimate of the norm of the operator. Default: 1.

=item * fullorthogonalize_N

Required number of reorthogonalizations.

=item * orthogonalizations

Actual number of orthogonalizations performed.

=back

=head1 INTERNAL ATTRIBUTES

=over 4

=item * _justorthogonalized

Flags a recent orthogonalization.

=back

=head1 INTERNAL METHODS

=over 4

=item * _build_next_W

=item * _fullorthogonalize_indeed

=item * _checkorthogonalize

=item * _sign

Only used with real coefficients.

=item * _arg

Only used with complex coefficients.

=back

=cut

use Machine::Epsilon;
use PDL::Lite;
use PDL::NiceSlice;
use Photonic::Utils qw(top_slice);
use Moo::Role;

requires 'complexCoeffs';

has 'previous_W' =>(is=>'ro',
     writer=>'_previous_W', lazy=>1, init_arg=>undef,
     default=>sub{PDL->pdl([0])},
     documentation=>"Row of error matrix"
);
has 'current_W' =>(is=>'ro',
     writer=>'_current_W', lazy=>1, init_arg=>undef,
     default=>sub{PDL->pdl([0])},
     documentation=>"Row of error matrix"
);
has 'next_W' =>(is=>'ro',
     writer=>'_next_W', lazy=>1, init_arg=>undef,
     builder=>'_build_next_W',
     documentation=>"Next row of error matrix"
);
has 'accuracy'=>(is=>'ro', default=>sub{machine_epsilon()},
                documentation=>'Desired or machine precision');
has 'noise'=>(is=>'ro', default=>sub{machine_epsilon()},
    documentation=>'Noise introduced each iteration to overlap matrix');
has 'normOp'=>(is=>'ro', required=>1, default=>1,
	       documentation=>'Estimate of operator norm');
has fullorthogonalize_N=>(is=>'ro', init_arg=>undef, default=>0,
			  writer=>'_fullorthogonalize_N',
			  documentation=>'# desired reorthogonalizations');
has 'orthogonalizations'=>(is=>'ro', init_arg=>undef, default=>0,
			   writer=>'_orthogonalizations');
has '_justorthogonalized'=>(
    is=>'ro', init_arg=>undef, default=>0,
    writer=>'_write_justorthogonalized',
    documentation=>'Flag I just orthogonalized');

sub _build_next_W {
    my $self=shift;
    my $g_n=$self->current_g;
    return PDL->pdl([$g_n]);
}

sub _fullorthogonalize_indeed {
    my ($self, $psi, $gs)=@_;
    return $psi unless my $fo_N = $self->fullorthogonalize_N;
    $self->_fullorthogonalize_N($fo_N-1);
    $self->_orthogonalizations($self->orthogonalizations+1);
    $self->_write_justorthogonalized(1);
    my $it=$self->states;
    $psi=$psi->copy; # no mutate inputs
    for my $n (0..$gs->dim(-1)-1) {
	my $s=top_slice($it, "($n)");
	$psi-=top_slice($gs, "($n)")*$self->innerProduct($s, $psi)*$s;
    }
    return $psi;
};

# returns the number of states to unwind
sub _checkorthogonalize {
    my ($self, $n, $a, $b, $c, $b_np1, $g_n, $g_np1)=@_;
    return 0 if $self->fullorthogonalize_N; #already orthogonalizing
    if($self->_justorthogonalized){
	$self->_write_justorthogonalized(0);
	my $current_W=PDL->ones($n)*$self->noise;
	my $next_W=PDL->ones($n+1)*$self->noise;
	$current_W->(-1).=$g_n;
	$next_W->(-1).=$g_np1;
	$self->_current_W($current_W);
	$self->_next_W($next_W);
	return 0;
    }
    $self->_previous_W(my $previous_W=$self->current_W);
    $self->_current_W(my $current_W=$self->next_W);
    my $next_W=PDL->zeroes(
        $self->complexCoeffs ? PDL::cdouble() : PDL::double(),
        $n+1
    );
    if($n>=2){
	$next_W->(0:-3) .= $b->(1:-1)*$current_W->(1:-1)
	    + ($a->(0:-2)-$a->(($n-1)))*$current_W->(0:-2)
	    - $c->(($n-1))*$previous_W;
	$next_W->(1:-3)+=$c->(1:-2)*$current_W->(0:-3) if ($n>=3);
	my $diff;
	if ($self->complexCoeffs) {
	    my $s=$next_W->(0:-3)->copy;
	    $s->where(my $indexes=(my $a=$s->abs)==0).=1;
	    $a->where($indexes).=1;
	    $diff=$s/$a; # arg
	} else {
	    $diff=2*($next_W->(0:-3)>=0)-1; # sign
	}
	$next_W->(0:-3) .= ($next_W->(0:-3)+($diff*2*$self->normOp*$self->noise))/$b_np1;
    }
    $next_W->((-2)) .= $self->noise;
    $next_W->((-1)) .= $g_np1;
    $self->_next_W($next_W);
    return 0 unless $n>=2;
    my $max=$next_W->(0:-2)->abs->maximum;
    return 0 unless $max > sqrt($self->accuracy);
    #recalculate the last $ortho states with full reorthogonalization
    my $orthos=$n>3 ? 2 : 1; #number of reorthogonalizations
    $self->_fullorthogonalize_N($orthos); #$ortho states, but check until that+1 state
    $orthos;
}

no Moo::Role;

1;
