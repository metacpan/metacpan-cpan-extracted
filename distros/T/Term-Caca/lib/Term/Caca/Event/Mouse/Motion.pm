package Term::Caca::Event::Mouse::Motion;
BEGIN {
  $Term::Caca::Event::Mouse::Motion::AUTHORITY = 'cpan:YANICK';
}
{
  $Term::Caca::Event::Mouse::Motion::VERSION = '1.2.0';
}

use strict;
use warnings;

use parent 'Term::Caca::Event';
use Term::Caca;
use Method::Signatures;

sub new {
    my $class = shift;
    return bless $class->SUPER::new( @_ ), $class;
}

method x {
    return Term::Caca::_get_event_mouse_x( $self->_event );
}

method y {
    return Term::Caca::_get_event_mouse_y( $self->_event );
}

method pos {
    return ( $self->x, $self->y );
}

1;

__END__
=pod

=head1 NAME

Term::Caca::Event::Mouse::Motion

=head1 VERSION

version 1.2.0

=head1 AUTHORS

=over 4

=item *

John Beppu <beppu@cpan.org>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by John Beppu.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut

