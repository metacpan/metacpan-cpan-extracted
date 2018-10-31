package Perl::Critic::Policy::TooMuchCode::ProhibitDuplicateSub;
# ABSTRACT: When 2 subroutines are defined with the same name, report the first one.

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
            "Aonther subroutine definition latter in the same scope with identical name masks this one.",
            $_,
        );
    } @duplicates;

    return @violations;
}

1;
