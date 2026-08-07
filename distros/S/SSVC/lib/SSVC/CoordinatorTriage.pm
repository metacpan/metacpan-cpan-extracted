package SSVC::CoordinatorTriage;

use feature ':5.10';
use strict;
use utf8;
use warnings;

use parent 'SSVC::Base';

use Carp ();

use constant METADATA => +{
    key         => 'coordinator_triage',
    name        => 'Coordinator Triage',
    description =>
        'Coordinator decision about whether to decline, track, or actively coordinate a vulnerability report.',
    url => 'https://certcc.github.io/SSVC/',
};

#<<<
use constant DECISION_POINTS => +{
    report_public => {
        vector_name => 'RP',
        label       => 'Report Public',
        definition  => 'Is a viable report of the details of the vulnerability already publicly available?',
        values      => [N => 'no', Y => 'yes'],
    },

    supplier_contacted => {
        vector_name => 'SCON',
        label       => 'Supplier Contacted',
        definition  =>
            'Has the reporter made a good-faith effort to contact the supplier of the vulnerable component using a quality contact method?',
        values => [N => 'no', Y => 'yes'],
    },

    report_credibility => {
        vector_name => 'RC',
        label       => 'Report Credibility',
        definition  => 'Is the report credible?',
        values      => [NC => 'not_credible', C => 'credible'],
    },

    supplier_cardinality => {
        vector_name => 'SC',
        label       => 'Supplier Cardinality',
        definition  => 'How many suppliers are responsible for the vulnerable component and its remediation or mitigation plan?',
        values      => [O => 'one', M => 'multiple'],
    },

    supplier_engagement => {
        vector_name => 'SE',
        label       => 'Supplier Engagement',
        definition  =>
            'Is the supplier responding to the reporter\'s contact effort and actively participating in the coordination effort?',
        values => [A => 'active', U => 'unresponsive'],
    },

    automatable => {
        vector_name => 'A',
        label       => 'Automatable',
        definition  => 'Can an attacker reliably automate creating exploitation events for this vulnerability?',
        values      => [N => 'no', Y => 'yes'],
    },

    value_density => {
        vector_name => 'VD',
        label       => 'Value Density',
        definition  => 'The concentration of value in the target.',
        values      => [D => 'diffuse', C => 'concentrated'],
    },

    safety_impact => {
        vector_name => 'SI',
        label       => 'Safety Impact',
        definition  => 'The safety impact of the vulnerability.',
        values      => [N => 'negligible', M => 'marginal', R => 'critical', C => 'catastrophic'],
    },

    utility => {
        vector_name => 'U',
        label       => 'Utility',
        definition  => 'The usefulness of the exploit to the adversary, computed from Automatable and Value Density.',
        values      => [L => 'laborious', E => 'efficient', S => 'super_effective'],
    },

    public_safety_impact => {
        vector_name => 'PSI',
        label       => 'Public Safety Impact',
        definition  => 'A coarse-grained representation of impact to public safety, computed from Safety Impact.',
        values      => [M => 'minimal', S => 'significant'],
    },

    decision => {
        vector_name => 'COORDINATE',
        label       => 'Decline, Track, Coordinate',
        definition  => 'The coordinator triage decision.',
        values      => [D => 'decline', T => 'track', C => 'coordinate'],
    },
};
#>>>

use constant DECISION_PATH => [qw(RP SCON RC SC SE U PSI)];
use constant VECTOR        => [qw(RP SCON RC SC SE VD A SI U PSI COORDINATE)];

# https://certcc.github.io/SSVC/reference/decision_points/utility/ (Automatable x Value Density -> Utility)
#    A VD  =>  U
my %A_VD_to_U = (N => {D => 'L', C => 'E'}, Y => {D => 'E', C => 'S'},);

# https://certcc.github.io/SSVC/reference/decision_points/public_safety_impact/ (Safety Impact -> Public Safety Impact)
#    SI  =>  PSI
my %SI_to_PSI = (N => 'M', M => 'S', R => 'S', C => 'S');

# https://certcc.github.io/SSVC/howto/triage_decision/
# (Report Public x Supplier Contacted x Report Credibility x Supplier Cardinality x Supplier Engagement x Utility x Public Safety Impact -> Decision)
#    RP SCON RC SC SE U PSI  =>  COORDINATE
#<<<
use constant DECISION_TREE => +{
    'N:N:C:M:A:E:M'   => 'D', 'N:N:C:M:A:E:S'   => 'D', 'N:N:C:M:A:L:M'   => 'D', 'N:N:C:M:A:L:S'   => 'D',
    'N:N:C:M:A:S:M'   => 'D', 'N:N:C:M:A:S:S'   => 'C', 'N:N:C:M:U:E:M'   => 'D', 'N:N:C:M:U:E:S'   => 'D',
    'N:N:C:M:U:L:M'   => 'D', 'N:N:C:M:U:L:S'   => 'D', 'N:N:C:M:U:S:M'   => 'D', 'N:N:C:M:U:S:S'   => 'C',
    'N:N:C:O:A:E:M'   => 'D', 'N:N:C:O:A:E:S'   => 'D', 'N:N:C:O:A:L:M'   => 'D', 'N:N:C:O:A:L:S'   => 'D',
    'N:N:C:O:A:S:M'   => 'D', 'N:N:C:O:A:S:S'   => 'D', 'N:N:C:O:U:E:M'   => 'D', 'N:N:C:O:U:E:S'   => 'D',
    'N:N:C:O:U:L:M'   => 'D', 'N:N:C:O:U:L:S'   => 'D', 'N:N:C:O:U:S:M'   => 'D', 'N:N:C:O:U:S:S'   => 'D',
    'N:N:NC:M:A:E:M'  => 'D', 'N:N:NC:M:A:E:S'  => 'D', 'N:N:NC:M:A:L:M'  => 'D', 'N:N:NC:M:A:L:S'  => 'D',
    'N:N:NC:M:A:S:M'  => 'D', 'N:N:NC:M:A:S:S'  => 'C', 'N:N:NC:M:U:E:M'  => 'D', 'N:N:NC:M:U:E:S'  => 'D',
    'N:N:NC:M:U:L:M'  => 'D', 'N:N:NC:M:U:L:S'  => 'D', 'N:N:NC:M:U:S:M'  => 'D', 'N:N:NC:M:U:S:S'  => 'C',
    'N:N:NC:O:A:E:M'  => 'D', 'N:N:NC:O:A:E:S'  => 'D', 'N:N:NC:O:A:L:M'  => 'D', 'N:N:NC:O:A:L:S'  => 'D',
    'N:N:NC:O:A:S:M'  => 'D', 'N:N:NC:O:A:S:S'  => 'D', 'N:N:NC:O:U:E:M'  => 'D', 'N:N:NC:O:U:E:S'  => 'D',
    'N:N:NC:O:U:L:M'  => 'D', 'N:N:NC:O:U:L:S'  => 'D', 'N:N:NC:O:U:S:M'  => 'D', 'N:N:NC:O:U:S:S'  => 'D',
    'N:Y:C:M:A:E:M'   => 'D', 'N:Y:C:M:A:E:S'   => 'T', 'N:Y:C:M:A:L:M'   => 'D', 'N:Y:C:M:A:L:S'   => 'T',
    'N:Y:C:M:A:S:M'   => 'C', 'N:Y:C:M:A:S:S'   => 'C', 'N:Y:C:M:U:E:M'   => 'C', 'N:Y:C:M:U:E:S'   => 'C',
    'N:Y:C:M:U:L:M'   => 'C', 'N:Y:C:M:U:L:S'   => 'C', 'N:Y:C:M:U:S:M'   => 'C', 'N:Y:C:M:U:S:S'   => 'C',
    'N:Y:C:O:A:E:M'   => 'D', 'N:Y:C:O:A:E:S'   => 'T', 'N:Y:C:O:A:L:M'   => 'D', 'N:Y:C:O:A:L:S'   => 'D',
    'N:Y:C:O:A:S:M'   => 'D', 'N:Y:C:O:A:S:S'   => 'T', 'N:Y:C:O:U:E:M'   => 'C', 'N:Y:C:O:U:E:S'   => 'C',
    'N:Y:C:O:U:L:M'   => 'T', 'N:Y:C:O:U:L:S'   => 'C', 'N:Y:C:O:U:S:M'   => 'C', 'N:Y:C:O:U:S:S'   => 'C',
    'N:Y:NC:M:A:E:M'  => 'D', 'N:Y:NC:M:A:E:S'  => 'T', 'N:Y:NC:M:A:L:M'  => 'D', 'N:Y:NC:M:A:L:S'  => 'T',
    'N:Y:NC:M:A:S:M'  => 'T', 'N:Y:NC:M:A:S:S'  => 'C', 'N:Y:NC:M:U:E:M'  => 'D', 'N:Y:NC:M:U:E:S'  => 'T',
    'N:Y:NC:M:U:L:M'  => 'D', 'N:Y:NC:M:U:L:S'  => 'T', 'N:Y:NC:M:U:S:M'  => 'T', 'N:Y:NC:M:U:S:S'  => 'C',
    'N:Y:NC:O:A:E:M'  => 'D', 'N:Y:NC:O:A:E:S'  => 'T', 'N:Y:NC:O:A:L:M'  => 'D', 'N:Y:NC:O:A:L:S'  => 'D',
    'N:Y:NC:O:A:S:M'  => 'D', 'N:Y:NC:O:A:S:S'  => 'T', 'N:Y:NC:O:U:E:M'  => 'D', 'N:Y:NC:O:U:E:S'  => 'T',
    'N:Y:NC:O:U:L:M'  => 'D', 'N:Y:NC:O:U:L:S'  => 'D', 'N:Y:NC:O:U:S:M'  => 'D', 'N:Y:NC:O:U:S:S'  => 'T',
    'Y:N:C:M:A:E:M'   => 'D', 'Y:N:C:M:A:E:S'   => 'D', 'Y:N:C:M:A:L:M'   => 'D', 'Y:N:C:M:A:L:S'   => 'D',
    'Y:N:C:M:A:S:M'   => 'D', 'Y:N:C:M:A:S:S'   => 'C', 'Y:N:C:M:U:E:M'   => 'D', 'Y:N:C:M:U:E:S'   => 'D',
    'Y:N:C:M:U:L:M'   => 'D', 'Y:N:C:M:U:L:S'   => 'D', 'Y:N:C:M:U:S:M'   => 'D', 'Y:N:C:M:U:S:S'   => 'C',
    'Y:N:C:O:A:E:M'   => 'D', 'Y:N:C:O:A:E:S'   => 'D', 'Y:N:C:O:A:L:M'   => 'D', 'Y:N:C:O:A:L:S'   => 'D',
    'Y:N:C:O:A:S:M'   => 'D', 'Y:N:C:O:A:S:S'   => 'D', 'Y:N:C:O:U:E:M'   => 'D', 'Y:N:C:O:U:E:S'   => 'D',
    'Y:N:C:O:U:L:M'   => 'D', 'Y:N:C:O:U:L:S'   => 'D', 'Y:N:C:O:U:S:M'   => 'D', 'Y:N:C:O:U:S:S'   => 'D',
    'Y:N:NC:M:A:E:M'  => 'D', 'Y:N:NC:M:A:E:S'  => 'D', 'Y:N:NC:M:A:L:M'  => 'D', 'Y:N:NC:M:A:L:S'  => 'D',
    'Y:N:NC:M:A:S:M'  => 'D', 'Y:N:NC:M:A:S:S'  => 'C', 'Y:N:NC:M:U:E:M'  => 'D', 'Y:N:NC:M:U:E:S'  => 'D',
    'Y:N:NC:M:U:L:M'  => 'D', 'Y:N:NC:M:U:L:S'  => 'D', 'Y:N:NC:M:U:S:M'  => 'D', 'Y:N:NC:M:U:S:S'  => 'C',
    'Y:N:NC:O:A:E:M'  => 'D', 'Y:N:NC:O:A:E:S'  => 'D', 'Y:N:NC:O:A:L:M'  => 'D', 'Y:N:NC:O:A:L:S'  => 'D',
    'Y:N:NC:O:A:S:M'  => 'D', 'Y:N:NC:O:A:S:S'  => 'D', 'Y:N:NC:O:U:E:M'  => 'D', 'Y:N:NC:O:U:E:S'  => 'D',
    'Y:N:NC:O:U:L:M'  => 'D', 'Y:N:NC:O:U:L:S'  => 'D', 'Y:N:NC:O:U:S:M'  => 'D', 'Y:N:NC:O:U:S:S'  => 'D',
    'Y:Y:C:M:A:E:M'   => 'D', 'Y:Y:C:M:A:E:S'   => 'D', 'Y:Y:C:M:A:L:M'   => 'D', 'Y:Y:C:M:A:L:S'   => 'D',
    'Y:Y:C:M:A:S:M'   => 'D', 'Y:Y:C:M:A:S:S'   => 'C', 'Y:Y:C:M:U:E:M'   => 'D', 'Y:Y:C:M:U:E:S'   => 'D',
    'Y:Y:C:M:U:L:M'   => 'D', 'Y:Y:C:M:U:L:S'   => 'D', 'Y:Y:C:M:U:S:M'   => 'D', 'Y:Y:C:M:U:S:S'   => 'C',
    'Y:Y:C:O:A:E:M'   => 'D', 'Y:Y:C:O:A:E:S'   => 'D', 'Y:Y:C:O:A:L:M'   => 'D', 'Y:Y:C:O:A:L:S'   => 'D',
    'Y:Y:C:O:A:S:M'   => 'D', 'Y:Y:C:O:A:S:S'   => 'D', 'Y:Y:C:O:U:E:M'   => 'D', 'Y:Y:C:O:U:E:S'   => 'D',
    'Y:Y:C:O:U:L:M'   => 'D', 'Y:Y:C:O:U:L:S'   => 'D', 'Y:Y:C:O:U:S:M'   => 'D', 'Y:Y:C:O:U:S:S'   => 'D',
    'Y:Y:NC:M:A:E:M'  => 'D', 'Y:Y:NC:M:A:E:S'  => 'D', 'Y:Y:NC:M:A:L:M'  => 'D', 'Y:Y:NC:M:A:L:S'  => 'D',
    'Y:Y:NC:M:A:S:M'  => 'D', 'Y:Y:NC:M:A:S:S'  => 'C', 'Y:Y:NC:M:U:E:M'  => 'D', 'Y:Y:NC:M:U:E:S'  => 'D',
    'Y:Y:NC:M:U:L:M'  => 'D', 'Y:Y:NC:M:U:L:S'  => 'D', 'Y:Y:NC:M:U:S:M'  => 'D', 'Y:Y:NC:M:U:S:S'  => 'C',
    'Y:Y:NC:O:A:E:M'  => 'D', 'Y:Y:NC:O:A:E:S'  => 'D', 'Y:Y:NC:O:A:L:M'  => 'D', 'Y:Y:NC:O:A:L:S'  => 'D',
    'Y:Y:NC:O:A:S:M'  => 'D', 'Y:Y:NC:O:A:S:S'  => 'D', 'Y:Y:NC:O:U:E:M'  => 'D', 'Y:Y:NC:O:U:E:S'  => 'D',
    'Y:Y:NC:O:U:L:M'  => 'D', 'Y:Y:NC:O:U:L:S'  => 'D', 'Y:Y:NC:O:U:S:M'  => 'D', 'Y:Y:NC:O:U:S:S'  => 'D',
};
#>>>

sub new {

    my ($class, %params) = @_;

    my $self = $class->SUPER::new(%params);

    unless ($self->vector_value('A') && $self->vector_value('VD')) {
        Carp::croak "Cannot compute 'utility': need 'automatable' and 'value_density'";
    }

    my $computed_U = $A_VD_to_U{$self->vector_value('A')}->{$self->vector_value('VD')};

    if ($self->vector_value('U') && $self->vector_value('U') ne $computed_U) {
        Carp::croak sprintf "Inconsistent 'utility' (got: %s, expected: %s)", $self->vector_value('U'), $computed_U;
    }

    $self->{vector}->{U}                = $computed_U;
    $self->{decision_points}->{utility} = $class->decision_point_labels('utility')->{$computed_U};

    unless ($self->vector_value('SI')) {
        Carp::croak "Cannot compute 'public_safety_impact': need 'safety_impact'";
    }

    my $computed_PSI = $SI_to_PSI{$self->vector_value('SI')};

    if ($self->vector_value('PSI') && $self->vector_value('PSI') ne $computed_PSI) {
        Carp::croak sprintf "Inconsistent 'public_safety_impact' (got: %s, expected: %s)", $self->vector_value('PSI'),
            $computed_PSI;
    }

    $self->{vector}->{PSI} = $computed_PSI;
    $self->{decision_points}->{public_safety_impact}
        = $class->decision_point_labels('public_safety_impact')->{$computed_PSI};

    unless ($self->vector_value('RP')
        && $self->vector_value('SCON')
        && $self->vector_value('RC')
        && $self->vector_value('SC')
        && $self->vector_value('SE'))
    {
        Carp::croak "Cannot compute 'decision'"
            . ": need 'report_public', 'supplier_contacted', 'report_credibility', 'supplier_cardinality' and 'supplier_engagement'";
    }

    my $computed_D = $class->DECISION_TREE->{join ':', map { $self->vector_value($_) } @{$class->DECISION_PATH}};

    if ($self->vector_value('COORDINATE') && $self->vector_value('COORDINATE') ne $computed_D) {
        Carp::croak sprintf "Inconsistent 'decision' (got: %s, expected: %s)", $self->vector_value('COORDINATE'),
            $computed_D;
    }

    $self->{vector}->{COORDINATE} = $computed_D;
    $self->{decision} = $class->decision_point_labels('decision')->{$computed_D};

    return $self;

}

sub report_public        { shift->{decision_points}->{report_public} }
sub supplier_contacted   { shift->{decision_points}->{supplier_contacted} }
sub report_credibility   { shift->{decision_points}->{report_credibility} }
sub supplier_cardinality { shift->{decision_points}->{supplier_cardinality} }
sub supplier_engagement  { shift->{decision_points}->{supplier_engagement} }
sub automatable          { shift->{decision_points}->{automatable} }
sub value_density        { shift->{decision_points}->{value_density} }
sub safety_impact        { shift->{decision_points}->{safety_impact} }
sub utility              { shift->{decision_points}->{utility} }
sub public_safety_impact { shift->{decision_points}->{public_safety_impact} }
sub decision             { shift->{decision} }

sub TO_JSON {

    my $self = shift;

    return {
        report_public        => $self->report_public,
        supplier_contacted   => $self->supplier_contacted,
        report_credibility   => $self->report_credibility,
        supplier_cardinality => $self->supplier_cardinality,
        supplier_engagement  => $self->supplier_engagement,
        automatable          => $self->automatable,
        value_density        => $self->value_density,
        safety_impact        => $self->safety_impact,
        utility              => $self->utility,
        public_safety_impact => $self->public_safety_impact,
        decision             => $self->decision,
    };

}

1;


__END__
=head1 NAME

SSVC::CoordinatorTriage - SSVC Coordinator Triage decision

=head1 SYNOPSIS

  use SSVC::CoordinatorTriage;

  $ssvc = SSVC::CoordinatorTriage->new(
    report_public         => 'no',
    supplier_contacted    => 'yes',
    report_credibility    => 'credible',
    supplier_cardinality  => 'multiple',
    supplier_engagement   => 'unresponsive',
    automatable           => 'yes',
    value_density         => 'concentrated',
    safety_impact         => 'catastrophic',
  );

  # Get the decision
  say $ssvc->decision; # coordinate

  # Convert SSVC in JSON in according of SSVC JSON Schema
  $json = encode_json($ssvc);


=head1 DESCRIPTION

The Coordinator Triage decision helps a coordinator decide whether to
decline, track, or actively coordinate a vulnerability report.

L<https://certcc.github.io/SSVC/howto/triage_decision/>

=begin html
 
<a href = "https://raw.githubusercontent.com/giterlizzi/perl-SSVC/main/graph/coordinator_triage.png">
<img src = "https://raw.githubusercontent.com/giterlizzi/perl-SSVC/main/graph/coordinator_triage.png"
     alt = "Coordinator Triage" />
</a>
 
=end html

=head2 OBJECT-ORIENTED INTERFACE

=over

=item $ssvc = SSVC::CoordinatorTriage->new(%params)

Creates a new L<SSVC::CoordinatorTriage> instance using the provided decision points.

Parameters / Decision Points:

=over

=item * C<report_public> (required)

=item * C<supplier_contacted> (required)

=item * C<report_credibility> (required)

=item * C<supplier_cardinality> (required)

=item * C<supplier_engagement> (required)

=item * C<automatable> (required), used to compute C<utility>

=item * C<value_density> (required), used to compute C<utility>

=item * C<safety_impact> (required), used to compute C<public_safety_impact>

=item * C<utility> (optional), Computed from C<automatable> and C<value_density>

=item * C<public_safety_impact> (optional), Computed from C<safety_impact>

=back

=item $ssvc->decision

The coordinator triage decision: C<decline>, C<track> or C<coordinate>.

=item $ssvc->TO_JSON

Helper method for JSON modules (L<JSON>, L<JSON::PP>, L<JSON::XS>, L<Mojo::JSON>, etc).

=back

=head2 DECISION POINTS

=over

=item $ssvc->report_public

Is a viable report of the details of the vulnerability already publicly available?

=item $ssvc->supplier_contacted

Has the reporter made a good-faith effort to contact the supplier of the vulnerable component using a quality contact method?

=item $ssvc->report_credibility

Is the report credible?

=item $ssvc->supplier_cardinality

How many suppliers are responsible for the vulnerable component and its remediation or mitigation plan?

=item $ssvc->supplier_engagement

Is the supplier responding to the reporter's contact effort and actively participating in the coordination effort?

=item $ssvc->automatable

Can an attacker reliably automate creating exploitation events for this vulnerability?

=item $ssvc->value_density

The concentration of value in the target.

=item $ssvc->safety_impact

The safety impact of the vulnerability.

=item $ssvc->utility

The usefulness of the exploit to the adversary, computed from C<automatable> and C<value_density>.

=item $ssvc->public_safety_impact

A coarse-grained representation of impact to public safety, computed from C<safety_impact>.

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
