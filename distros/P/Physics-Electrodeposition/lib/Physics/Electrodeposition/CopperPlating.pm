package Physics::Electrodeposition::CopperPlating;

use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(looks_like_number);

our $VERSION = '0.01';

use constant PI => 3.141592653589793;
use constant FARADAY_C_PER_MOL => 96485;
use constant COPPER_MOLAR_MASS_G_PER_MOL => 63.546;
use constant COPPER_DENSITY_G_PER_CM3 => 8.96;
use constant ELECTRONS_PER_CU => 2;

sub new {
    my ($class, %args) = @_;
    my $seed_args = $args{seed_layer} || {};
    my $bath_args = $args{bath} || {};

    my $self = {
        wafer_diameter_mm => $args{wafer_diameter_mm} // 200,
        voltage_v         => $args{voltage_v} // 0.90,
        pattern_type      => $args{pattern_type} // 'studs',
        convection        => $args{convection} // 'medium',
        target_thickness_um => $args{target_thickness_um},
        cathodic_efficiency => $args{cathodic_efficiency} // 0.96,
        seed_layer        => {
            aluminum_nm => $seed_args->{aluminum_nm} // 300,
            titanium_nm => $seed_args->{titanium_nm} // 50,
        },
        bath             => {
            copper_sulfate_g_l => $bath_args->{copper_sulfate_g_l} // 200,
            sulfuric_acid_g_l  => $bath_args->{sulfuric_acid_g_l} // 60,
            chloride_mg_l      => $bath_args->{chloride_mg_l} // 50,
            suppressor         => $bath_args->{suppressor} // 'PEG',
            accelerator        => $bath_args->{accelerator} // 'SPS',
            leveler            => $bath_args->{leveler} // 'Janus Green B',
        },
    };

    bless $self, $class;
    $self->_validate;
    return $self;
}

sub simulate {
    my ($self, %overrides) = @_;
    my $seed_overrides = $overrides{seed_layer} || {};

    my %input = (
        wafer_diameter_mm   => $overrides{wafer_diameter_mm} // $self->{wafer_diameter_mm},
        voltage_v           => $overrides{voltage_v} // $self->{voltage_v},
        pattern_type        => $overrides{pattern_type} // $self->{pattern_type},
        convection          => $overrides{convection} // $self->{convection},
        target_thickness_um => exists $overrides{target_thickness_um}
            ? $overrides{target_thickness_um}
            : $self->{target_thickness_um},
        cathodic_efficiency => $overrides{cathodic_efficiency} // $self->{cathodic_efficiency},
        seed_layer          => {
            aluminum_nm => $seed_overrides->{aluminum_nm} // $self->{seed_layer}{aluminum_nm},
            titanium_nm => $seed_overrides->{titanium_nm} // $self->{seed_layer}{titanium_nm},
        },
    );

    $self->_validate_input(\%input);

    my %open_area_fraction = (
        studs                => 0.12,
        redistribution_lines => 0.42,
    );
    my %convection_factor = (
        low    => 0.90,
        medium => 1.00,
        high   => 1.12,
    );
    my %uniformity_bonus = (
        low    => -2.0,
        medium => 0.0,
        high   => 1.4,
    );

    my $diameter_cm = $input{wafer_diameter_mm} / 10;
    my $radius_cm   = $diameter_cm / 2;
    my $wafer_area_cm2 = PI * $radius_cm * $radius_cm;
    my $active_area_cm2 = $wafer_area_cm2 * $open_area_fraction{$input{pattern_type}};

    my $reference_conductance = (300 / 2.65) + (50 / 42.0);
    my $seed_conductance = ($input{seed_layer}{aluminum_nm} / 2.65)
        + ($input{seed_layer}{titanium_nm} / 42.0);
    my $seed_factor = _clamp(0.82, 1.08, 0.84 + 0.21 * ($seed_conductance / $reference_conductance));

    my $voltage_factor = _clamp(0.75, 1.30, $input{voltage_v} / 0.90);
    my $pattern_factor = $input{pattern_type} eq 'studs' ? 1.06 : 0.92;

    my $current_density_a_cm2 = 0.022 * $voltage_factor * $seed_factor
        * $convection_factor{$input{convection}} * $pattern_factor;
    $current_density_a_cm2 = _clamp(0.012, 0.045, $current_density_a_cm2);

    my $current_a = $current_density_a_cm2 * $active_area_cm2;

    my $growth_rate_cm_s = (
        $current_density_a_cm2
        * $input{cathodic_efficiency}
        * COPPER_MOLAR_MASS_G_PER_MOL
    ) / (
        ELECTRONS_PER_CU
        * FARADAY_C_PER_MOL
        * COPPER_DENSITY_G_PER_CM3
    );

    my $growth_rate_um_min = $growth_rate_cm_s * 10_000 * 60;

    my $wafer_penalty = $input{wafer_diameter_mm} == 300 ? 1.2 : 0.0;
    my $pattern_bonus = $input{pattern_type} eq 'studs' ? 0.8 : -1.1;
    my $seed_bonus = ($seed_factor - 1.0) * 7.0;
    my $current_penalty = $current_density_a_cm2 > 0.032
        ? (($current_density_a_cm2 - 0.032) / 0.013) * 1.8
        : 0.0;

    my $uniformity_percent = 95.5 + $uniformity_bonus{$input{convection}} + $pattern_bonus
        + $seed_bonus - $wafer_penalty - $current_penalty;
    $uniformity_percent = _clamp(88.0, 99.2, $uniformity_percent);

    my %result = (
        wafer_diameter_mm      => $input{wafer_diameter_mm},
        wafer_area_cm2         => sprintf('%.2f', $wafer_area_cm2) + 0,
        active_area_cm2        => sprintf('%.2f', $active_area_cm2) + 0,
        pattern_type           => $input{pattern_type},
        seed_layer             => $input{seed_layer},
        bath                   => $self->{bath},
        voltage_v              => $input{voltage_v},
        expected_current_a     => sprintf('%.2f', $current_a) + 0,
        current_density_a_cm2  => sprintf('%.4f', $current_density_a_cm2) + 0,
        growth_rate_um_min     => sprintf('%.3f', $growth_rate_um_min) + 0,
        convection             => $input{convection},
        cathodic_efficiency    => $input{cathodic_efficiency},
        estimated_uniformity_percent => sprintf('%.1f', $uniformity_percent) + 0,
    );

    if (defined $input{target_thickness_um}) {
        $result{target_thickness_um} = $input{target_thickness_um};
        $result{estimated_plating_time_min} = sprintf(
            '%.1f',
            $input{target_thickness_um} / $growth_rate_um_min,
        ) + 0;
    }

    return \%result;
}

sub process_notes {
    my ($self, %overrides) = @_;
    my $pattern_type = $overrides{pattern_type} // $self->{pattern_type};
    my $wafer_diameter_mm = $overrides{wafer_diameter_mm} // $self->{wafer_diameter_mm};

    my $pattern_note = $pattern_type eq 'studs'
        ? 'Stud growth generally plates more uniformly because the exposed area fraction is low, so depletion is localized and easier to refresh with modest bath motion.'
        : 'Redistribution lines typically show a larger center-to-edge and line-end thickness spread because the exposed area is larger and the transport path is longer.';

    my $wafer_note = $wafer_diameter_mm == 300
        ? 'A 300 mm wafer is more sensitive to radial current distribution and flow design than a 200 mm wafer, so the same chemistry usually needs stronger agitation or tighter current control.'
        : 'A 200 mm wafer is easier to keep uniform because the radial current path and diffusion length are shorter than on a 300 mm wafer.';

    return [
        'The model assumes an acid copper bath based on CuSO4 and H2SO4 with chloride plus suppressor, accelerator, and leveler additives.',
        'The seed stack is modeled as aluminum for conductivity with titanium as the adhesion or barrier layer; direct copper plating assumes the native oxide has been removed before immersion.',
        'Expected current is estimated from the patterned area rather than the full wafer area because plated openings dominate the electrochemical load.',
        'Growth rate follows Faraday-law scaling, so higher voltage, better seed conductivity, and stronger convection all raise the deposition rate within the operating window of the model.',
        'More convection improves ion replenishment and usually tightens thickness uniformity until very aggressive flow starts to overemphasize edge plating.',
        $pattern_note,
        $wafer_note,
    ];
}

sub _validate {
    my ($self) = @_;
    $self->_validate_input($self);
}

sub _validate_input {
    my ($self, $input) = @_;

    for my $field (qw(wafer_diameter_mm voltage_v cathodic_efficiency)) {
        croak "$field must be numeric" unless looks_like_number($input->{$field});
    }

    croak 'wafer_diameter_mm must be 200 or 300'
        unless $input->{wafer_diameter_mm} == 200 || $input->{wafer_diameter_mm} == 300;
    croak 'voltage_v must be between 0.4 V and 1.5 V'
        unless $input->{voltage_v} >= 0.4 && $input->{voltage_v} <= 1.5;
    croak 'cathodic_efficiency must be between 0.7 and 1.0'
        unless $input->{cathodic_efficiency} >= 0.7 && $input->{cathodic_efficiency} <= 1.0;
    croak "pattern_type must be 'studs' or 'redistribution_lines'"
        unless $input->{pattern_type} eq 'studs' || $input->{pattern_type} eq 'redistribution_lines';
    croak "convection must be 'low', 'medium', or 'high'"
        unless $input->{convection} eq 'low'
            || $input->{convection} eq 'medium'
            || $input->{convection} eq 'high';

    for my $metal (qw(aluminum_nm titanium_nm)) {
        croak "seed_layer.$metal must be numeric"
            unless looks_like_number($input->{seed_layer}{$metal});
        croak "seed_layer.$metal must be positive"
            unless $input->{seed_layer}{$metal} > 0;
    }

    if (defined $input->{target_thickness_um}) {
        croak 'target_thickness_um must be numeric'
            unless looks_like_number($input->{target_thickness_um});
        croak 'target_thickness_um must be positive'
            unless $input->{target_thickness_um} > 0;
    }

    return;
}

sub _clamp {
    my ($min, $max, $value) = @_;
    return $min if $value < $min;
    return $max if $value > $max;
    return $value;
}

1;

__END__

=pod

=head1 NAME

Physics::Electrodeposition::CopperPlating - First-order copper electroplating model for Al/Ti seed layers

=head1 SYNOPSIS

  use Physics::Electrodeposition::CopperPlating;

  my $sim = Physics::Electrodeposition::CopperPlating->new(
      wafer_diameter_mm => 300,
      pattern_type      => 'redistribution_lines',
      convection        => 'high',
      target_thickness_um => 8,
  );

  my $result = $sim->simulate;

=head1 DESCRIPTION

This module provides a simple engineering estimate for copper electroplating on
an aluminum and titanium seed stack for 200 mm and 300 mm wafers. It is meant
for early process tradeoff studies rather than detailed electrochemical design.

=head1 METHODS

=head2 new(%args)

Creates a simulation object.

=head2 simulate(%overrides)

Returns a hash reference containing expected current, growth rate, plating time,
and estimated within-wafer uniformity.

=head2 process_notes(%overrides)

Returns an array reference of process assumptions and qualitative notes.

=cut
