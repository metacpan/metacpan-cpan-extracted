package Security::CVSS;

use 5.008;
use strict;
use warnings;

use Module::Check_Args;
use Carp qw( croak );

our $VERSION = '0.3';

our %BASE_PARAMS =
            (
                AccessVector          => {Params => {'remote' => 1,   'local' => 0.7},
                                          P2V    => {'remote' => 'R', 'local' => 'L'}},

                AccessComplexity      => {Params => {'low' => 1,   'high' => 0.8},
                                          P2V    => {'low' => 'L', 'high' => 'H'}},

                Authentication        => {Params => {'required' => 0.6, 'not-required'    => 1},
                                          P2V    => {'required' => 'R', 'not-required' => 'NR'}},

                ConfidentialityImpact => {Params => {'none'     => 0,   'partial' => 0.7, 'complete' => 1},
                                          P2V    => {'none'     => 'N', 'partial' => 'P', 'complete' => 'C'}},

                IntegrityImpact       => {Params => {'none'     => 0,   'partial' => 0.7, 'complete' => 1},
                                          P2V    => {'none'     => 'N', 'partial' => 'P', 'complete' => 'C'}},

                AvailabilityImpact    => {Params => {'none'     => 0,   'partial' => 0.7, 'complete' => 1},
                                          P2V    => {'none'     => 'N', 'partial' => 'P', 'complete' => 'C'}},

                ImpactBias            => {Params => {'normal'   => 1,   'confidentiality' => 1,   'integrity' => 1,   'availability' => 1},
                                          P2V    => {'normal'   => 'N', 'confidentiality' => 'C', 'integrity' => 'I', 'availability' => 'A'}}
            );

_CreateV2P(\%BASE_PARAMS);

our %TEMPORAL_PARAMS =
            (
                Exploitability   => {Params => {'unproven' => 0.85, 'proof-of-concept' => 0.9, 'functional' => 0.95, 'high' => 1},
                                     P2V    => {'unproven' => 'U',  'proof-of-concept' => 'P', 'functional' => 'F',  'high' => 'H'}},

                RemediationLevel => {Params => {'official-fix' => 0.87, 'temporary-fix' => 0.9, 'workaround' => 0.95, 'unavailable' => 1},
                                     P2V    => {'official-fix' => 'O',  'temporary-fix' => 'T', 'workaround' => 'W',  'unavailable' => 'U'}},

                ReportConfidence => {Params => {'unconfirmed' => 0.9, 'uncorroborated' => 0.95, 'confirmed' => 1},
                                     P2V    => {'unconfirmed' => 'U', 'uncorroborated' => 'Uc', 'confirmed' => 'C'}}
            );

_CreateV2P(\%TEMPORAL_PARAMS);

our %ENVIRONMENTAL_PARAMS =
            (
                CollateralDamagePotential => {Params => {'none' => 0, 'low' => 0.1,  'medium' => 0.3,  'high' => 0.5}},
                TargetDistribution        => {Params => {'none' => 0, 'low' => 0.25, 'medium' => 0.75, 'high' => 1}}
            );

our %ALL_PARAMS = (%BASE_PARAMS, %TEMPORAL_PARAMS, %ENVIRONMENTAL_PARAMS);

# Create accessors for all parameters
foreach my $Accessor (keys %ALL_PARAMS)
{
    no strict 'refs';
    *{"Security::CVSS::$Accessor"} = sub
        {
            exact_argcount(2);
            my $self = shift;
            $self->_ValidateParam($Accessor, @_);
        };
}

sub new
{
    range_argcount(1, 2);
    my $class  = shift;
    my $Params = shift;

    my $self   = bless({}, $class);

    if (defined($Params))
    {   $self->UpdateFromHash($Params); }

    return $self;
}

# Create the Vector-to-Param hash from the P2V hash
sub _CreateV2P
{
    exact_argcount(1);
    my $Params = shift;

    foreach my $Param (keys %$Params)
    {
        $Params->{$Param}->{V2P} = { map { $Params->{$Param}->{P2V}->{$_} => $_ } keys %{$Params->{$Param}->{P2V}} };
    }
}

sub _ValidateParam
{
    exact_argcount(3);
    my $self  = shift;
    my $Param = shift;
    my $Value = shift;

    # If vector value - convert to full value
    if (exists($ALL_PARAMS{$Param}->{V2P}->{$Value}))
    {   $Value = $ALL_PARAMS{$Param}->{V2P}->{$Value}; }
    else
    {   $Value = lc($Value); }

    if (!grep(/^$Value$/i, keys %{$ALL_PARAMS{$Param}->{Params}}))
    {   croak("Invalid value '$Value' for $Param"); }

    $self->{$Param} = $Value;
}

sub _ConvertToVectorValue
{
    my $Value = shift;
    my @Words = split('-', $Value);

    my $VectorValue;
    foreach my $Word (@Words)
    {   $VectorValue .= uc(substr($Word, 0, 1)); }
}

# Sets up the object from a vector in the format at:
# http://nvd.nist.gov/cvss.cfm?vectorinfo
sub Vector
{
    range_argcount(1, 2);
    my ($self, $Vector) = @_;

    if (defined($Vector))
    {
        if ($Vector !~ m#^\(AV:([RL])/AC:([HL])/Au:(R|NR)/C:([NPC])/I:([NPC])/A:([NPC])/B:([NCIA])(/E:([UPFH])/RL:([OTWU])/RC:(U|Uc|C))?\)#)
        {   croak('Invalid CVSS vector'); }

        my %Values =
            (
                AccessVector          => $1,
                AccessComplexity      => $2,
                Authentication        => $3,
                ConfidentialityImpact => $4,
                IntegrityImpact       => $5,
                AvailabilityImpact    => $6,
                ImpactBias            => $7
            );

        if (defined($8))
        {
            # Has temporal portion
            %Values =
                (
                    %Values,
                    Exploitability   => $9,
                    RemediationLevel => $10,
                    ReportConfidence => $11
                );
        }

        $self->UpdateFromHash(\%Values);
    }
    else
    {
        # Check all parameters exist
        foreach my $Param (keys %BASE_PARAMS)
        {
            if (!defined($self->{$Param}))
            {   croak("You must set '$Param' to output the CVSS vector"); }
        }

        my $VectorValue = sub
            {
                return $ALL_PARAMS{$_[0]}->{P2V}->{$self->{$_[0]}};
            };

        my $Vector = sprintf('AV:%s/AC:%s/Au:%s/C:%s/I:%s/A:%s/B:%s',
                             &$VectorValue('AccessVector'),
                             &$VectorValue('AccessComplexity'),
                             &$VectorValue('Authentication'),
                             &$VectorValue('ConfidentialityImpact'),
                             &$VectorValue('IntegrityImpact'),
                             &$VectorValue('AvailabilityImpact'),
                             &$VectorValue('ImpactBias'));

        my $Environmental = 1;
        foreach my $Param (keys %TEMPORAL_PARAMS)
        {
            if (!defined($self->{$Param}))
            {
                $Environmental = 0;
                last;
            }
        }

        if ($Environmental)
        {
            $Vector .= sprintf('/E:%s/RL:%s/RC:%s',
                               &$VectorValue('Exploitability'),
                               &$VectorValue('RemediationLevel'),
                               &$VectorValue('ReportConfidence'));
        }

        return "($Vector)";
    }
}

sub UpdateFromHash
{
    exact_argcount(2);
    my ($self, $Params) = @_;

    if (ref($Params) ne 'HASH')
    {   croak 'Parameter must be a hash reference'; }

    foreach my $Param (keys %$Params)
    {
        if (!exists($ALL_PARAMS{$Param}))
        {   croak "$Param is not a valid parameter"; }

        $self->$Param($Params->{$Param});
    }
}

sub BaseScore
{
    exact_argcount(1);
    my $self = shift;

    # Check all parameters exist
    foreach my $Param (keys %BASE_PARAMS)
    {
        if (!defined($self->{$Param}))
        {   croak("You must set '$Param' to calculate the Base CVSS score"); }
    }

    my $Score = 10;
    foreach my $Param ('AccessVector', 'AccessComplexity', 'Authentication')
    {
        $Score *= $BASE_PARAMS{$Param}->{Params}->{$self->{$Param}};
    }

    # Calculate the impact portion of the score taking into account the weighting bias
    my $ImpactScore = 0;
    foreach my $ImpactType ('ConfidentialityImpact', 'IntegrityImpact', 'AvailabilityImpact')
    {
        my $Value = $BASE_PARAMS{$ImpactType}->{Params}->{$self->{$ImpactType}};

        if ($self->{ImpactBias} . 'impact'  eq lc($ImpactType))
        {   $Value *= 0.5; }
        elsif ($self->{ImpactBias} eq 'normal')
        {   $Value *= 0.333; }
        else
        {   $Value *= 0.25; }

        $ImpactScore += $Value;
    }
    $Score *= $ImpactScore;

    # Round to one sig fig
    return sprintf('%.1f', $Score);
}

sub TemporalScore
{
    exact_argcount(1);
    my $self = shift;

    # Check all parameters exist
    foreach my $Param (keys %TEMPORAL_PARAMS)
    {
        if (!defined($self->{$Param}))
        {   croak("You must set '$Param' to calculate the Temporal CVSS score"); }
    }

    my $Score = $self->BaseScore();

    foreach my $Param (keys %TEMPORAL_PARAMS)
    {   $Score *= $TEMPORAL_PARAMS{$Param}->{Params}->{$self->{$Param}}; }

    # Round to one sig fig
    return sprintf('%.1f', $Score);
}

sub EnvironmentalScore
{
    exact_argcount(1);
    my $self = shift;

    # Check all parameters exist
    foreach my $Param (keys %ENVIRONMENTAL_PARAMS)
    {
        if (!defined($self->{$Param}))
        {   croak("You must set '$Param' to calculate the Environmental CVSS score"); }
    }

    my $TemporalScore = $self->TemporalScore;

    my $Score = ($TemporalScore + ((10 - $TemporalScore)
                * $ENVIRONMENTAL_PARAMS{CollateralDamagePotential}->{Params}->{$self->{CollateralDamagePotential}}))
                * $ENVIRONMENTAL_PARAMS{TargetDistribution}->{Params}->{$self->{TargetDistribution}};

    # Round to one sig fig
    return sprintf('%.1f', $Score);
}

1;
__END__

=head1 NAME

Security::CVSS - Calculate CVSS values (Common Vulnerability Scoring System)

=head1 SYNOPSIS

  use Security::CVSS;

  my $CVSS = new Security::CVSS;

  $CVSS->AccessVector('Local');
  $CVSS->AccessComplexity('High');
  $CVSS->Authentication('Not-Required');
  $CVSS->ConfidentialityImpact('Complete');
  $CVSS->IntegrityImpact('Complete');
  $CVSS->AvailabilityImpact('Complete');
  $CVSS->ImpactBias('Normal');

  my $BaseScore = $CVSS->BaseScore();

  $CVSS->Exploitability('Proof-Of-Concept');
  $CVSS->RemediationLevel('Official-Fix');
  $CVSS->ReportConfidence('Confirmed');

  my $TemporalScore = $CVSS->TemporalScore()

  $CVSS->CollateralDamagePotential('None');
  $CVSS->TargetDistribution('None');

  my $EnvironmentalScore = $CVSS->EnvironmentalScore();

  my $CVSS = new CVSS({AccessVector => 'Local',
                       AccessComplexity => 'High',
                       Authentication => 'Not-Required',
                       ConfidentialityImpact => 'Complete',
                       IntegrityImpact => 'Complete',
                       AvailabilityImpact => 'Complete',
                       ImpactBias => 'Normal'
                    });

  my $BaseScore = $CVSS->BaseScore();

  $CVSS->UpdateFromHash({AccessVector => 'Remote',
                         AccessComplexity => 'Low');

  my $NewBaseScore = $CVSS->BaseScore();

  $CVSS->Vector('(AV:L/AC:H/Au:NR/C:N/I:P/A:C/B:C)');
  my $BaseScore = $CVSS->BaseScore();
  my $Vector = $CVSS->Vector();

=head1 DESCRIPTION

CVSS allows you to calculate all three types of score described
under the CVSS system: Base, Temporal and Environmental.

You can modify any parameter via its accessor and recalculate
at any time.

The temporal score depends on the base score, and the environmental
score depends on the temporal score. Therefore you must remember
to supply all necessary parameters.

Vector allows you to parse a CVSS vector as described at:
http://nvd.nist.gov/cvss.cfm?vectorinfo

Called without any parameters it will return the CVSS vector as a
string.

=head1 POSSIBLE VALUES

For meaning of these values see the official CVSS FAQ
at https://www.first.org/cvss/faq/#c7

=head2 Base Score

  AccessVector            Local, Remote
  AccessComplexity        Low, High
  Authentication          Required, Not-Required
  ConfidentialityImpact   None, Partial, Complete
  IntegrityImpact         None, Partial, Complete
  AvailabilityImpact      None, Partial, Complete

=head2 Temporal Score

  Exploitability          Unproven, Proof-of-Concept, Functional, High
  RemediationLevel        Official-Fix, Temporary-Fix, Workaround,
                          Unavailable
  ReportConfidence        Unconfirmed, Uncorroborated, Confirmed

=head2 Environmental Score

  CollateralDamagePotential  None, Low, Medium, High
  TargetDistribution         None, Low, Medium, High

=head1 SEE ALSO

This module is based on the formulas supplied at:
http://www.first.org/cvss/

=head1 AUTHOR

Periscan LLC, E<lt>cpan@periscan.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Periscan LLC

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
