package Term::Caca::Event::Resize;
BEGIN {
  $Term::Caca::Event::Resize::AUTHORITY = 'cpan:YANICK';
}
{
  $Term::Caca::Event::Resize::VERSION = '1.2.0';
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

method width {
    return Term::Caca::_get_event_resize_width( $self->_event );
}

method height {
    return Term::Caca::_get_event_resize_height( $self->_event );
}

method size {
    return( $self->width, $self->height );
}

1;



__END__
=pod

=head1 NAME

Term::Caca::Event::Resize

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

