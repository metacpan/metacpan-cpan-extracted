package Physics::Etch::WetEtch;

use strict;
use warnings;
use parent -norequire, 'Physics::Etch::Process';

use Physics::Etch::Process ();   # for KB_EV constant

our $VERSION = '0.01';

# Wet (liquid) etch: chemical, essentially isotropic.
#
# Extra attributes:
#   rate          nm/min at ref_temp        (required)
#   ref_temp      degC   (default 25)
#   Ea            eV     activation energy   (default 0.50)
#   isotropy      lateral/vertical ratio     (default 1.00, fully isotropic)
#   concentration relative etchant strength  (default 1.00, linear factor)
#   agitation     relative mass transport     (default 1.00)
#
# Rate model:
#   R(T) = rate * exp( (Ea/kB) * (1/Tref - 1/T) ) * concentration * agitation
#   lateral = R * isotropy

sub new {
    my ( $class, %args ) = @_;

    my $self = $class->SUPER::new(%args);

    $self->{rate} = $args{rate};
    die "$class: 'rate' (nm/min) is required\n" unless defined $self->{rate};

    $self->{ref_temp}      = defined $args{ref_temp}      ? $args{ref_temp}      : 25;
    $self->{Ea}            = defined $args{Ea}             ? $args{Ea}            : 0.50;
    $self->{isotropy}      = defined $args{isotropy}      ? $args{isotropy}      : 1.00;
    $self->{concentration} = defined $args{concentration} ? $args{concentration} : 1.00;
    $self->{agitation}     = defined $args{agitation}     ? $args{agitation}     : 1.00;

    # default the process temperature to the reference temperature
    $self->{temperature} = $self->{ref_temp} unless defined $self->{temperature};

    return $self;
}

sub process_type        { 'Wet' }
sub default_process_key { 'wet' }

for my $attr (qw( rate ref_temp Ea isotropy concentration agitation )) {
    no strict 'refs';
    *{$attr} = sub {
        my ( $self, $v ) = @_;
        $self->{$attr} = $v if @_ > 1;
        return $self->{$attr};
    };
}

# Arrhenius multiplier relative to the reference temperature.
sub arrhenius_factor {
    my ($self) = @_;
    my $kb    = Physics::Etch::Process::KB_EV();
    my $t_ref = $self->{ref_temp}    + 273.15;
    my $t     = $self->{temperature} + 273.15;
    return exp( ( $self->{Ea} / $kb ) * ( 1 / $t_ref - 1 / $t ) );
}

sub vertical_rate {
    my ($self) = @_;
    return $self->{rate}
        * $self->arrhenius_factor
        * $self->{concentration}
        * $self->{agitation};
}

sub lateral_rate {
    my ($self) = @_;
    return $self->vertical_rate * $self->{isotropy};
}

sub _conditions_lines {
    my ($self) = @_;
    my @l;
    push @l, sprintf( '  Temperature  : %.1f degC  (ref %.1f degC, Ea %.2f eV)',
        $self->{temperature}, $self->{ref_temp}, $self->{Ea} );
    push @l, sprintf( '  Arrhenius x  : %.2f  (rate vs. reference)',
        $self->arrhenius_factor );
    push @l, sprintf( '  Concentration: %.2f x     Agitation: %.2f x',
        $self->{concentration}, $self->{agitation} )
        if $self->{concentration} != 1 || $self->{agitation} != 1;
    push @l, sprintf( '  Isotropy     : %.2f  (lateral/vertical)', $self->{isotropy} );
    return @l;
}

1;

__END__

=head1 NAME

Physics::Etch::WetEtch - isotropic, temperature-activated wet etch model

=head1 SYNOPSIS

    use Physics::Etch::WetEtch;

    my $etch = Physics::Etch::WetEtch->new(
        target      => 'copper',
        etchant     => 'FeCl3',
        thickness   => 500,      # nm
        rate        => 800,      # nm/min at ref_temp
        ref_temp    => 25,       # degC
        Ea          => 0.43,     # eV
        temperature => 40,       # degC (run hotter -> faster)
        feature_cd  => 2000,     # nm mask opening
        mask        => 'photoresist',
        mask_thickness => 1200,
        sel_mask    => 40,
        overetch    => 0.30,
    );

    print $etch->report;

=head1 DESCRIPTION

Models a liquid-chemistry etch. Rate follows an Arrhenius temperature law
scaled from a reference rate, times optional linear concentration and agitation
factors. The etch is (near-)isotropic, so lateral rate equals vertical rate
times C<isotropy> (default 1.0), producing undercut and sloped/rounded
sidewalls.

See L<Physics::Etch::Process> for the inherited profile, selectivity, and
reporting methods.

=cut
