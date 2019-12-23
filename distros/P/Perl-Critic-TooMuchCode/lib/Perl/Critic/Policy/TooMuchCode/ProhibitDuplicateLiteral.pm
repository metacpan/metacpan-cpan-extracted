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

    my $tokens = $doc->find('PPI::Token::Quote') or return;
    for my $el (@$tokens) {
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

    return @violations;
}

1;

__END__

=head1 NAME

TooMuchCode::ProhibitDuplicateLiteral - Don't repeat youself with identical literals

=head1 DESCRIPTION

This policy checks if there are string/number literals with identical value in
the same DOM. Usually that's a small signal of repeating and perhaps a small
chance of refactoring.

=cut
