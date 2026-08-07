package SSVC::CISA::BOD2604;

use feature ':5.10';
use strict;
use utf8;
use warnings;

use parent 'SSVC::Base';

use constant METADATA => +{
    key         => 'cisa_bod_26_04',
    name        => 'CISA BOD 26-04 Response Model',
    description => 'CISA Binding Operational Directive 26-04 remediation timeline for a vulnerability.',
    url         => 'https://certcc.github.io/SSVC/howto/cisa_response/',
};

#<<<
use constant DECISION_POINTS => +{
    in_kev => {
        vector_name => 'KEV',
        label       => 'In CISA KEV',
        definition  => 'Is the vulnerability listed in the CISA Known Exploited Vulnerabilities (KEV) catalog?',
        values      => [N => 'no', Y => 'yes'],
    },

    publicly_exposed => {
        vector_name => 'PE',
        label       => 'Publicly Exposed',
        definition  =>
            'Is the affected asset accessible to unauthenticated or untrusted entities via public networks?',
        values => [N => 'no', Y => 'yes'],
    },

    automatable => {
        vector_name => 'A',
        label       => 'Automatable',
        definition  => 'Can an attacker reliably automate creating exploitation events for this vulnerability?',
        values      => [N => 'no', Y => 'yes'],
    },

    technical_impact => {
        vector_name => 'TI',
        label       => 'Technical Impact',
        definition  => 'The technical impact of the vulnerability.',
        values      => [P => 'partial', T => 'total'],
    },

    decision => {
        vector_name => 'RT',
        label       => 'Remediation Timeline',
        definition  => 'The CISA BOD 26-04 remediation timeline for the vulnerability.',
        values      => [
            FSU => 'fix_on_system_upgrade',
            D60 => '60_days',
            D14 => '14_days',
            D3  => '3_days',
            D3F => '3_days_forensic_investigation',
        ],
    },
};
#>>>

use constant VECTOR        => [qw(KEV PE A TI RT)];
use constant DECISION_PATH => [qw(KEV PE A TI)];

# https://certcc.github.io/SSVC/howto/cisa_response/ (In KEV x Publicly Exposed x Automatable x Technical Impact -> Remediation Timeline)
#    KEV PE A TI  =>  RT
#<<<
use constant DECISION_TREE => +{
    'N:N:N:P' => 'FSU', 'N:N:N:T' => 'FSU', 'N:N:Y:P' => 'D60', 'N:N:Y:T' => 'D60',
    'N:Y:N:P' => 'D60', 'N:Y:N:T' => 'D14', 'N:Y:Y:P' => 'D14', 'N:Y:Y:T' => 'D3',
    'Y:N:N:P' => 'D14', 'Y:N:N:T' => 'D14', 'Y:N:Y:P' => 'D14', 'Y:N:Y:T' => 'D3F',
    'Y:Y:N:P' => 'D14', 'Y:Y:N:T' => 'D3F', 'Y:Y:Y:P' => 'D3',  'Y:Y:Y:T' => 'D3F',
};
#>>>

sub new {

    my ($class, %params) = @_;

    my $self = $class->SUPER::new(%params);

    my $decision = $self->compute;

    $self->{vector}->{RT} = $decision;
    $self->{decision} = $class->decision_point_labels('decision')->{$self->vector_value('RT')};

    return $self;

}

sub in_kev           { shift->{decision_points}->{in_kev} }
sub publicly_exposed { shift->{decision_points}->{publicly_exposed} }
sub automatable      { shift->{decision_points}->{automatable} }
sub technical_impact { shift->{decision_points}->{technical_impact} }
sub decision         { shift->{decision} }

sub TO_JSON {

    my $self = shift;

    return {
        in_kev           => $self->in_kev,
        publicly_exposed => $self->publicly_exposed,
        automatable      => $self->automatable,
        technical_impact => $self->technical_impact,
        decision         => $self->decision,
    };

}

1;


__END__
=head1 NAME

SSVC::CISA::BOD2604 - SSVC CISA BOD 26-04 Response Model (remediation timeline)

=head1 SYNOPSIS

  use SSVC::CISA::BOD2604;

  $ssvc = SSVC::CISA::BOD2604->new(
    in_kev            => 'yes',
    publicly_exposed  => 'yes',
    automatable       => 'yes',
    technical_impact  => 'total',
  );

  # Get the decision
  say $ssvc->decision; # 3_days_forensic_investigation

  # Convert SSVC in JSON in according of SSVC JSON Schema
  $json = encode_json($ssvc);


=head1 DESCRIPTION

The CISA BOD 26-04 Response Model determines the remediation timeline CISA's
Binding Operational Directive 26-04 assigns to a vulnerability, based on
whether it is in the CISA KEV catalog, whether the affected asset is publicly
exposed, whether it is automatable, and its technical impact.

Unlike L<SSVC::CISA> (the older CISA SSVC v2 guide, producing a
Track/Track*/Attend/Act decision), this model produces a remediation timeline:
C<fix_on_system_upgrade>, C<60_days>, C<14_days>, C<3_days> or
C<3_days_forensic_investigation>.

L<https://certcc.github.io/SSVC/howto/cisa_response/>

=begin html

<a href = "https://raw.githubusercontent.com/giterlizzi/perl-SSVC/main/graph/cisa_bod_26_04.png">
<img src = "https://raw.githubusercontent.com/giterlizzi/perl-SSVC/main/graph/cisa_bod_26_04.png"
     alt = "CISA BOD 26-04 Response Model" />
</a>

=end html

=head2 OBJECT-ORIENTED INTERFACE

=over

=item $ssvc = SSVC::CISA::BOD2604->new(%params)

Creates a new L<SSVC::CISA::BOD2604> instance using the provided decision points.

Parameters / Decision Points:

=over

=item * C<in_kev> (required)

=item * C<publicly_exposed> (required)

=item * C<automatable> (required)

=item * C<technical_impact> (required)

=back

=item $ssvc->decision

The CISA BOD 26-04 remediation timeline: C<fix_on_system_upgrade>, C<60_days>,
C<14_days>, C<3_days> or C<3_days_forensic_investigation>.

=item $ssvc->TO_JSON

Helper method for JSON modules (L<JSON>, L<JSON::PP>, L<JSON::XS>, L<Mojo::JSON>, etc).

=back

=head2 DECISION POINTS

=over

=item $ssvc->in_kev

Is the vulnerability listed in the CISA Known Exploited Vulnerabilities (KEV) catalog?

=item $ssvc->publicly_exposed

Is the affected asset accessible to unauthenticated or untrusted entities via public networks?

=item $ssvc->automatable

Can an attacker reliably automate creating exploitation events for this vulnerability?

=item $ssvc->technical_impact

The technical impact of the vulnerability.

=back

=head1 SEE ALSO

L<SSVC>, L<SSVC::Base>, L<SSVC::CISA>

=over 4

=item [Carnegie Mellon University] SSVC: Stakeholder-Specific Vulnerability Categorization (L<https://certcc.github.io/SSVC/>)

=item [CISA] Binding Operational Directive 26-04 (L<https://certcc.github.io/SSVC/howto/cisa_response/>)

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
