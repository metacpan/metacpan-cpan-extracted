package SSVC::Deployer;

use feature ':5.10';
use strict;
use utf8;
use warnings;

use parent 'SSVC::Base';

use Carp ();

use constant METADATA => +{
    key         => 'deployer',
    name        => 'Deployer',
    description =>
        'Decision about the priority with which a deployer should apply a patch or other remediation for a deployed system.',
    url => 'https://certcc.github.io/SSVC/',
};

#<<<
use constant DECISION_POINTS => +{
    exploitation => {
        vector_name => 'E',
        label       => 'Exploitation',
        definition  => 'The present state of exploitation of the vulnerability.',
        values      => [N => 'none', P => 'public_poc', A => 'active'],
    },

    system_exposure => {
        vector_name => 'EXP',
        label       => 'System Exposure',
        definition  => 'The accessible attack surface of the affected system or service.',
        values      => [S => 'small', C => 'controlled', O => 'open'],
    },

    automatable => {
        vector_name => 'A',
        label       => 'Automatable',
        definition  => 'Can an attacker reliably automate creating exploitation events for this vulnerability?',
        values      => [N => 'no', Y => 'yes'],
    },

    safety_impact => {
        vector_name => 'SI',
        label       => 'Safety Impact',
        definition  => 'The safety impact of the vulnerability.',
        values      => [N => 'negligible', M => 'marginal', R => 'critical', C => 'catastrophic'],
    },

    mission_impact => {
        vector_name => 'MI',
        label       => 'Mission Impact',
        definition  => 'Impact on Mission Essential Functions of the organization.',
        values      => [D => 'degraded', MSC => 'mef_support_crippled', MEF => 'mef_failure', MF => 'mission_failure'],
    },

    human_impact => {
        vector_name => 'HI',
        label       => 'Human Impact',
        definition  => 'Human Impact is a combination of Safety Impact and Mission Impact.',
        values      => [L => 'low', M => 'medium', H => 'high', VH => 'very_high'],
    },

    decision => {
        vector_name => 'DSOI',
        label       => 'Defer, Scheduled, Out-of-Cycle, Immediate',
        definition  => 'The priority with which a deployer should apply a patch or other remediation.',
        values      => [D => 'defer', S => 'scheduled', O => 'out_of_cycle', I => 'immediate'],
    },
};
#>>>

use constant DECISION_PATH => [qw(E EXP A HI)];
use constant VECTOR        => [qw(E EXP A SI MI HI DSOI)];

# https://certcc.github.io/SSVC/reference/decision_points/human_impact/ (Safety Impact x Mission Impact -> Human Impact)
#    SI MI  =>  HI
my %SI_MI_to_HI = (
    N => {D => 'L',  MSC => 'L',  MEF => 'M',  MF => 'VH'},
    M => {D => 'L',  MSC => 'L',  MEF => 'M',  MF => 'VH'},
    R => {D => 'M',  MSC => 'H',  MEF => 'H',  MF => 'VH'},
    C => {D => 'VH', MSC => 'VH', MEF => 'VH', MF => 'VH'},
);

# https://certcc.github.io/SSVC/howto/deployer_tree/ (Exploitation x System Exposure x Automatable x Human Impact -> Decision)
#    E EXP A HI  =>  DSOI
#<<<
use constant DECISION_TREE => +{
    'A:C:N:H'  => 'O', 'A:C:N:L'  => 'S', 'A:C:N:M'  => 'S', 'A:C:N:VH' => 'O',
    'A:C:Y:H'  => 'O', 'A:C:Y:L'  => 'O', 'A:C:Y:M'  => 'O', 'A:C:Y:VH' => 'O',
    'A:O:N:H'  => 'O', 'A:O:N:L'  => 'S', 'A:O:N:M'  => 'O', 'A:O:N:VH' => 'I',
    'A:O:Y:H'  => 'I', 'A:O:Y:L'  => 'O', 'A:O:Y:M'  => 'O', 'A:O:Y:VH' => 'I',
    'A:S:N:H'  => 'O', 'A:S:N:L'  => 'S', 'A:S:N:M'  => 'S', 'A:S:N:VH' => 'O',
    'A:S:Y:H'  => 'O', 'A:S:Y:L'  => 'S', 'A:S:Y:M'  => 'O', 'A:S:Y:VH' => 'O',
    'N:C:N:H'  => 'S', 'N:C:N:L'  => 'D', 'N:C:N:M'  => 'S', 'N:C:N:VH' => 'S',
    'N:C:Y:H'  => 'S', 'N:C:Y:L'  => 'S', 'N:C:Y:M'  => 'S', 'N:C:Y:VH' => 'S',
    'N:O:N:H'  => 'S', 'N:O:N:L'  => 'D', 'N:O:N:M'  => 'S', 'N:O:N:VH' => 'S',
    'N:O:Y:H'  => 'S', 'N:O:Y:L'  => 'S', 'N:O:Y:M'  => 'S', 'N:O:Y:VH' => 'O',
    'N:S:N:H'  => 'S', 'N:S:N:L'  => 'D', 'N:S:N:M'  => 'D', 'N:S:N:VH' => 'S',
    'N:S:Y:H'  => 'S', 'N:S:Y:L'  => 'D', 'N:S:Y:M'  => 'S', 'N:S:Y:VH' => 'S',
    'P:C:N:H'  => 'S', 'P:C:N:L'  => 'D', 'P:C:N:M'  => 'S', 'P:C:N:VH' => 'S',
    'P:C:Y:H'  => 'S', 'P:C:Y:L'  => 'S', 'P:C:Y:M'  => 'S', 'P:C:Y:VH' => 'O',
    'P:O:N:H'  => 'S', 'P:O:N:L'  => 'S', 'P:O:N:M'  => 'S', 'P:O:N:VH' => 'O',
    'P:O:Y:H'  => 'O', 'P:O:Y:L'  => 'S', 'P:O:Y:M'  => 'S', 'P:O:Y:VH' => 'O',
    'P:S:N:H'  => 'S', 'P:S:N:L'  => 'D', 'P:S:N:M'  => 'S', 'P:S:N:VH' => 'S',
    'P:S:Y:H'  => 'S', 'P:S:Y:L'  => 'S', 'P:S:Y:M'  => 'S', 'P:S:Y:VH' => 'S',
};
#>>>

sub new {

    my ($class, %params) = @_;

    my $self = $class->SUPER::new(%params);

    unless ($self->vector_value('SI') && $self->vector_value('MI')) {
        Carp::croak "Cannot compute 'human_impact': need 'safety_impact' and 'mission_impact'";
    }

    my $computed_HI = $SI_MI_to_HI{$self->vector_value('SI')}->{$self->vector_value('MI')};

    if ($self->vector_value('HI') && $self->vector_value('HI') ne $computed_HI) {
        Carp::croak sprintf "Inconsistent 'human_impact' (got: %s, expected: %s)", $self->vector_value('HI'),
            $computed_HI;
    }

    $self->{vector}->{HI}                    = $computed_HI;
    $self->{decision_points}->{human_impact} = $class->decision_point_labels('human_impact')->{$computed_HI};

    unless ($self->vector_value('E')
        && $self->vector_value('EXP')
        && $self->vector_value('A')
        && $self->vector_value('HI'))
    {
        Carp::croak "Cannot compute 'decision'"
            . ": need 'exploitation', 'system_exposure', 'automatable' and 'human_impact'";
    }

    my $computed_D = $class->DECISION_TREE->{join ':', map { $self->vector_value($_) } @{$class->DECISION_PATH}};

    if ($self->vector_value('DSOI') && $self->vector_value('DSOI') ne $computed_D) {
        Carp::croak sprintf "Inconsistent 'decision' (got: %s, expected: %s)", $self->vector_value('DSOI'), $computed_D;
    }

    $self->{vector}->{DSOI} = $computed_D;
    $self->{decision} = $class->decision_point_labels('decision')->{$computed_D};

    return $self;

}

sub exploitation    { shift->{decision_points}->{exploitation} }
sub system_exposure { shift->{decision_points}->{system_exposure} }
sub automatable     { shift->{decision_points}->{automatable} }
sub safety_impact   { shift->{decision_points}->{safety_impact} }
sub mission_impact  { shift->{decision_points}->{mission_impact} }
sub human_impact    { shift->{decision_points}->{human_impact} }
sub decision        { shift->{decision} }

sub TO_JSON {

    my $self = shift;

    return {
        exploitation    => $self->exploitation,
        system_exposure => $self->system_exposure,
        automatable     => $self->automatable,
        safety_impact   => $self->safety_impact,
        mission_impact  => $self->mission_impact,
        human_impact    => $self->human_impact,
        decision        => $self->decision,
    };

}

1;


__END__
=head1 NAME

SSVC::Deployer - SSVC Deployer decision (patch application priority)

=head1 SYNOPSIS

  use SSVC::Deployer;

  $ssvc = SSVC::Deployer->new(
    exploitation    => 'active',
    system_exposure => 'open',
    automatable     => 'yes',
    safety_impact   => 'catastrophic',
    mission_impact  => 'mission_failure',
  );

  # Get the decision
  say $ssvc->decision; # immediate

  # Get the decision point value
  say $ssvc->human_impact; # very_high

  # Convert SSVC in JSON in according of SSVC JSON Schema
  $json = encode_json($ssvc);


=head1 DESCRIPTION

The Deployer decision helps organizations decide the priority with which to
apply a patch, or other remediation, for a deployed system.

L<https://certcc.github.io/SSVC/howto/deployer_tree/>

=begin html
 
<a href = "https://raw.githubusercontent.com/giterlizzi/perl-SSVC/main/graph/deployer.png">
<img src = "https://raw.githubusercontent.com/giterlizzi/perl-SSVC/main/graph/deployer.png"
     alt = "Deployer" />
</a>
 
=end html

=head2 OBJECT-ORIENTED INTERFACE

=over

=item $ssvc = SSVC::Deployer->new(%params)

Creates a new L<SSVC::Deployer> instance using the provided decision points.

Parameters / Decision Points:

=over

=item * C<exploitation> (required)

=item * C<system_exposure> (required)

=item * C<automatable> (required)

=item * C<safety_impact> (required)

=item * C<mission_impact> (required)

=item * C<human_impact> (optional), Computed from C<safety_impact> and C<mission_impact>

=back

=item $ssvc->decision

The deployer patch-application priority decision: C<defer>, C<scheduled>, C<out_of_cycle> or C<immediate>.

=item $ssvc->TO_JSON

Helper method for JSON modules (L<JSON>, L<JSON::PP>, L<JSON::XS>, L<Mojo::JSON>, etc).

=back

=head2 DECISION POINTS

=over

=item $ssvc->exploitation

The present state of exploitation of the vulnerability.

=item $ssvc->system_exposure

The accessible attack surface of the affected system or service.

=item $ssvc->automatable

Can an attacker reliably automate creating exploitation events for this vulnerability?

=item $ssvc->safety_impact

The safety impact of the vulnerability.

=item $ssvc->mission_impact

Impact on Mission Essential Functions of the organization.

=item $ssvc->human_impact

Human Impact, computed from C<safety_impact> and C<mission_impact>.

=back

=head1 SEE ALSO

L<SSVC>, L<SSVC::Base>

=over 4

=item [Carnegie Mellon University] SSVC: Stakeholder-Specific Vulnerability Categorization (L<https://certcc.github.io/SSVC/>)

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-SSVC/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-SSVC>

    git clone https://github.com/giterlizzi/perl-SSVC.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025-2026 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
