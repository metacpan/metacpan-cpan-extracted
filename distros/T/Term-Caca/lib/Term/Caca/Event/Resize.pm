package Term::Caca::Event::Resize;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: event triggered when the display is resized
$Term::Caca::Event::Resize::VERSION = '3.1.0';

use Moo;
extends 'Term::Caca::Event';

use Term::Caca;

has width => 
    is => 'ro',
    lazy => 1,
    default => sub {
        Term::Caca::caca_get_event_resize_width( $_[0]->event );
    };

has height => 
    is => 'ro',
    lazy => 1,
    default => sub {
        Term::Caca::caca_get_event_resize_height( $_[0]->event );
    };


has size => 
    is => 'ro',
    lazy => 1,
    default => sub {
        [ $_[0]->width, $_[0]->height ];
    };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Term::Caca::Event::Resize - event triggered when the display is resized

=head1 VERSION

version 3.1.0

=head1 ATTRIBUTES 

=head2 width 

New width of the display.

=head2 height 

New height of the display.

=head2 size 

New size of the display, as an array ref of the width and height.

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
