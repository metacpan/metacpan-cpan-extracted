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
        name           => 'whitelist_numbers',
        description    => 'A comma-separated list of numbers that can be allowed to occur multiple times.',
        default_string => "0, 1, 2, 3, 4, 5, 6, 7, 8, 9, -1, -2, -3, -4, -5, -6, -7, -8, -9",
        behavior       => 'string',
        parser         => \&_parse_whitelist_numbers,
    }, , {
        name           => 'whitelist',
        description    => 'A list of numbers or quoted strings that can be allowed to occur multiple times.',
        default_string => "0 1",
        behavior       => 'string',
        parser         => \&_parse_whitelist,
    });
}

sub _parse_whitelist {
    my ($self, $param, $value) = @_;
    my $default = $param->get_default_string();

    my %whitelist;
    for my $v (grep { defined } ($default, $value)) {
        my $parser = PPI::Document->new(\$v);
        for my $token (@{$parser->find('PPI::Token::Number') ||[]}) {
            $whitelist{ $token->content } = 1;
        }
        for my $token (@{$parser->find('PPI::Token::Quote') ||[]}) {
            $whitelist{ $token->string } = 1;
        }
    }
    $self->{_whitelist} = \%whitelist;
    return undef;
}

sub _parse_whitelist_numbers {
    my ($self, $param, $value) = @_;
    my $default = $param->get_default_string();
    my %nums = map { $_ => 1 } grep { defined($_) && $_ ne '' } map { split /\s*,\s*/ } ($default, $value //'');
    $self->{_whitelist_numbers} = \%nums;
    return undef;
}

sub violates {
    my ($self, undef, $doc) = @_;
    my %firstSeen;
    my @violations;

    for my $el (@{ $doc->find('PPI::Token::Quote') ||[]}) {
        next if $el->can("interpolations") && $el->interpolations();

        my $val = $el->string;
        next if $self->{"_whitelist"}{$val};

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
        next if $self->{"_whitelist_numbers"}{$val};
        next if $self->{"_whitelist"}{$val};
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
in the C<whitelist> parameter in the configs:

    [TooMuchCode:ProhibitDuplicateLiteral]
    whitelist = 'present' "forty two" 42

The values is a space-separated list of numbers or quoted string.

The default values in the whitelist are: C<0 1>. This two numbers are
always part of whitelist and cannot be removed.

Please be aware that, a string literal and its numerical literal
counterpart (C<1> vs C<"1">) are considered to be the
same. Whitelisting C<"42"> would also whitelist C<42> together.

=head1 DEPRECATED CONFIGURATIONS

The C<whitelist> parameter replace another parameter name C<whitelist_numbers>, which serves the same purpose but only numbers were supported.

The default value of whitelist_numbers is 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, -1, -2, -3, -4, -5, -6, -7, -8, -9

To opt-out more, add C<whitelist_numbers> like this in C<.perlcriticrc>

    [TooMuchCode::ProhibitDuplicateLiteral]
    whitelist_numbers = 42, 10

The numbers given to C<whitelist_numbers> are appended and there is no
way to remove default values.

It is still supported in current release but will be removed in near
future. Please check the content of C<Changes>for the announcement.

=cut
