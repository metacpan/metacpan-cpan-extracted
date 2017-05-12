package Term::Caca::Event::Mouse::Button;
BEGIN {
  $Term::Caca::Event::Mouse::Button::AUTHORITY = 'cpan:YANICK';
}
{
  $Term::Caca::Event::Mouse::Button::VERSION = '1.2.0';
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

method index {
    return Term::Caca::_get_event_mouse_button( $self->_event );
}

method left { return 1 == $self->index }
method right { return 3 == $self->index }
method middle { return 2 == $self->index }


1;



__END__
=pod

=head1 NAME

Term::Caca::Event::Mouse::Button

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

