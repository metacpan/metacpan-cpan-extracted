package MooX::ChainedAttributes::Role::GenerateAccessor;

$MooX::ChainedAttributes::Role::GenerateAccessor::VERSION = '0.07';

use Moo::Role;

around is_simple_set => sub {
    my $orig = shift;
    my $self = shift;
    my ($attr, $spec) = @_;
    return 0
        if $spec->{chained};
    $self->$orig(@_);
};

around _generate_set => sub {
    my $orig = shift;
    my $self = shift;
    my ($attr, $spec) = @_;
    my $chained = $spec->{chained};
    local $spec->{chained};
    my $set = $self->$orig(@_);
    return $set
        if !$chained;

    "(scalar ($set, \$_[0]))";
};

1;
