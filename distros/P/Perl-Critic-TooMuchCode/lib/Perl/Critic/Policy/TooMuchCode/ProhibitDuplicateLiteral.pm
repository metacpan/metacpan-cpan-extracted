package Perl::Critic::Policy::TooMuchCode::ProhibitDuplicateLiteral;
use strict;
use warnings;
use Perl::Critic::Utils;
use parent 'Perl::Critic::Policy';

sub default_themes       { return qw( bugs maintenance )     }
sub applies_to           { return 'PPI::Document' }

sub violates {
    my ($self, undef, $doc) = @_;
    my %firstSeen;
    my @violations;

    for my $el (@{ $doc->find('PPI::Token::Quote') ||[]}) {
        my $val = $el->string;
        if ($firstSeen{"$val"}) {
            push @violations, $self->violation(
                "A duplicate quoted literal at line: " . $el->line_number . ", column: " . $el->column_number,
                "Another string literal in the same piece of code.",
                $el,
            );
        } else {
            $firstSeen{"$val"} = $el->location;
        }
    }

    my $whitelist = $self->__get_config->get('whitelist_numbers') // '';

    my %whitelist = map { $_ => 1 } 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, -1, -2, -3, -4, -5, -6, -7, -8, -9, split /\s*,\s*/, $whitelist;

    %firstSeen = ();
    for my $el (@{ $doc->find('PPI::Token::Number') ||[]}) {
        my $val = $el->content;
        next if $whitelist{"$val"};
        if ($firstSeen{"$val"}) {
            push @violations, $self->violation(
                "A duplicate numerical literal at line: " . $el->line_number . ", column: " . $el->column_number,
                "Another string literal in the same piece of code.",
                $el,
            );
        } else {
            $firstSeen{"$val"} = $el->location;
        }
    }

    return @violations;
}

1;

__END__

=head1 NAME

TooMuchCode::ProhibitDuplicateLiteral - Don't repeat yourself with identical literals

=head1 DESCRIPTION

This policy checks if there are string/number literals with identical
value in the same piece of perl code. Usually that's a small signal of
repeating and perhaps a small chance of refactoring.

Certain numbers are whitelisted and not being checked in this policy
because they are conventionally used everywhere.

The default whitelist is 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, -1, -2, -3, -4, -5, -6, -7, -8, -9

To opt-out more, add C<whitelist_numbers> like this in C<.perlcriticrc>

    [TooMuchCode:ProhibitDuplicateLiteral]
    whitelist_numbers = 42, 10

This configurable parameter appends to the default whitelist and there
are no way to remove the default whitelist.

A string literal with its numerical literal counterpart with same
value (C<1> vs C<"1">) are considered to be two distinct values.
Since it's a bit rare to explicitly hard-code number as string literals,
it shouldn't make much difference otherwise. However this is just
an arbitrary choice and might be adjusted in future versions.

=cut
