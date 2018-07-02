package Perl::Critic::Policy::TooMuchCode::ProhibitLargeTryBlock;

use strict;
use warnings;
use Perl::Critic::Utils;
use parent 'Perl::Critic::Policy';

our $VERSION = '0.01';

sub default_themes       { return qw(maintenance)     }
sub applies_to           { return 'PPI::Document' }

sub violates {
    my ( $self, $elem, $doc ) = @_;
    my $limit = $self->{try_block_statement_count_limit} || 10;

    my @violations;

    return @violations unless $self->__use_try_tiny($elem);

    for my $try_keyword (@{ $elem->find(sub { $_[1]->isa('PPI::Token::Word') && $_[1]->content eq "try" }) ||[]}) {
        my $try_block = $try_keyword->snext_sibling or next;
        next unless $try_block->isa('PPI::Structure::Block');

        my $s = $try_block->find('PPI::Statement') or next;
        my $statement_count = @$s;
        next unless $statement_count > $limit;

        push @violations, $self->violation("try block is too large", "The statement count in this block is ${statement_count}, larger then the limit of ${limit}", $try_block);
    }

    return @violations;
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
C<try> block.  And if you do, this module can be used to catch the
oversize try blocks.

=cut
