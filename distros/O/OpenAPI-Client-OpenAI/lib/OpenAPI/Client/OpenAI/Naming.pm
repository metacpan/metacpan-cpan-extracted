package OpenAPI::Client::OpenAI::Naming;

use 5.014;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(to_snake_case detect_collisions);

# Convert any of camelCase, PascalCase, kebab-case, snake_case, or mixed
# to snake_case. Pure function; the runtime alias loop and the docgen
# both depend on this producing stable, collision-detectable output.
#
# Input:  a string (operationId or similar identifier)
# Output: the same identifier normalised to lower_snake_case
sub to_snake_case {
    my ($name) = @_;
    return $name unless defined $name && length $name;

    # kebab → snake first so we can treat the rest as a single identifier.
    $name =~ s/-/_/g;

    # Insert underscore between a run of capitals and a following Capital+lowercase
    # (handles "APIKey" → "API_Key", "HTTPServer" → "HTTP_Server").
    $name =~ s/([A-Z]+)([A-Z][a-z])/${1}_${2}/g;

    # Insert underscore between lowercase/digit and an uppercase letter
    # (handles "createChat" → "create_Chat").
    $name =~ s/([a-z\d])([A-Z])/${1}_${2}/g;

    # Collapse any doubled underscores from already-snake input mixed with the above.
    $name =~ s/_+/_/g;

    return lc $name;
}

# Given an array-ref of operationIds, return a hash-ref mapping each
# snake_case form that collides (i.e. has more than one source) to a
# sorted array-ref of the original operationIds that produced it.
# Returns an empty hash-ref when there are no collisions.
#
# Input:  array-ref of strings
# Output: hash-ref { snake_form => [sorted originals], ... } (only collisions)
sub detect_collisions {
    my ($operation_ids) = @_;
    my %by_snake;
    for my $op (@$operation_ids) {
        push @{ $by_snake{ to_snake_case($op) } }, $op;
    }
    # Only return entries with more than one source operationId.
    return {
        map  { $_ => [ sort @{ $by_snake{$_} } ] }
        grep { @{ $by_snake{$_} } > 1 } keys %by_snake
    };
}

1;

__END__

=encoding UTF-8

=head1 NAME

OpenAPI::Client::OpenAI::Naming - Identifier normalisation helpers for OpenAPI::Client::OpenAI

=head1 SYNOPSIS

    use OpenAPI::Client::OpenAI::Naming qw(to_snake_case detect_collisions);

    my $snake = to_snake_case('createChatCompletion');  # 'create_chat_completion'

    my $collisions = detect_collisions(\@operation_ids);
    if (%$collisions) { ... }

=head1 DESCRIPTION

Provides pure-function helpers for normalising OpenAPI operationIds to
C<snake_case> and detecting collisions when multiple operationIds map to the
same normalised form.

=head1 FUNCTIONS

=head2 to_snake_case

    my $snake = to_snake_case($identifier);

Converts a camelCase, PascalCase, kebab-case, or already-snake_case identifier
to lower C<snake_case>.  Pure function; the result is stable and suitable for
use as a Perl method name.

=head2 detect_collisions

    my $collisions = detect_collisions(\@operation_ids);

Given an array-ref of operationId strings, returns a hash-ref mapping each
C<snake_case> form that would be produced by more than one source operationId
to a sorted array-ref of those source operationIds.  Returns an empty hash-ref
when there are no collisions.

=head1 COPYRIGHT AND LICENSE

Same terms as L<OpenAPI::Client::OpenAI>.

=cut
