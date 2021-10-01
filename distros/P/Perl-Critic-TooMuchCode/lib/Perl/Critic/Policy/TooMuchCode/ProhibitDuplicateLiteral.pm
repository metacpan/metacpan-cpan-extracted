package Perl::Critic::Policy::TooMuchCode::ProhibitDuplicateLiteral;
use strict;
use warnings;
use List::Util 1.33 qw(any);
use Perl::Critic::Utils;
use PPI;
use parent 'Perl::Critic::Policy';

sub default_themes       { return qw( bugs maintenance )     }
sub applies_to           { return 'PPI::Document' }

sub supported_parameters {
    return ({
        name           => 'allowlist',
        description    => 'A list of numbers or quoted strings that can be allowed to occur multiple times.',
        default_string => "0 1",
        behavior       => 'string',
        parser         => \&_parse_allowlist,
    });
}

sub _parse_allowlist {
    my ($self, $param, $value) = @_;
    my $default = $param->get_default_string();

    my %allowlist;
    for my $v (grep { defined } ($default, $value)) {
        my $parser = PPI::Document->new(\$v);
        for my $token (@{$parser->find('PPI::Token::Number') ||[]}) {
            $allowlist{ $token->content } = 1;
        }
        for my $token (@{$parser->find('PPI::Token::Quote') ||[]}) {
            $allowlist{ $token->string } = 1;
        }
    }
    $self->{_allowlist} = \%allowlist;
    return undef;
}

sub violates {
    my ($self, undef, $doc) = @_;
    my %firstSeen;
    my @violations;

    for my $el (@{ $doc->find('PPI::Token::Quote') ||[]}) {
        next if $el->can("interpolations") && $el->interpolations();

        my $val = $el->string;
        next if $self->{"_allowlist"}{$val};

        if ($firstSeen{"$val"}) {
            push @violations, $self->violation(
                "A duplicate literal value at line: " . $el->line_number . ", column: " . $el->column_number,
                "Another literal value in the same piece of code.",
                $el,
            );
        } else {
            $firstSeen{"$val"} = $el->location;
        }
    }

    for my $el (@{ $doc->find('PPI::Token::Number') ||[]}) {
        my $val = $el->content;
        next if $self->{"_allowlist"}{$val};
        if ($firstSeen{$val}) {
            push @violations, $self->violation(
                "A duplicate literal value at line: " . $el->line_number . ", column: " . $el->column_number,
                "Another literal value in the same piece of code.",
                $el,
            );
        } else {
            $firstSeen{$val} = $el->location;
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

=head1 CONFIGURATION

Some strings/numbers may be allowed to have duplicates by listing them
in the C<allowlist> parameter in the configs:

    [TooMuchCode::ProhibitDuplicateLiteral]
    allowlist = 'present' "forty two" 42

The values is a space-separated list of numbers or quoted string.

The default values in the allowlist are: C<0 1>. These two numbers are
always part of allowlist and cannot be removed.

Please be aware that, a string literal and its numerical literal
counterpart (C<1> vs C<"1">) are considered to be the same. Adding
C<"42"> to the allowlist is the same as adding C<42>.

=cut
