package Physics::Etch::Loading;

use strict;
use warnings;

our $VERSION = '0.01';

# ===========================================================================
# Etch loading and aspect-ratio-dependent-etch (ARDE / RIE-lag) models.
#
#   Macro loading (Mogab):  R/R0 = 1 / (1 + kappa * A_load)
#       A_load = total exposed etchable area on the wafer (cm^2)
#              = open_fraction * wafer_area
#   Micro loading:          local rate ~ 1 / (1 + k_micro * local_density)
#   ARDE / RIE lag:         f(AR) = 1 / (1 + AR / arde_length)
#       narrow (high aspect ratio) features etch slower and taper.
#
# Parameters (all tunable):
#   kappa        macro loading coefficient (1/cm^2)   default 0.01
#   k_micro      micro loading coefficient            default 0.5
#   arde_length  aspect ratio at which rate halves     default 8
#   lateral_arde exponent linking lateral ARDE to vertical (0..1) default 0.5
# ===========================================================================
sub new {
    my ( $class, %a ) = @_;
    return bless {
        kappa        => defined $a{kappa}        ? $a{kappa}        : 0.01,
        k_micro      => defined $a{k_micro}      ? $a{k_micro}      : 0.5,
        arde_length  => defined $a{arde_length}  ? $a{arde_length}  : 8,
        lateral_arde => defined $a{lateral_arde} ? $a{lateral_arde} : 0.5,
    }, $class;
}

for my $attr (qw( kappa k_micro arde_length lateral_arde )) {
    no strict 'refs';
    *{$attr} = sub {
        my ( $self, $v ) = @_;
        $self->{$attr} = $v if @_ > 1;
        return $self->{$attr};
    };
}

# --- Macro loading ---------------------------------------------------------
# rate multiplier (<= 1) for a total exposed area (cm^2)
sub macro_factor {
    my ( $self, $area_cm2 ) = @_;
    $area_cm2 = 0 if !defined $area_cm2 || $area_cm2 < 0;
    return 1 / ( 1 + $self->{kappa} * $area_cm2 );
}

# convenience: from open fraction + wafer area
sub macro_factor_from_fraction {
    my ( $self, $open_fraction, $wafer_area_cm2 ) = @_;
    return $self->macro_factor( $open_fraction * $wafer_area_cm2 );
}

# --- Micro loading ---------------------------------------------------------
# absolute local multiplier for a local open density (0..1)
sub micro_factor {
    my ( $self, $density ) = @_;
    $density = 0 unless defined $density;
    return 1 / ( 1 + $self->{k_micro} * $density );
}

# local rate relative to the mean-density rate (denser -> slower)
sub micro_relative {
    my ( $self, $density, $mean_density ) = @_;
    return $self->micro_factor($density)
        / ( $self->micro_factor($mean_density) || 1 );
}

# --- ARDE / RIE lag --------------------------------------------------------
# vertical rate multiplier vs aspect ratio (depth/width)
sub arde_factor {
    my ( $self, $aspect_ratio ) = @_;
    $aspect_ratio = 0 if !defined $aspect_ratio || $aspect_ratio < 0;
    return 1 / ( 1 + $aspect_ratio / ( $self->{arde_length} || 1e9 ) );
}

# lateral (radical) rate is less suppressed than vertical -> tapering
sub arde_lateral_factor {
    my ( $self, $aspect_ratio ) = @_;
    return $self->arde_factor($aspect_ratio)**$self->{lateral_arde};
}

# --- Estimate loading strength from chamber transport ----------------------
# longer gas residence -> more depletion -> stronger macro loading
sub from_chamber {
    my ( $class, $chamber, %a ) = @_;
    my $tau     = $chamber->residence_time_s // 0.02;
    my $tau_ref = $a{tau_ref} // 0.02;                  # s
    my $kappa0  = $a{kappa0}  // 0.01;
    return $class->new(
        kappa => $kappa0 * ( $tau_ref ? $tau / $tau_ref : 1 ),
        ( exists $a{k_micro}     ? ( k_micro     => $a{k_micro} )     : () ),
        ( exists $a{arde_length} ? ( arde_length => $a{arde_length} ) : () ),
    );
}

sub describe {
    my ($self) = @_;
    return sprintf(
        'Loading: kappa=%.4g /cm^2, k_micro=%.3g, ARDE length=%.3g (AR at half-rate)',
        $self->{kappa}, $self->{k_micro}, $self->{arde_length} );
}

1;

__END__

=head1 NAME

Physics::Etch::Loading - macro / micro loading and ARDE (RIE-lag) models

=head1 SYNOPSIS

    use Physics::Etch::Loading;

    my $load = Physics::Etch::Loading->new( kappa => 0.012, arde_length => 6 );

    # macro loading from a 25%-open pattern on a 300 cm^2 wafer
    my $macro = $load->macro_factor_from_fraction( 0.25, 300 );   # < 1

    # RIE lag: a feature at aspect ratio 5
    my $lag = $load->arde_factor( 5 );                            # < 1

    # or derive loading strength from chamber transport
    my $load2 = Physics::Etch::Loading->from_chamber( $chamber );

=head1 DESCRIPTION

Provides the three rate-modifying effects that couple pattern and reactor to
local etch behaviour:

=over 4

=item * B<Macro loading> - global rate falls as total exposed area rises
(Mogab's C<1/(1+kappa*A)>). Pair with L<Physics::Etch::Layout> open fraction
and L<Physics::Etch::Chamber> wafer area.

=item * B<Micro loading> - local rate depends on local pattern density.

=item * B<ARDE / RIE lag> - narrow, high-aspect-ratio features etch slower
(vertically) and taper, because lateral radical flux is less suppressed than
the directional ion flux.

=back

=cut
