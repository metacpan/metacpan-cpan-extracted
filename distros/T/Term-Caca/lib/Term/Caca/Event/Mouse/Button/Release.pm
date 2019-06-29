package Term::Caca::Event::Mouse::Button::Release;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: event triggered by a button release 
$Term::Caca::Event::Mouse::Button::Release::VERSION = '3.1.0';

use Moo;
extends qw/ Term::Caca::Event::Mouse::Button /;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Term::Caca::Event::Mouse::Button::Release - event triggered by a button release 

=head1 VERSION

version 3.1.0

=head1 DESCRIPTION 

Extends L<Term::Caca::Event::Mouse::Button>.

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
