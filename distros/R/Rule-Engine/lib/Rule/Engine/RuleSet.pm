package Rule::Engine::RuleSet;
use Moose;

=head1 NAME

Rule::Engine::RuleSet - A Set of Rules

=head1 ATTRIBUTES

=head2 filter

=cut

has 'filter' => (
    is => 'rw',
    isa => 'Rule::Engine::Filter',
    predicate => 'has_filter'
);

=head2 description

Text describing this rule.

=cut

has 'description' => (
    is => 'rw',
    isa => 'Str'
);

=head2 name

The name of this rule.

=cut

has 'name' => (
    is => 'rw',
    isa => 'Str',
    required => 1
);

=head2 rules

An array of rules.

=cut

has 'rules' => (
    is  => 'rw',
    isa => 'ArrayRef[Rule::Engine::Rule]',
    traits => [ 'Array' ],
    default => sub { [] },
    handles => {
        add_rule => 'push',
        rule_count => 'count'
    }
);

=head1 METHODS

=head2 add_rule($rule)

Add a rule

=head2 execute

=cut

sub execute {
    my ($self, $session, $objects) = @_;

    foreach my $obj (@{ $objects }) {
        foreach my $rule (@{ $self->rules }) {
            $rule->execute($session, $obj) if $rule->evaluate($session, $obj);
        }
    }

    return $objects unless $self->has_filter;
    my @returnable = ();
    foreach my $obj (@{ $objects }) {
        push(@returnable, $obj) if($self->filter->check($session, $obj));
    }

    return \@returnable;
}

=head2 rule_count

Returns the number of rules for this session.

=cut


__PACKAGE__->meta->make_immutable;
no Moose;

1;