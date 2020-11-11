package Perl::Critic::Policy::TooMuchCode::ProhibitDuplicateSub;
use strict;
use warnings;
use Perl::Critic::Utils;
use parent 'Perl::Critic::Policy';

sub default_themes       { return qw( bugs maintenance )     }
sub applies_to           { return 'PPI::Document' }

sub violates {
    my ($self, undef, $doc) = @_;
    my $subdefs = $doc->find('PPI::Statement::Sub') or return;

    my %seen;
    my @duplicates;
    for my $sub (@$subdefs) {
        next if $sub->forward || (! $sub->name);

        if (exists $seen{ $sub->name }) {
            push @duplicates, $seen{ $sub->name };
        }
        $seen{ $sub->name } = $sub;
    }

    my @violations = map {
        my $last_sub = $seen{ $_->name };

        $self->violation(
            "Duplicate subroutine definition. Redefined at line: " . $last_sub->line_number . ", column: " . $last_sub->column_number,
            "Another subroutine definition latter in the same scope with identical name masks this one.",
            $_,
        );
    } @duplicates;

    return @violations;
}

1;

=encoding utf-8

=head1 NAME

TooMuchCode::ProhibitDuplicateSub - When 2 subroutines are defined with the same name, report the first one.

=head1 DESCRIPTION

This policy checks if there are subroutine definitions with identical names
under the same namespace. If they exists, all but the last one are marked as
violation.

perl runtime allows a named subroutine to be redefined in the same source file
and the latest definition wins. In the event that this is done by developers,
preferably unintentionally, perl runtime warns about a subroutine is
redefined with the position is for the one that wins. This policy does the
opposite.

Although the last one is not marked as a violation, it's position is
reported together. Making it easier for developer to locate the subroutine.

Should the developer decide to programmatically remove the duplicates,
simply go through all the violations and remove those statements.

=cut
