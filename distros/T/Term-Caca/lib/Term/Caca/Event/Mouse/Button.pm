package Term::Caca::Event::Mouse::Button;
our $AUTHORITY = 'cpan:YANICK';
$Term::Caca::Event::Mouse::Button::VERSION = '3.1.0';
use Moo;
extends 'Term::Caca::Event';

has index =>
    is => 'ro',
    lazy => 1,
    default => sub {
        Term::Caca::caca_get_event_mouse_button( $_[0]->event );
    };

sub left { return 1 == $_[0]->index }
sub right { return 3 == $_[0]->index }
sub middle { return 2 == $_[0]->index }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Term::Caca::Event::Mouse::Button

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
