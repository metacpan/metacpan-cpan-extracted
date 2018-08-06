package Perl::Critic::Policy::TooMuchCode::ProhibitLargeTryBlock;

use strict;
use warnings;
use Perl::Critic::Utils;
use parent 'Perl::Critic::Policy';

sub default_themes       { return qw(maintenance)     }
sub applies_to           { return 'PPI::Structure::Block' }

sub violates {
    my ( $self, $elem, $doc ) = @_;
    my $limit = $self->{try_block_statement_count_limit} || 10;

    return unless $self->__use_try_tiny($doc);
    my @violations;

    my $word_before = $elem->sprevious_sibling;
    return unless $word_before && $word_before->isa('PPI::Token::Word') && $word_before->content eq 'try';

    my $s = $elem->find('PPI::Statement') or return;
    my $statement_count = @$s;
    return unless $statement_count > $limit;

    return $self->violation('try block is too large', "The statement count in this block is ${statement_count}, larger then the limit of ${limit}", $elem);
}

sub __use_try_tiny {
    my ($self, $elem) = @_;
    my $includes = $elem->find('PPI::Statement::Include') or return 0;
    return 0 < grep { $_->module eq 'Try::Tiny' } @$includes;
}

1;

=encoding utf-8

=head1 NAME

TooMuchCode::ProhibitLargeTryBlock -- Find oversized `try..catch` block.

=head1 DESCRIPTION

You may or may not consider it a bad idea to have a lot of code in a
C<try> block.  If you do, this module can be used to catch the
oversized try blocks.

=cut
