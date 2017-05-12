package Path::Dispatcher::Rule::Intersection;
use Any::Moose;
extends 'Path::Dispatcher::Rule';

with 'Path::Dispatcher::Role::Rules';

sub _match {
    my $self = shift;
    my $path = shift;

    my @rules = $self->rules;
    return if @rules == 0;

    for my $rule (@rules) {
        return unless $rule->match($path);
    }

    return {};
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=head1 NAME

Path::Dispatcher::Rule::Intersection - all rules must match

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 rules

=cut

