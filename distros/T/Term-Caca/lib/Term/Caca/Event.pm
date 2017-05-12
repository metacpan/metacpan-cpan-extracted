package Term::Caca::Event;
BEGIN {
  $Term::Caca::Event::AUTHORITY = 'cpan:YANICK';
}
{
  $Term::Caca::Event::VERSION = '1.2.0';
}
# ABSTRACT: base class for Term::Caca events


use strict;
use warnings;

use Method::Signatures;
use Term::Caca;

sub new {
    my $self = bless {}, shift;

    my %args = @_;

    $self->{event} = $args{event};

    return $self;
}

method _event { $self->{event} }

sub DESTROY {
    my $self = shift;

    Term::Caca::_free_event($self->_event) if $self->_event;
}

1;


__END__
=pod

=head1 NAME

Term::Caca::Event - base class for Term::Caca events

=head1 VERSION

version 1.2.0

=head1 DESCRIPTION

This class is inherited by the C<Term::Caca::Event::*>
classes, and shouldn't be used directly.

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

