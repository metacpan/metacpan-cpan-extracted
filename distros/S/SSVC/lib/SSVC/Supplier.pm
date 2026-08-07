package SSVC::Supplier;

use feature ':5.10';
use strict;
use utf8;
use warnings;

use parent 'SSVC::Base';

use Carp ();

use constant METADATA => +{
    key         => 'supplier',
    name        => 'Supplier',
    description =>
        'Decision about the priority with which a supplier should develop and release a patch or other remediation for a vulnerability.',
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

    utility => {
        vector_name => 'U',
        label       => 'Utility',
        definition  => 'The usefulness of the exploit to the adversary, computed from Automatable and Value Density.',
        values      => [L => 'laborious', E => 'efficient', S => 'super_effective'],
    },

    technical_impact => {
        vector_name => 'TI',
        label       => 'Technical Impact',
        definition  => 'The technical impact of the vulnerability.',
        values      => [P => 'partial', T => 'total'],
    },

    safety_impact => {
        vector_name => 'SI',
        label       => 'Safety Impact',
        definition  => 'The safety impact of the vulnerability.',
        values      => [N => 'negligible', M => 'marginal', R => 'critical', C => 'catastrophic'],
    },

    public_safety_impact => {
        vector_name => 'PSI',
        label       => 'Public Safety Impact',
        definition  => 'A coarse-grained representation of impact to public safety, computed from Safety Impact.',
        values      => [M => 'minimal', S => 'significant'],
    },

    decision => {
        vector_name => 'DSOI',
        label       => 'Defer, Scheduled, Out-of-Cycle, Immediate',
        definition  => 'The priority with which a supplier should develop and release a patch or other remediation.',
        values      => [D => 'defer', S => 'scheduled', O => 'out_of_cycle', I => 'immediate'],
    },
};
#>>>

use constant DECISION_PATH => [qw(E U TI PSI)];
use constant VECTOR        => [qw(E A VD U TI SI PSI DSOI)];

# https://certcc.github.io/SSVC/reference/decision_points/utility/ (Automatable x Value Density -> Utility)
#    A VD  =>  U
my %A_VD_to_U = (N => {D => 'L', C => 'E'}, Y => {D => 'E', C => 'S'},);

# https://certcc.github.io/SSVC/reference/decision_points/public_safety_impact/ (Safety Impact -> Public Safety Impact)
#    SI  =>  PSI
my %SI_to_PSI = (N => 'M', M => 'S', R => 'S', C => 'S');

# https://certcc.github.io/SSVC/howto/supplier_tree/ (Exploitation x Utility x Technical Impact x Public Safety Impact -> Decision)
#    E U TI PSI  =>  DSOI
#<<<
use constant DECISION_TREE => +{
    'N:L:P:M' => 'D', 'N:L:P:S' => 'S', 'N:L:T:M' => 'S', 'N:L:T:S' => 'O',
    'N:E:P:M' => 'S', 'N:E:P:S' => 'O', 'N:E:T:M' => 'S', 'N:E:T:S' => 'O',
    'N:S:P:M' => 'S', 'N:S:P:S' => 'O', 'N:S:T:M' => 'O', 'N:S:T:S' => 'O',
    'P:L:P:M' => 'S', 'P:L:P:S' => 'O', 'P:L:T:M' => 'S', 'P:L:T:S' => 'I',
    'P:E:P:M' => 'S', 'P:E:P:S' => 'I', 'P:E:T:M' => 'O', 'P:E:T:S' => 'I',
    'P:S:P:M' => 'O', 'P:S:P:S' => 'I', 'P:S:T:M' => 'O', 'P:S:T:S' => 'I',
    'A:L:P:M' => 'O', 'A:L:P:S' => 'I', 'A:L:T:M' => 'O', 'A:L:T:S' => 'I',
    'A:E:P:M' => 'O', 'A:E:P:S' => 'I', 'A:E:T:M' => 'O', 'A:E:T:S' => 'I',
    'A:S:P:M' => 'I', 'A:S:P:S' => 'I', 'A:S:T:M' => 'I', 'A:S:T:S' => 'I',
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

    unless ($self->vector_value('E') && $self->vector_value('TI')) {
        Carp::croak "Cannot compute 'decision': need 'exploitation' and 'technical_impact'";
    }

    my $computed_D = $class->DECISION_TREE->{join ':', map { $self->vector_value($_) } @{$class->DECISION_PATH}};

    if ($self->vector_value('DSOI') && $self->vector_value('DSOI') ne $computed_D) {
        Carp::croak sprintf "Inconsistent 'decision' (got: %s, expected: %s)", $self->vector_value('DSOI'), $computed_D;
    }

    $self->{vector}->{DSOI} = $computed_D;
    $self->{decision} = $class->decision_point_labels('decision')->{$computed_D};

    return $self;

}

sub exploitation         { shift->{decision_points}->{exploitation} }
sub automatable          { shift->{decision_points}->{automatable} }
sub value_density        { shift->{decision_points}->{value_density} }
sub utility              { shift->{decision_points}->{utility} }
sub technical_impact     { shift->{decision_points}->{technical_impact} }
sub safety_impact        { shift->{decision_points}->{safety_impact} }
sub public_safety_impact { shift->{decision_points}->{public_safety_impact} }
sub decision             { shift->{decision} }

sub TO_JSON {

    my $self = shift;

    return {
        exploitation         => $self->exploitation,
        automatable          => $self->automatable,
        value_density        => $self->value_density,
        utility              => $self->utility,
        technical_impact     => $self->technical_impact,
        safety_impact        => $self->safety_impact,
        public_safety_impact => $self->public_safety_impact,
        decision             => $self->decision,
    };

}

1;


__END__
=head1 NAME

SSVC::Supplier - SSVC Supplier decision (patch development priority)

=head1 SYNOPSIS

  use SSVC::Supplier;

  $ssvc = SSVC::Supplier->new(
    exploitation      => 'active',
    automatable       => 'yes',
    value_density     => 'concentrated',
    technical_impact  => 'total',
    safety_impact     => 'catastrophic',
  );

  # Get the decision
  say $ssvc->decision; # immediate

  # Get the decision point value
  say $ssvc->utility; # super_effective

  # Convert SSVC in JSON in according of SSVC JSON Schema
  $json = encode_json($ssvc);


=head1 DESCRIPTION

The Supplier decision helps a supplier (e.g. a software vendor) decide the
priority with which to develop and release a patch, or other remediation,
for a vulnerability.

L<https://certcc.github.io/SSVC/howto/supplier_tree/>

=begin html
 
<a href = "https://raw.githubusercontent.com/giterlizzi/perl-SSVC/main/graph/supplier.png">
<img src = "https://raw.githubusercontent.com/giterlizzi/perl-SSVC/main/graph/supplier.png"
     alt = "Supplier" />
</a>
 
=end html

=head2 OBJECT-ORIENTED INTERFACE

=over

=item $ssvc = SSVC::Supplier->new(%params)

Creates a new L<SSVC::Supplier> instance using the provided decision points.

Parameters / Decision Points:

=over

=item * C<exploitation> (required)

=item * C<automatable> (required), used to compute C<utility>

=item * C<value_density> (required), used to compute C<utility>

=item * C<technical_impact> (required)

=item * C<safety_impact> (required), used to compute C<public_safety_impact>

=item * C<utility> (optional), Computed from C<automatable> and C<value_density>

=item * C<public_safety_impact> (optional), Computed from C<safety_impact>

=back

=item $ssvc->decision

The supplier patch-development priority decision: C<defer>, C<scheduled>, C<out_of_cycle> or C<immediate>.

=item $ssvc->TO_JSON

Helper method for JSON modules (L<JSON>, L<JSON::PP>, L<JSON::XS>, L<Mojo::JSON>, etc).

=back

=head2 DECISION POINTS

=over

=item $ssvc->exploitation

The present state of exploitation of the vulnerability.

=item $ssvc->automatable

Can an attacker reliably automate creating exploitation events for this vulnerability?

=item $ssvc->value_density

The concentration of value in the target.

=item $ssvc->technical_impact

The technical impact of the vulnerability.

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
