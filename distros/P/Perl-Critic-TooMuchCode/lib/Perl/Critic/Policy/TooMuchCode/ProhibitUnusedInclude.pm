package Perl::Critic::Policy::TooMuchCode::ProhibitUnusedInclude;

use strict;
use warnings;
use Perl::Critic::Utils;
use parent 'Perl::Critic::Policy';

sub default_themes       { return qw( maintenance )     }
sub applies_to           { return 'PPI::Document' }

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;
    my @violations = $self->gather_violations_try_family($elem, $doc);
    push @violations, $self->gather_violations_objective($elem, $doc);
    return @violations;
}

sub gather_violations_try_family {
    my ( $self, $elem, $doc ) = @_;

    my @violations;

    my @includes = @{ $elem->find('PPI::Statement::Include') ||[] };
    return @violations unless @includes;

    my $has_try_block = 0;
    for my $try_keyword (@{ $elem->find(sub { $_[1]->isa('PPI::Token::Word') && $_[1]->content eq 'try' }) ||[]}) {
        my $try_block = $try_keyword->snext_sibling or next;
        next unless $try_block->isa('PPI::Structure::Block');
        $has_try_block = 1;
        last;
    }

    for my $try_module (qw(Try::Tiny Try::Catch Try::Lite TryCatch Try)) {
        my @uses = grep { $_->module eq $try_module } @includes;
        if (@uses && !$has_try_block) {
            push @violations, map { $self->violation("Unused ${try_module} module", 'There are no `try` block in the code.', $_) } @uses;
        }
    }

    return @violations;
}

sub gather_violations_objective {
    my ( $self, $elem, $doc ) = @_;

    my @violations;

    for my $class_name (qw(HTTP::Tiny HTTP::Lite LWP::UserAgent File::Spec)) {
        my @include_statements = grep { $_->module eq $class_name } @{ $elem->find('PPI::Statement::Include') ||[] };
        next unless @include_statements;

        my $is_used = $elem->find(
            sub {
                my $el = $_[1];
                $el->isa('PPI::Token::Word') && $el->content eq $class_name && !($el->parent->isa('PPI::Statement::Include'))
            }
        );

        unless ($is_used) {
            push @violations, map {
                $self->violation("Unused ${class_name} module.", "No methods from ${class_name} are invoked.", $_)
            } @include_statements;
        }
    }
    return @violations;
}

1;

=encoding utf-8

=head1 NAME

TooMuchCode::ProhibitUnusedInclude -- Find unused include statements.

=head1 DESCRIPTION

This critic policy scans for unused include statement according to their documentation.

For example, L<Try::Tiny> implicity introduce a C<try> subroutine that takes a block. Therefore, a
lonely C<use Try::Tiny> statement without a C<try { .. }> block somewhere in its scope is considered
to be an "Unused Include".

=cut
