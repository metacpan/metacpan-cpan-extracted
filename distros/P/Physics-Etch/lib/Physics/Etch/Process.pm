package Physics::Etch::Process;

use strict;
use warnings;
use Carp qw(croak);

use Physics::Etch::Material;
use Physics::Etch::Etchant;

our $VERSION = '0.01';

# Boltzmann constant in eV/K (used by Arrhenius scaling in subclasses).
use constant KB_EV => 8.617333262e-5;

# ---------------------------------------------------------------------------
# Construction
# ---------------------------------------------------------------------------
#
# Shared attributes handled here:
#   target       Material (required)      - the film being etched
#   etchant      Etchant  (required)
#   thickness    nm                       - film thickness (also -> target)
#   feature_cd   nm                       - mask opening / line width (profile)
#   mask         Material                 - masking layer (optional)
#   mask_thickness nm                     - defaults to mask->thickness
#   substrate    Material                 - layer under the film (optional)
#   temperature  degC
#   time         min (optional explicit etch time)
#   overetch     fraction (default 0.20)
#   uniformity   fraction, +/- (default 0)
#   sel_mask     selectivity target:mask (optional)
#   sel_substrate selectivity target:substrate (optional)

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;

    $self->{target}  = $self->_as_material( $args{target} )
        // croak "$class: 'target' material is required";
    $self->{etchant} = $self->_as_etchant( $args{etchant}, $self->default_process_key )
        // croak "$class: 'etchant' is required";

    # thickness convenience: push into the target material
    if ( defined $args{thickness} ) {
        $self->{target}->thickness( $args{thickness} );
    }

    $self->{feature_cd}    = $args{feature_cd};
    $self->{mask}          = $self->_as_material( $args{mask} );
    $self->{substrate}     = $self->_as_material( $args{substrate} );
    $self->{mask_thickness} = defined $args{mask_thickness}
        ? $args{mask_thickness}
        : ( $self->{mask} ? $self->{mask}->thickness : undef );

    $self->{temperature}   = $args{temperature};
    $self->{time}          = $args{time};
    $self->{overetch}      = defined $args{overetch}   ? $args{overetch}   : 0.20;
    $self->{uniformity}    = defined $args{uniformity} ? $args{uniformity} : 0.0;
    $self->{sel_mask}      = $args{sel_mask};
    $self->{sel_substrate} = $args{sel_substrate};

    return $self;
}

# ---------------------------------------------------------------------------
# Accessors
# ---------------------------------------------------------------------------
for my $attr (
    qw( target etchant feature_cd mask substrate mask_thickness
        temperature overetch uniformity sel_mask sel_substrate )
    )
{
    no strict 'refs';
    *{$attr} = sub {
        my ( $self, $v ) = @_;
        $self->{$attr} = $v if @_ > 1;
        return $self->{$attr};
    };
}

sub thickness { $_[0]->{target}->thickness }

# ---------------------------------------------------------------------------
# Abstract hooks - subclasses MUST implement
# ---------------------------------------------------------------------------
sub process_type      { croak 'process_type() must be implemented by subclass' }
sub default_process_key { 'wet' }                 # 'wet' | 'dry'
sub vertical_rate     { croak 'vertical_rate() must be implemented by subclass' }
sub lateral_rate      { croak 'lateral_rate() must be implemented by subclass' }
sub _conditions_lines { return () }               # subclass adds recipe knobs

# ---------------------------------------------------------------------------
# Kinetics / anisotropy
# ---------------------------------------------------------------------------
sub anisotropy {
    my ($self) = @_;
    my $v = $self->vertical_rate;
    return 0 if !$v;
    my $a = 1 - $self->lateral_rate / $v;
    $a = 0 if $a < 0;
    $a = 1 if $a > 1;
    return $a;
}

# time (min) to remove the full film thickness
sub time_to_clear {
    my ($self) = @_;
    my $h = $self->thickness;
    my $v = $self->vertical_rate;
    return undef unless defined $h && $v;
    return $h / $v;
}

# actual etch time used: explicit if given, else clear-time * (1+overetch)
sub etch_time {
    my ($self) = @_;
    return $self->{time} if defined $self->{time};
    my $tc = $self->time_to_clear;
    return undef unless defined $tc;
    return $tc * ( 1 + $self->{overetch} );
}

sub etch_depth {
    my ( $self, $t ) = @_;
    $t = $self->etch_time unless defined $t;
    return $self->vertical_rate * $t;
}

# lateral penetration under the mask at the film surface (per side)
sub undercut {
    my ( $self, $t ) = @_;
    $t = $self->etch_time unless defined $t;
    return $self->lateral_rate * $t;
}

sub is_cleared {
    my ( $self, $t ) = @_;
    my $h = $self->thickness;
    return undef unless defined $h;
    return $self->etch_depth($t) >= $h ? 1 : 0;
}

# ---------------------------------------------------------------------------
# Profile geometry
# ---------------------------------------------------------------------------
sub profile {
    my ( $self, $t ) = @_;
    $t = $self->etch_time unless defined $t;
    croak 'profile() needs an etch time (set thickness/overetch or time)'
        unless defined $t;

    my $h        = $self->thickness;
    my $depth    = $self->etch_depth($t);
    my $film_d   = defined $h && $depth > $h ? $h : $depth;    # capped at film
    my $under    = $self->undercut($t);
    my $w        = $self->feature_cd;

    my %p = (
        time           => $t,
        etch_depth     => $depth,
        film_depth     => $film_d,
        undercut       => $under,
        anisotropy     => $self->anisotropy,
        cleared        => ( defined $h ? ( $depth >= $h ? 1 : 0 ) : undef ),
    );

    if ( defined $w ) {
        my $top    = $w + 2 * $under;
        my $bot    = $w + 2 * ( $under > $film_d ? $under - $film_d : 0 );
        # atan2(depth, undercut): -> 90 deg (vertical) as undercut -> 0
        my $angle  = _deg( atan2( $film_d, $under ) );
        $p{feature_cd}     = $w;
        $p{top_width}      = $top;
        $p{bottom_width}   = $bot;
        $p{etch_bias}      = 2 * $under;             # total CD gain
        $p{sidewall_angle} = $angle;                 # degrees from horizontal
        $p{aspect_ratio}   = $w > 0 ? $film_d / $w : undef;
    }

    return \%p;
}

# ---------------------------------------------------------------------------
# Selectivity, mask survival, substrate over-etch
# ---------------------------------------------------------------------------
sub mask_etch_rate {
    my ($self) = @_;
    my $s = $self->{sel_mask};
    return undef unless defined $s && $s > 0;
    return $self->vertical_rate / $s;
}

sub mask_loss {
    my ( $self, $t ) = @_;
    $t = $self->etch_time unless defined $t;
    my $r = $self->mask_etch_rate;
    return undef unless defined $r;
    return $r * $t;
}

sub mask_survives {
    my ( $self, $t ) = @_;
    my $loss = $self->mask_loss($t);
    my $mt   = $self->{mask_thickness};
    return undef unless defined $loss && defined $mt;
    return $loss < $mt ? 1 : 0;
}

sub substrate_etch_rate {
    my ($self) = @_;
    my $s = $self->{sel_substrate};
    return undef unless defined $s && $s > 0;
    return $self->vertical_rate / $s;
}

# how far the etch cuts into the substrate during over-etch
sub substrate_overetch {
    my ( $self, $t ) = @_;
    $t = $self->etch_time unless defined $t;
    my $tc = $self->time_to_clear;
    my $r  = $self->substrate_etch_rate;
    return undef unless defined $tc && defined $r;
    my $ot = $t - $tc;
    return $ot > 0 ? $r * $ot : 0;
}

# ---------------------------------------------------------------------------
# Across-wafer uniformity
# ---------------------------------------------------------------------------
sub uniformity_report {
    my ($self) = @_;
    my $u = $self->{uniformity} || 0;
    my $v = $self->vertical_rate;
    my $h = $self->thickness;
    my %r = ( uniformity => $u, rate_nominal => $v );
    $r{rate_min} = $v * ( 1 - $u );
    $r{rate_max} = $v * ( 1 + $u );
    if ( defined $h && $r{rate_min} > 0 ) {
        $r{clear_fast} = $h / $r{rate_max};
        $r{clear_slow} = $h / $r{rate_min};
        $r{overetch_to_clear_all} =
            $u < 1 ? ( ( 1 + $u ) / ( 1 - $u ) - 1 ) : undef;
    }
    return \%r;
}

# ---------------------------------------------------------------------------
# Reporting
# ---------------------------------------------------------------------------
sub report {
    my ($self) = @_;
    my $t   = $self->etch_time;
    my @out;

    push @out, '=' x 66;
    push @out, sprintf( '%s ETCH  --  %s', uc $self->process_type,
        $self->target->label );
    push @out, '=' x 66;

    push @out, sprintf( '  Etchant      : %s  [%s]',
        $self->etchant->composition, $self->etchant->mechanism );
    push @out, sprintf( '  Film to etch : %s nm',
        _num( $self->thickness ) ) if defined $self->thickness;

    # subclass conditions
    my @cond = $self->_conditions_lines;
    push @out, @cond if @cond;

    push @out, '  ' . '-' x 62;
    push @out, sprintf( '  Vertical rate  : %s nm/min', _num( $self->vertical_rate ) );
    push @out, sprintf( '  Lateral rate   : %s nm/min', _num( $self->lateral_rate ) );
    push @out, sprintf( '  Anisotropy A   : %.3f  (1 = perfectly directional)',
        $self->anisotropy );

    if ( defined $self->{sel_mask} && $self->mask ) {
        push @out, sprintf( '  Selectivity/mask (%s)      : %s : 1',
            $self->mask->pretty, _num( $self->{sel_mask} ) );
    }
    if ( defined $self->{sel_substrate} && $self->substrate ) {
        push @out, sprintf( '  Selectivity/substrate (%s) : %s : 1',
            $self->substrate->pretty, _num( $self->{sel_substrate} ) );
    }

    push @out, '  ' . '-' x 62;
    if ( defined( my $tc = $self->time_to_clear ) ) {
        push @out, sprintf( '  Time to clear  : %.2f min', $tc );
    }
    if ( defined $t ) {
        push @out, sprintf( '  Etch time      : %.2f min  (over-etch %.0f%%)',
            $t, ( $self->{overetch} // 0 ) * 100 );
        push @out, sprintf( '  Etch depth     : %s nm', _num( $self->etch_depth($t) ) );
    }

    # profile
    if ( defined $self->feature_cd && defined $t ) {
        my $p = $self->profile($t);
        push @out, '  ' . '-' x 62;
        push @out, sprintf( '  Feature (mask CD)   : %s nm', _num( $p->{feature_cd} ) );
        push @out, sprintf( '  Undercut (per side) : %s nm', _num( $p->{undercut} ) );
        push @out, sprintf( '  Etch bias (CD gain) : %s nm', _num( $p->{etch_bias} ) );
        push @out, sprintf( '  Top / bottom width  : %s / %s nm',
            _num( $p->{top_width} ), _num( $p->{bottom_width} ) );
        push @out, sprintf( '  Sidewall angle      : %.1f deg', $p->{sidewall_angle} );
        push @out, sprintf( '  Aspect ratio        : %.2f : 1', $p->{aspect_ratio} )
            if defined $p->{aspect_ratio};
    }

    # mask survival
    if ( defined( my $ml = $self->mask_loss($t) ) ) {
        push @out, '  ' . '-' x 62;
        push @out, sprintf( '  Mask etch rate : %s nm/min', _num( $self->mask_etch_rate ) );
        push @out, sprintf( '  Mask loss      : %s nm', _num($ml) );
        if ( defined( my $surv = $self->mask_survives($t) ) ) {
            push @out, sprintf( '  Mask remaining : %s nm  (%s)',
                _num( $self->{mask_thickness} - $ml ),
                $surv ? 'OK' : 'MASK CONSUMED!' );
        }
    }

    # substrate over-etch
    if ( defined( my $so = $self->substrate_overetch($t) ) ) {
        push @out, sprintf( '  Substrate over-etch (%s) : %s nm',
            $self->substrate->pretty, _num($so) );
    }

    # uniformity
    if ( $self->{uniformity} ) {
        my $u = $self->uniformity_report;
        push @out, '  ' . '-' x 62;
        push @out, sprintf( '  Uniformity     : +/- %.0f%%', $u->{uniformity} * 100 );
        if ( defined $u->{clear_fast} ) {
            push @out, sprintf( '  Clear time span: %.2f - %.2f min',
                $u->{clear_fast}, $u->{clear_slow} );
            push @out, sprintf( '  Min over-etch to clear whole wafer : %.0f%%',
                $u->{overetch_to_clear_all} * 100 )
                if defined $u->{overetch_to_clear_all};
        }
    }

    push @out, '=' x 66;
    return join( "\n", @out ) . "\n";
}

# ---------------------------------------------------------------------------
# Coercion helpers
# ---------------------------------------------------------------------------
sub _as_material {
    my ( $self, $m ) = @_;
    return undef unless defined $m;
    return $m if ref $m && $m->isa('Physics::Etch::Material');
    return Physics::Etch::Material->new( name => $m ) unless ref $m;
    return Physics::Etch::Material->new(%$m) if ref $m eq 'HASH';
    croak 'material must be a Physics::Etch::Material, name, or hashref';
}

sub _as_etchant {
    my ( $self, $e, $type ) = @_;
    return undef unless defined $e;
    return $e if ref $e && $e->isa('Physics::Etch::Etchant');
    return Physics::Etch::Etchant->new( name => $e, type => $type )
        unless ref $e;
    return Physics::Etch::Etchant->new( type => $type, %$e ) if ref $e eq 'HASH';
    croak 'etchant must be a Physics::Etch::Etchant, name, or hashref';
}

# ---------------------------------------------------------------------------
# Formatting helpers
# ---------------------------------------------------------------------------
sub _deg { $_[0] * 180 / 3.14159265358979 }

sub _num {
    my ($n) = @_;
    return 'n/a' unless defined $n;
    my $a = abs $n;
    return sprintf( '%.3g', $n ) if $a != 0 && ( $a < 0.1 || $a >= 100000 );
    return sprintf( '%.0f', $n )  if $a >= 100;
    return sprintf( '%.1f', $n )  if $a >= 10;
    return sprintf( '%.2f', $n );
}

1;

__END__

=head1 NAME

Physics::Etch::Process - base class for wet and dry etch process models

=head1 DESCRIPTION

Common machinery shared by L<Physics::Etch::WetEtch> and
L<Physics::Etch::DryEtch>: film/mask/substrate bookkeeping, profile geometry
(depth, undercut, etch bias, sidewall angle, aspect ratio), selectivity and
mask-survival calculations, across-wafer uniformity, and a formatted
C<report()>.

Subclasses must implement C<process_type>, C<vertical_rate> and
C<lateral_rate>, and may add recipe knobs to the report via
C<_conditions_lines>.

=head1 KEY METHODS

=over 4

=item C<time_to_clear> / C<etch_time> / C<etch_depth($t)> / C<undercut($t)>

=item C<anisotropy>  ( 1 - lateral/vertical )

=item C<profile($t)>  hashref with top/bottom width, sidewall angle, aspect ratio

=item C<mask_loss($t)> / C<mask_survives($t)> / C<substrate_overetch($t)>

=item C<uniformity_report> / C<report>

=back

=cut
