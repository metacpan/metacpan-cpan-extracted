package Term::Caca::Event;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: base class for Term::Caca events
$Term::Caca::Event::VERSION = '3.1.0';

use Moo;

use FFI::Platypus::Memory;

has event => (
    is => 'ro',
    required => 1,
    predicate => 1,
);

has type => (
    is => 'ro',
    lazy => 1,
    default => sub {
        ( ref $_[0] ) =~ s/Term::Caca::Event:://r;
    }
);

sub DEMOLISH {
    my $self = shift;

    free $self->event if $self->has_event;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Term::Caca::Event - base class for Term::Caca events

=head1 VERSION

version 3.1.0

=head1 DESCRIPTION

This class is inherited by the C<Term::Caca::Event::*>
classes, and shouldn't be used directly.

=head1 ATTRIBUTES

=head2 event 

Required. The underlying caca event structure.

=head2 type 

Holds the name of the event (which is the 
name of the class without the 
leading C<Term::Caca::Event::>.

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
