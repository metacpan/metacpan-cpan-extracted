package Path::Dispatcher::Rule::Sequence;
use Any::Moose;

extends 'Path::Dispatcher::Rule';
with 'Path::Dispatcher::Role::Rules';

has delimiter => (
    is      => 'ro',
    isa     => 'Str',
    default => ' ',
);

sub _match_as_far_as_possible {
    my $self = shift;
    my $path = shift;

    my @tokens = $self->tokenize($path->path);
    my @rules  = $self->rules;
    my @matched;

    while (@tokens && @rules) {
        my $rule  = $rules[0];
        my $token = $tokens[0];

        last unless $rule->match($path->clone_path($token));

        push @matched, $token;
        shift @rules;
        shift @tokens;
    }

    return (\@matched, \@tokens, \@rules);
}

sub _match {
    my $self = shift;
    my $path = shift;

    my ($matched, $tokens, $rules) = $self->_match_as_far_as_possible($path);

    return if @$rules; # didn't provide everything necessary
    return if @$tokens && !$self->prefix; # had tokens left over

    my $leftover = $self->untokenize(@$tokens);
    return {
        leftover            => $leftover,
        positional_captures => $matched,
    };
}

sub complete {
    my $self = shift;
    my $path = shift;

    my ($matched, $tokens, $rules) = $self->_match_as_far_as_possible($path);
    return if @$tokens > 1; # had tokens leftover
    return if !@$rules; # consumed all rules

    my $rule = shift @$rules;
    my $token = @$tokens ? shift @$tokens : '';

    return map { $self->untokenize(@$matched, $_) }
           $rule->complete($path->clone_path($token));
}

sub tokenize {
    my $self = shift;
    my $path = shift;
    return grep { length } split $self->delimiter, $path;
}

sub untokenize {
    my $self   = shift;
    my @tokens = @_;
    return join $self->delimiter,
           grep { length }
           map { split $self->delimiter, $_ }
           @tokens;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=head1 NAME

Path::Dispatcher::Rule::Sequence - a sequence of rules

=head1 SYNOPSIS

=head1 DESCRIPTION

This is basically a more robust and flexible version of
L<Path::Dispatcher::Rule::Tokens>.

Instead of a mish-mash of strings, regexes, and array references,
a Sequence rule has just a list of other rules.

=head1 ATTRIBUTES

=head2 rules

=head2 delimiter

=cut

