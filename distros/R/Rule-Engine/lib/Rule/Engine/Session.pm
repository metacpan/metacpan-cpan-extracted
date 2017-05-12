package Rule::Engine::Session;
use Moose;

=head1 NAME

Rule::Engine::Session - A Rule Engine Session

=head1 ATTRIBUTES

=head2 environment

=cut

has 'environment' => (
    is => 'rw',
    isa => 'HashRef',
    traits => [ 'Hash' ],
    handles => {
        set_environment => 'set',
        get_environment => 'get'
    },
    default => sub { {} }
);

=head2 rules

A hash of rules.

=cut

has 'rulesets' => (
    is  => 'rw',
    isa => 'HashRef[Rule::Engine::RuleSet]',
    traits => [ 'Hash' ],
    default => sub { {} },
    handles => {
        add_ruleset => 'set',
        get_ruleset => 'get',
        ruleset_count => 'count'
    }
);

=head1 METHODS

=head2 add_ruleset($name, $ruleset)

Add a ruleset.

=head2 execute($ruleset, \@objects)

Execute the rules against the objects provided

=cut

sub execute {
    my ($self, $name, $objects) = @_;

    die 'Must supply some objects' unless defined($objects);

    my $rs = $self->get_ruleset($name);
    unless(defined($rs)) {
        die "Uknown RuleSet: $name";
    }

    if(ref($objects) ne 'ARRAY') {
        my @objs = ( $objects );
        $objects = \@objs;
    }

	return $rs->execute($self, $objects);
}

=head2 get_ruleset($name)

Gets the RuleSet (if it exists) with the specified name.

=head2 rule_count

Returns the number of rules for this session.

=cut


__PACKAGE__->meta->make_immutable;
no Moose;

1;