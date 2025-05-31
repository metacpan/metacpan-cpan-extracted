package Pithub::ResultSet;
our $AUTHORITY = 'cpan:PLU';

# Honestly stolen from Array::Iterator, removed all unused parts

use strict;
use warnings;

our $VERSION = '0.01043';

sub new {
    my ( $class, @array ) = @_;
    my $_array   = $array[0];
    my $iterator = {
        _current_index => 0,
        _length        => 0,
        _iteratee      => [],
        _iterated      => 0,
    };
    bless $iterator => $class;
    $iterator->_init( scalar @{$_array}, $_array );
    return $iterator;
}

sub _init {
    my ( $self, $length, $iteratee ) = @_;
    $self->{_current_index} = 0;
    $self->{_length}        = $length;
    $self->{_iteratee}      = $iteratee;
}

sub _get_item {
    my ( $self, $iteratee, $index ) = @_;
    return $iteratee->[$index];
}

## no critic (NamingConventions::Capitalization)
sub getNext {
    my $self = shift;
    $self->{_iterated} = 1;
    $self->{_current_index} < $self->{_length} or return undef;
    return $self->_get_item( $self->{_iteratee}, $self->{_current_index}++ );
}

sub getLength {
    my $self = shift;
    return $self->{_length};
}

1;

=pod

=encoding UTF-8

=head1 NAME

Pithub::ResultSet - Iterate over the results

=head1 VERSION

version 0.01043

=head1 SYNOPSIS

  use Pithub::ResultSet ();

  see L<Pithub::Result>

=head1 DESCRIPTION

Iterate over items in the result-set.

=head1 METHODS

=head2 B<new ($content)>

Constructor

=head2 B<getLength>

Get length of result-set.

=head2 B<getNext>

Get next item in the result-set.

=head1 SEE ALSO

=over 4

=item B<Array::Iterator>

=back

=head1 AUTHOR

H.Merijn Brand E<lt>hmbrand@cpan.orgE<gt>

=head1 ORIGINAL AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>
perlancar E<lt>perlancar@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Code derived from Array::Iterator, stripped down to only what is required

=head1 AUTHOR

Johannes Plunien <plu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Johannes Plunien.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Iterate over the results

