package Path::Dispatcher::Rule::Alternation;
use Any::Moose;
extends 'Path::Dispatcher::Rule';

with 'Path::Dispatcher::Role::Rules';

sub _match {
    my $self = shift;
    my $path = shift;

    my @rules = $self->rules;
    return if @rules == 0;

    for my $rule (@rules) {
        return {} if $rule->match($path);
    }

    return;
}

sub complete {
    my $self = shift;

    return map { $_->complete(@_) } $self->rules;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=head1 NAME

Path::Dispatcher::Rule::Alternation - any rule must match

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 rules

=cut

