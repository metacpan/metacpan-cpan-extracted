package Perl::Critic::Policy::TooMuchCode::ProhibitLargeBlock;

use strict;
use warnings;
use List::Util qw(first);
use Perl::Critic::Utils;
use parent 'Perl::Critic::Policy';

sub default_themes       { return qw(maintenance)     }
sub applies_to           { return 'PPI::Structure::Block' }

sub violates {
    my ( $self, $elem, $doc ) = @_;
    my $limit = $self->{block_statement_count_limit} || 10;

    my $word_before = $elem->sprevious_sibling;
    return unless $word_before && $word_before->isa('PPI::Token::Word');

    my ($block_keyword) = first { $_ eq $word_before->content } qw(map grep do);
    return unless $block_keyword;

    my $s = $elem->find('PPI::Statement') or return;
    my $statement_count = @$s;

    return unless $statement_count > $limit;

    return $self->violation('Oversize block', "The statement count in this ${block_keyword} block is ${statement_count}, larger than the limit of ${limit}", $elem);
}

1;

=encoding utf-8

=head1 NAME

TooMuchCode::ProhibitLargeBlock -- Find oversized blocks

=head1 DESCRIPTION

This policy scan for large code blocks of the following type.

    map { ... };
    grep { ... };
    do { ... };

=cut
