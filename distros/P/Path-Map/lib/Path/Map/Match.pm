package Path::Map::Match;

use strict;
use warnings;

sub new {
    my ($class, %attributes) = @_;
    return bless \%attributes, $class;
}

sub mapper { $_[0]->{mapper} }
sub values { $_[0]->{values} }
sub handler { $_[0]->mapper->_target }

sub variables {
    my $self = shift;

    my %vars;
    @vars{ @{ $self->mapper->_variables } } = @{ $self->values };

    return \%vars;
}

1;

__END__

=head1 NAME

Path::Map::Match - Match object for Path::Map

=head1 DESCRIPTION

This object contains the match state from a L<Path::Map>
L<lookup|Path::Map/lookup>.

=head1 METHODS

=head2 new

The constructor. Should not be called directly, these objects should always be
instantiated via L<Path::Map/lookup>.

=head2 handler

The handler that this match points to. This is identical to whatever was
originally passed to L<Path::Map/add_handler>.

=head2 variables

A hashref of variables matched against the path.

For example given the path_template C<root/:var>, a path C<root/foo> would
yield a result of C<< { var => 'foo' } >>.

=head2 values

An arrayref of variable values, without names, in the order in which they
appeared in the path.

=head2 mapper

The L<Path::Map> object which matched, this is normally an object nested
inside the main "root" mapper.

=head1 AUTHOR

Matt Lawrence E<lt>mattlaw@cpan.orgE<gt>

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
