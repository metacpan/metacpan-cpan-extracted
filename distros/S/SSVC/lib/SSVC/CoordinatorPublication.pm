package SSVC::CoordinatorPublication;

use feature ':5.10';
use strict;
use utf8;
use warnings;

use parent 'SSVC::Base';

use constant PUBLISH              => [qw(publish dont_publish)];
use constant SUPPLIER_INVOLVEMENT => [qw(fix_ready cooperative uncooperative_unresponsive)];
use constant EXPLOITATION         => [qw(none public_poc active)];
use constant PUBLIC_VALUE_ADDED   => [qw(limited ampliative precedence)];

use constant METADATA => +{
    key         => 'coordinator_publication',
    name        => 'Coordinator Publication',
    description => 'Coordinator decision about whether to publish information about a vulnerability.',
    url         => 'https://certcc.github.io/SSVC/',
};

use constant VECTOR => [qw(SINV E PVA PUBLISH)];

use constant DECISION_PATH => [qw(SINV E PVA)];

use constant DECISION_TREE => +{

    # SINV : E : PVA => P

    'FR:N:L' => 'N',
    'C:N:L'  => 'N',
    'FR:P:L' => 'N',
    'FR:N:A' => 'N',
    'UU:N:L' => 'N',
    'C:P:L'  => 'N',
    'FR:A:L' => 'N',
    'C:N:A'  => 'N',
    'FR:P:A' => 'N',
    'FR:N:P' => 'P',
    'UU:P:L' => 'N',
    'C:A:L'  => 'N',
    'UU:N:A' => 'N',
    'C:P:A'  => 'N',
    'FR:A:A' => 'P',
    'C:N:P'  => 'P',
    'FR:P:P' => 'P',
    'UU:A:L' => 'P',
    'UU:P:A' => 'P',
    'C:A:A'  => 'P',
    'UU:N:P' => 'P',
    'C:P:P'  => 'P',
    'FR:A:P' => 'P',
    'UU:A:A' => 'P',
    'UU:P:P' => 'P',
    'C:A:P'  => 'P',
    'UU:A:P' => 'P',
};

#<<<
use constant DECISION_POINTS => +{
    publish => {
        vector_name => 'PUBLISH',
        label       => 'Publish, Do Not Publish',
        definition  => 'The publish outcome group.',
        values      => [P => 'publish', N => 'dont_publish'],
    },

    supplier_involvement => {
        vector_name => 'SINV',
        label       => 'Supplier Involvement',
        definition  => 'What is the state of the supplier\'s work on addressing the vulnerability?',
        values      => [FR => 'fix_ready', C => 'cooperative', UU => 'uncooperative_unresponsive'],
    },

    exploitation => {
        vector_name => 'E',
        label       => 'Exploitation',
        definition  => 'The present state of exploitation of the vulnerability.',
        values      => [N => 'none', P => 'public_poc', A => 'active'],
    },

    public_value_added => {
        vector_name => 'PVA',
        label       => 'Public Value Added',
        definition  => 'How much value would a publication from the coordinator benefit the broader community?',
        values      => [L => 'limited', A => 'ampliative', P => 'precedence'],
    },
};
#>>>


sub new {

    my ($class, %params) = @_;

    my $self = $class->SUPER::new(%params);

    my $decision = $self->compute;

    $self->{vector}->{PUBLISH} = $decision;
    $self->{decision} = $class->decision_point_labels('publish')->{$self->vector_value('PUBLISH')};

    return $self;
}


sub supplier_involvement { shift->{decision_points}->{supplier_involvement} }
sub exploitation         { shift->{decision_points}->{exploitation} }
sub public_value_added   { shift->{decision_points}->{public_value_added} }
sub publish              { shift->{decision} }

sub TO_JSON {

    my $self = shift;

    return {
        supplier_involvement => $self->supplier_involvement,
        exploitation         => $self->exploitation,
        public_value_added   => $self->public_value_added,
        publish              => $self->publish,
    };

}

1;


__END__
=head1 NAME

SSVC::CoordinatorPublication - SSVC Coordinator Publication decision

=head1 SYNOPSIS

  use SSVC::CoordinatorPublication;

  $ssvc = SSVC::CoordinatorPublication->new(
    supplier_involvement => 'fix_ready',
    exploitation         => 'active',
    public_value_added   => 'ampliative',
  );

  # Get the decision
  say $ssvc->publish; # publish

  # Convert SSVC in JSON in according of SSVC JSON Schema
  $json = encode_json($ssvc);


=head1 DESCRIPTION

The Coordinator Publication decision helps a coordinator decide whether to
publish information about a vulnerability.

L<https://certcc.github.io/SSVC/>

=begin html
 
<a href = "https://raw.githubusercontent.com/giterlizzi/perl-SSVC/main/graph/coordinator_publication.png">
<img src = "https://raw.githubusercontent.com/giterlizzi/perl-SSVC/main/graph/coordinator_publication.png"
     alt = "Coordinator Publication" />
</a>
 
=end html

=head2 OBJECT-ORIENTED INTERFACE

=over

=item $ssvc = SSVC::CoordinatorPublication->new(%params)

Creates a new L<SSVC::CoordinatorPublication> instance using the provided decision points.

Parameters / Decision Points:

=over

=item * C<supplier_involvement> (required)

=item * C<exploitation> (required)

=item * C<public_value_added> (required)

=back

=item $ssvc->publish

The coordinator publication decision: C<publish> or C<dont_publish>.

=item $ssvc->TO_JSON

Helper method for JSON modules (L<JSON>, L<JSON::PP>, L<JSON::XS>, L<Mojo::JSON>, etc).

=back

=head2 DECISION POINTS

=over

=item $ssvc->supplier_involvement

What is the state of the supplier's work on addressing the vulnerability?

=item $ssvc->exploitation

The present state of exploitation of the vulnerability.

=item $ssvc->public_value_added

How much value would a publication from the coordinator benefit the broader community?

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
