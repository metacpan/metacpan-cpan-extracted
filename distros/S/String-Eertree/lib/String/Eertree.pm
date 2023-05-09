package String::Eertree;
use warnings;
use strict;

use Syntax::Construct qw{ // };

use Moo;

use String::Eertree::Node;

has nodes => (is => 'ro', default => sub { [
    'String::Eertree::Node'->new(link => 0, length => -1, pos => -1),
    'String::Eertree::Node'->new(link => 0, length =>  0, pos =>  0)
]});
has string          => (is => 'ro',  required => 1);
has max             => (is => 'rwp', default  => 0);
has _count_finished => (is => 'rw',  default => 0);

sub node {
    my ($self, $index) = @_;
    die "Invalid index $index." if $index < 0;

    return $self->nodes->[$index]
}

sub at {
    my ($self, $pos) = @_;
    return substr $self->string, $pos, 1
}

sub BUILD {
    my ($self) = @_;
    my $i = 0;
    $self->add($i++, $_) for split //, $self->string;
};

sub Push {
    my ($self, $node) = @_;
    push @{ $self->nodes }, $node;
}

sub Last { $#{ $_[0]->nodes } }

sub add {
    my ($self, $index, $char) = @_;

    my $new_node;
    my $p = $self->max;
    while ($self->node($p)) {
        my $node = $self->node($p);
        my $pos = $node->length == -1
                ? $index
                : $index - $node->length - 1;
        if ($pos >= 0 && $self->at($pos) eq $char) {
            if (exists $node->edge->{$char}) {
                $new_node = $self->node($node->edge->{$char});
                $new_node->increment_count;
                $self->_set_max($node->edge->{$char});
                return
            }
            $new_node = 'String::Eertree::Node'->new(
                pos    => $pos,
                length => $index - $pos + 1);
            $node->edge->{$char} = $self->Last + 1;
            last
        }
        $p = $node->link;
    }

    $self->Push($new_node);
    $self->_set_max($self->Last);

    if ($new_node->length == 1) {
        $new_node->_set_link(1);
        return
    }

    my $q = $self->node($p)->link;
    while (1) {
        my $pos = $self->node($q)->length == -1
                ? $index
                : $index - $self->node($q)->length - 1;
        if ($pos >= 0 && $self->at($pos) eq $char) {
            $new_node->_set_link($self->node($q)->edge->{$char});
            last
        }
        $q = $self->node($q)->link;
    }
}

sub uniq_palindromes {
    my ($self) = @_;
    return grep length, map $_->string($self), @{ $self->nodes }
}

sub palindromes {
    my ($self) = @_;
    $self->_count;
    return map {
        grep length, ($_->string($self)) x $_->count
    } @{ $self->nodes }
}

sub _count {
    my ($self) = @_;
    return if $self->_count_finished;

    $self->_count_finished(1);
    for my $node (reverse @{ $self->nodes }) {
        $self->node($node->link)->increment_count($node->count);
    }
}

=head1 NAME

String::Eertree - Build the palindromic tree aka Eertree for a string

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

Eertrees make it possible to find palindrome substrings of a string in a very
fast way.

    use String::Eertree;

    my $tree = 'String::Eertree'->new(string => 'referee');
    my @palindromes = $tree->uniq_palindromes;  # r e f efe refer ere ee

To see how fast it is, check the file F<examples/rosetta-code.pl>. It compares
the speed of the Eertree algorithm to a naive generation of all the unique
palindromes as found at L<Rosetta
Code|https://rosettacode.org/wiki/Eertree#Perl>. Eertree is almost 40 times
faster on a string of length 79.

=head1 METHODS

=head2 new

  'String::Eertree'->new(string => 'xxx')

The constructor. Use the named argument C<string> to specify the string you
want to analyse.

=head2 string

  my $string = $tree->string;

The original string the tree was constructed from (see above).

=head2 uniq_palindromes

  my @palindromes = $tree->uniq_palindromes;

Returns all distinct palindrome substrings of the string.

=head2 palindromes

  my @palindromes = $tree->palindromes;

Returns all the palindrome substrings of the string, each substring can be
repeated if it's present at different positions in the string.

=head1 AUTHOR

E. Choroba, C<< <choroba at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-string-eertree at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=string-eertree>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc String::Eertree


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=string-eertree>

=item * Search CPAN

L<https://metacpan.org/release/string-eertree>

=back

=head1 ACKNOWLEDGEMENTS

Thanks Mohammad S Anwar (MANWAR) for introducing me to the idea.

Thanks L<shubham2508|https://github.com/shubham2508> for a clean Python
implementation.

Thanks Mikhail Rubinchik and Arseny M. Shur for inventing the eertree
(arXiv:1506.04862v2 [cs.DS] 17 Aug 2015).

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022-2023 by E. Choroba.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__PACKAGE__
