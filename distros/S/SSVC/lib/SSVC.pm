package SSVC;

use feature ':5.10';
use strict;
use utf8;
use warnings;

use Carp ();

use SSVC::Base                   ();
use SSVC::CISA                   ();
use SSVC::CISA::BOD2604          ();
use SSVC::CoordinatorPublication ();
use SSVC::CoordinatorTriage      ();
use SSVC::Deployer               ();
use SSVC::Supplier               ();

our $VERSION = '1.00';
$VERSION =~ tr/_//d;    ## no critic

my %METHODOLOGIES = (
    cisa                    => 'SSVC::CISA',
    cisa_bod_26_04          => 'SSVC::CISA::BOD2604',
    coordinator_publication => 'SSVC::CoordinatorPublication',
    coordinator_triage      => 'SSVC::CoordinatorTriage',
    deployer                => 'SSVC::Deployer',
    supplier                => 'SSVC::Supplier',
);

sub new {

    my $class = shift;

    my %params = (@_ == 2 && ref $_[1] eq 'HASH') ? (methodology => $_[0], %{$_[1]}) : @_;

    my $methodology = delete $params{methodology} || Carp::croak 'Missing methodology';

    return $class->methodology_class($methodology)->new(%params);

}

sub methodologies { keys %METHODOLOGIES }

sub methodology_class {

    my ($class, $name) = @_;

    unless (defined $name && defined $METHODOLOGIES{$name}) {
        Carp::croak 'Unknown SSCV methodology';
    }

    return $METHODOLOGIES{$name};

}

sub methodology_info {

    my ($class, $name) = @_;

    my $methodology_class = $class->methodology_class($name);

    my %decision_points
        = map { $_ => $methodology_class->decision_point_info($_) } keys %{$methodology_class->DECISION_POINTS};

    return {%{$methodology_class->METADATA}, decision_points => \%decision_points};

}

sub register_methodology {

    my ($class, $name, $methodology_class) = @_;

    Carp::croak 'Missing methodology name'           unless defined $name;
    Carp::croak 'Missing methodology class'          unless defined $methodology_class;
    Carp::croak "'$methodology_class' is not loaded" unless $methodology_class->can('new');

    unless ($methodology_class->isa('SSVC::Base')) {
        Carp::croak "'$methodology_class' must extend SSVC::Base";
    }

    $METHODOLOGIES{$name} = $methodology_class;

    return $class;

}

1;


__END__
=head1 NAME

SSVC - Perl extension for SSVC (Stakeholder-Specific Vulnerability Categorization)

=head1 SYNOPSIS

  use SSVC;

  $ssvc = SSVC->new(
    cisa => {
      exploitation             => 'active',
      automatable              => 'yes',
      technical_impact         => 'partial',
      mission_prevalence       => 'minimal',
      public_well_being_impact => 'irreversible',
    }
  );

  # - or -
  
  $ssvc = SSVC->new(
    methodology              => 'cisa',
    exploitation             => 'active',
    automatable              => 'yes',
    technical_impact         => 'partial',
    mission_prevalence       => 'minimal',
    public_well_being_impact => 'irreversible',
  );

  # Get the decision
  say $ssvc->decision; # act

  # Parse SSVC vector string (only SSVC::CISA implements a vector string grammar)
  $ssvc = SSVC::CISA->from_vector_string('SSVCv2/E:A/A:Y/T:P/P:M/B:I/M:H/D:C/2025-01-01T00:00:00');

  # Convert the SSVC object in "vector string"
  say $ssvc; # SSVCv2/E:A/A:Y/T:P/P:M/B:I/M:H/D:C/2025-01-01T00:00:00

  # Get the decision point value
  say $ssvc->public_well_being_impact; # irreversible

  # Convert SSVC in JSON in according of SSVC JSON Schema
  $json = encode_json($ssvc);


=head1 DESCRIPTION

SSVC stands for A Stakeholder-Specific Vulnerability Categorization. It is a
methodology for prioritizing vulnerabilities based on the needs of the
stakeholders involved in the vulnerability management process. SSVC is designed
to be used by any stakeholder in the vulnerability management process, including
finders, vendors, coordinators, deployers, and others.

L<https://certcc.github.io/SSVC/>


=head2 METHODOLOGIES

=over

=item * C<cisa> - L<SSVC::CISA>

=item * C<cisa_bod_26_04> - L<SSVC::CISA::BOD2604>

=item * C<coordinator_publication> - L<SSVC::CoordinatorPublication>

=item * C<coordinator_triage> - L<SSVC::CoordinatorTriage>

=item * C<deployer> - L<SSVC::Deployer>

=item * C<supplier> - L<SSVC::Supplier>

=back

Only L<SSVC::CISA> implements a "vector string" grammar (C<from_vector_string> /
C<to_vector_string> in the C<SSVCv2/...> format); the other methodologies do
not have an equivalent official compact representation, so parse/stringify
support for them is limited to the generic, non-standard output of
C<SSVC::Base::to_vector_string> (C<< <METHODOLOGY-KEY>v1/... >>, e.g.
C<DEPLOYERv1/...> or C<SUPPLIERv1/...>).


=head2 OBJECT-ORIENTED INTERFACE

=over

=item $ssvc = SSVC->new(methodology => $name, %decision_points)

=item $ssvc = SSVC->new($name => \%decision_points)

Creates a new L<SSVC> instance for the given methodology name, using the
provided decision points. Both forms are equivalent; the second is only
recognized when called with exactly two arguments and the second one is a
hashref - any other shape (e.g. C<< SSVC->new($name => %decision_points) >>
without wrapping them in a hashref) falls through to the first form and
requires an explicit C<methodology> key.

=item SSVC->methodologies

Returns the list of registered methodology names.

=item SSVC->methodology_class($name)

Returns the class implementing the given methodology name. Croaks if unknown.

=item SSVC->methodology_info($name)

Returns a hashref describing the given methodology (C<key>, C<name>,
C<description>, C<url>) with its C<decision_points> (one entry per decision
point: C<vector_name>, C<label>, C<definition>, C<enum> (ordered list of allowed
values), C<labels> (code => label) and C<codes> (label => code)).
Useful for building any tool that needs to introspect a methodology without
hardcoding its decision points.

  my $info = SSVC->methodology_info('deployer');
  say $info->{name};                                     # Deployer
  say $info->{decision_points}{exploitation}{label};     # Exploitation
  say join ', ', @{$info->{decision_points}{exploitation}{enum}};

=item SSVC->register_methodology($name, $methodology_class);

Registers a custom methodology class under C<$name>, making it available to
C<new>, C<methodology_class>, C<methodology_info> and C<methodologies>.

C<$methodology_class> must already be loaded and extend L<SSVC::Base>. Croaks
otherwise.

  package My::SSVC::Methodology {
    use parent 'SSVC::Base';
    use constant DECISION_POINTS => +{ ... };
    use constant DECISION_TREE   => +{ ... };
    use constant DECISION_PATH   => [ ... ];
  }

  SSVC->register_methodology(my_methodology => 'My::SSVC::Methodology');

  $ssvc = SSVC->new(my_methodology => $params);

=item $ssvc->TO_JSON

Helper method for JSON modules (L<JSON>, L<JSON::PP>, L<JSON::XS>, L<Mojo::JSON>, etc).

Convert the L<SSVC> object in JSON format.

    encode_json($ssvc);

=back

=head1 SEE ALSO

L<SSVC::CISA>, L<SSVC::CISA::BOD2604>, L<SSVC::CoordinatorPublication>, L<SSVC::CoordinatorTriage>, L<SSVC::Deployer>, L<SSVC::Supplier>

=over 4

=item [Carnegie Mellon University] SSVC: Stakeholder-Specific Vulnerability Categorization (L<https://certcc.github.io/SSVC/>)

=item [CISA] Stakeholder-Specific Vulnerability Categorization Guide (L<https://www.cisa.gov/sites/default/files/publications/cisa-ssvc-guide%20508c.pdf>)

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
