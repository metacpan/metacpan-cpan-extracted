package Physics::Etch::DryEtch;

use strict;
use warnings;
use parent -norequire, 'Physics::Etch::Process';

use Physics::Etch::Process ();   # for KB_EV constant

our $VERSION = '0.01';

# Dry (plasma / RIE / ion) etch: directional, tunable anisotropy.
#
# Extra attributes:
#   rate         nm/min at nominal conditions   (required)
#   power        RF power, W          (optional)   power_nom  (default 200)
#   pressure     mTorr                (optional)   pressure_nom (default 20)
#   bias         DC self-bias, V ~ ion energy (opt) bias_nom  (default 200)
#   anisotropy   nominal A, 0..1      (default 0.90)
#   loading      rate multiplier for exposed-area loading (default 1.0)
#   Ea, ref_temp thermal term for hot dry etches (default Ea=0 -> no T effect)
#
# Rate model (each factor -> 1.0 when its knob is not supplied):
#   power_factor    = (power/power_nom)      ^ 0.8   (ion + radical flux)
#   pressure_factor = (pressure/pressure_nom)^ 0.3   (radical density)
#   bias_factor     = (bias/bias_nom)        ^ 0.5   (ion-energy enhancement)
#   Rv = rate * power_factor * pressure_factor * bias_factor * loading * arrhenius
#
# Anisotropy (higher pressure -> more lateral; higher bias -> more vertical):
#   A_eff  = 1 - (1 - A_nom) * (pressure/pressure_nom) * (bias_nom/bias)
#   lateral = Rv * (1 - A_eff)

sub new {
    my ( $class, %args ) = @_;

    my $self = $class->SUPER::new(%args);

    $self->{rate} = $args{rate};
    die "$class: 'rate' (nm/min) is required\n" unless defined $self->{rate};

    $self->{power}        = $args{power};
    $self->{power_nom}    = defined $args{power_nom}    ? $args{power_nom}    : 200;
    $self->{pressure}     = $args{pressure};
    $self->{pressure_nom} = defined $args{pressure_nom} ? $args{pressure_nom} : 20;
    $self->{bias}         = $args{bias};
    $self->{bias_nom}     = defined $args{bias_nom}     ? $args{bias_nom}     : 200;
    $self->{anisotropy_nom} =
        defined $args{anisotropy} ? $args{anisotropy} : 0.90;
    $self->{loading}  = defined $args{loading}  ? $args{loading}  : 1.00;
    $self->{Ea}       = defined $args{Ea}       ? $args{Ea}       : 0.0;
    $self->{ref_temp} = defined $args{ref_temp} ? $args{ref_temp} : 25;

    return $self;
}

sub process_type        { 'Dry' }
sub default_process_key { 'dry' }

for my $attr (
    qw( rate power power_nom pressure pressure_nom bias bias_nom loading Ea ref_temp )
    )
{
    no strict 'refs';
    *{$attr} = sub {
        my ( $self, $v ) = @_;
        $self->{$attr} = $v if @_ > 1;
        return $self->{$attr};
    };
}

sub _ratio {
    my ( $num, $den, $exp ) = @_;
    return 1 unless defined $num && defined $den && $den > 0;
    return ( $num / $den )**$exp;
}

sub power_factor    { _ratio( $_[0]->{power},    $_[0]->{power_nom},    0.8 ) }
sub pressure_factor { _ratio( $_[0]->{pressure}, $_[0]->{pressure_nom}, 0.3 ) }
sub bias_factor     { _ratio( $_[0]->{bias},     $_[0]->{bias_nom},     0.5 ) }

sub arrhenius_factor {
    my ($self) = @_;
    return 1 unless $self->{Ea} && defined $self->{temperature};
    my $kb    = Physics::Etch::Process::KB_EV();
    my $t_ref = $self->{ref_temp}    + 273.15;
    my $t     = $self->{temperature} + 273.15;
    return exp( ( $self->{Ea} / $kb ) * ( 1 / $t_ref - 1 / $t ) );
}

sub vertical_rate {
    my ($self) = @_;
    return $self->{rate}
        * $self->power_factor
        * $self->pressure_factor
        * $self->bias_factor
        * $self->{loading}
        * $self->arrhenius_factor;
}

sub effective_anisotropy {
    my ($self) = @_;
    my $p_ratio = _ratio( $self->{pressure}, $self->{pressure_nom}, 1 );
    my $b_ratio = _ratio( $self->{bias_nom}, $self->{bias},         1 );  # inverse
    my $a = 1 - ( 1 - $self->{anisotropy_nom} ) * $p_ratio * $b_ratio;
    $a = 0 if $a < 0;
    $a = 1 if $a > 1;
    return $a;
}

sub lateral_rate {
    my ($self) = @_;
    return $self->vertical_rate * ( 1 - $self->effective_anisotropy );
}

# report the model's own anisotropy via the process-condition-aware value
sub anisotropy { $_[0]->effective_anisotropy }

sub _conditions_lines {
    my ($self) = @_;
    my @l;
    my @knobs;
    push @knobs, sprintf( 'power %g W',   $self->{power} )    if defined $self->{power};
    push @knobs, sprintf( 'pressure %g mTorr', $self->{pressure} )
        if defined $self->{pressure};
    push @knobs, sprintf( 'bias %g V',    $self->{bias} )     if defined $self->{bias};
    push @l, '  Plasma       : ' . join( ', ', @knobs ) if @knobs;
    push @l, sprintf( '  Ion energy   : ~%g eV (from DC bias)', $self->{bias} )
        if defined $self->{bias};
    push @l, sprintf( '  Loading      : %.2f x', $self->{loading} )
        if $self->{loading} != 1;
    push @l, sprintf( '  Temperature  : %.1f degC  (Ea %.2f eV)',
        $self->{temperature}, $self->{Ea} )
        if $self->{Ea} && defined $self->{temperature};
    return @l;
}

1;

__END__

=head1 NAME

Physics::Etch::DryEtch - anisotropic plasma / RIE dry etch model

=head1 SYNOPSIS

    use Physics::Etch::DryEtch;

    my $etch = Physics::Etch::DryEtch->new(
        target      => 'silicon_nitride',
        etchant     => 'CF4/O2',
        thickness   => 200,       # nm
        rate        => 120,       # nm/min nominal
        power       => 200,       # W
        pressure    => 30,        # mTorr
        bias        => 250,       # V (ion energy)
        anisotropy  => 0.9,
        feature_cd  => 300,
        mask        => 'photoresist',
        mask_thickness => 800,
        sel_mask    => 4,
        substrate   => 'silicon',
        sel_substrate => 8,
        overetch    => 0.20,
    );

    print $etch->report;

=head1 DESCRIPTION

Models plasma-based etching. The vertical rate scales from a nominal value with
RF power, chamber pressure and DC self-bias (ion energy). Anisotropy is tuned
by the balance of directional ion bombardment (bias, low pressure -> vertical)
against isotropic radical attack (high pressure, low bias -> lateral), giving a
process-dependent lateral rate and sidewall angle.

See L<Physics::Etch::Process> for the inherited profile, selectivity, mask
survival, over-etch and reporting methods.

=cut
