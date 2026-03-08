package Perl::Critic::Policy::ControlStructures::ProhibitReturnInMappingBlock;
use 5.008001;
use strict;
use warnings;
use parent 'Perl::Critic::Policy';
use List::Util qw(any);
use Perl::Critic::Utils qw(:severities);
use constant EXPL => 'A "return" in a mapping block causes confusing behavior.';

my @MAPPING_BLOCK_KEYWORDS = qw(map grep sort);

our $VERSION = "0.01";

sub supported_parameters { return (); }
sub default_severity     { return $SEVERITY_HIGHEST; }
sub default_themes       { return qw(bugs complexity); }
sub applies_to           { return 'PPI::Structure::Block'; }

sub violates {
    my ($self, $elem, undef) = @_;

    my $keyword = _mapping_block_keyword($elem);
    return if !$keyword;

    my $desc = sprintf('"return" statement in "%s" block.', $keyword);
    my @stmts = $elem->schildren;
    return if !@stmts;

    my @violations;

    for my $stmt (@stmts) {
        push @violations, $self->violation($desc, EXPL, $stmt) if _is_return($stmt);
    }

    return @violations;
}

sub _mapping_block_keyword {
    my ($elem) = @_;

    return if !$elem->sprevious_sibling;
    my $keyword = $elem->sprevious_sibling->content;
    return $keyword if any { $keyword eq $_ } @MAPPING_BLOCK_KEYWORDS;
    return;
}

sub _is_return {
    my ($stmt) = @_;

    return any { $_->content eq 'return' } $stmt->schildren;
}

1;
__END__

=encoding utf-8

=head1 NAME

Perl::Critic::Policy::ControlStructures::ProhibitReturnInMappingBlock - Do not "return" in mapping blocks (map, grep, sort)

=head1 AFFILIATION

This policy is part of the L<Perl::Critic::Policy::ControlStructures::ProhibitReturnInMappingBlock> distribution.

=head1 DESCRIPTION

Using C<return> in a mapping block (C<map>, C<grep>, or C<sort>) causes unexpected behavior.
A C<return> exits the entire enclosing subroutine, not just the block.

    sub func {
        my @list = (1, 2, 3);
        my @result = map {
            return 0 unless $_; # not ok
            $_ + 5;
        } @list;
        return @result;
    }

If you want to skip an element, use C<next> instead:

    sub func {
        my @list = (1, 2, 3);
        my @result = map {
            next unless $_;
            $_ + 5;
        } @list;
        return @result;
    }

This applies equally to C<grep> and C<sort> blocks.

=head1 CONFIGURATION

This Policy is not configurable except for the standard options.

=head1 SEE ALSO

L<Perl::Critic::Policy::ControlStructures::ProhibitReturnInDoBlock> by utgwkk, which inspired this policy.

=head1 LICENSE

Copyright (C) 2026 hogashi. Portions copyright (C) 2020 utgwkk.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

hogashi

=cut

