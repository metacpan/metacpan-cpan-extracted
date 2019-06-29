package Term::Caca::Event::Mouse::Motion;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: event triggered by mouse movements.
$Term::Caca::Event::Mouse::Motion::VERSION = '3.1.0';
use Moo;
extends 'Term::Caca::Event';

use Term::Caca;

has x => 
    is => 'ro',
    lazy => 1,
    default => sub { Term::Caca::caca_get_event_mouse_x( $_[0]->event ) };

has y => 
    is => 'ro',
    lazy => 1,
    default => sub { Term::Caca::caca_get_event_mouse_y( $_[0]->event ) };

has pos => 
    is => 'ro',
    lazy => 1,
    default => sub { [ $_[0]->x, $_[0]->y ] };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Term::Caca::Event::Mouse::Motion - event triggered by mouse movements.

=head1 VERSION

version 3.1.0

=head1 AUTHORS

=over 4

=item *

John Beppu <beppu@cpan.org>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019, 2018, 2013, 2011 by John Beppu.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut
