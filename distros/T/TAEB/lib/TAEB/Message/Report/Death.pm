package TAEB::Message::Report::Death;
use TAEB::OO;
extends 'TAEB::Message::Report';

has conducts => (
    metaclass  => 'Collection::Array',
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy       => 1,
    default    => sub { [] },
    auto_deref => 1,
    provides   => {
        push => 'add_conduct',
    },
);

has ['score', 'turns'] => (
    is  => 'rw',
    isa => 'Int',
);

sub as_string {
    my $self = shift;
    my $conducts = join ', ', $self->conducts;
    my $score = $self->score;
    my $turns = $self->turns;

    return << "REPORT";
Conducts: $conducts
Score:    $score
Turns:    $turns
REPORT
}

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

