package String::Eertree::Node;

use Moo;

has length     => (is => 'ro',  required => 1);
has pos        => (is => 'rwp', required => 1);
has link       => (is => 'rwp');
has edge       => (is => 'lazy', predicate => 1, builder => sub { {} }, );
has count      => (is => 'rwp', default => 1);
has step_tally => (is => 'rwp', default => 1);

sub increment_count {
    my ($self, $count) = @_;
    $self->_set_count(($count // 1) + $self->count);
}

sub string {
    my ($self, $eertree) = @_;
    return substr $eertree->string, $self->pos, $self->length
}

=head1 NAME

String::Eertree::Node - Represents a single node in a String::Eertree

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

You can study the implementation if you're interested in how eertrees
work. Otherwise, just use C<String::Eertree>.

=cut

__PACKAGE__
