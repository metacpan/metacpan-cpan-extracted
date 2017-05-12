package Osgood::Event;
use Moose;
use MooseX::Storage;
use MooseX::AttributeHelpers;

use DateTime;
use DateTime::Format::ISO8601;

with Storage('format' => 'JSON', 'io' => 'File');

has 'id' => ( is => 'rw', isa => 'Int'  );
has 'action' => ( is => 'rw', isa => 'Str', required => 1 );
has 'date_occurred' => (
    is => 'rw',
    isa => 'DateTime',
    default => sub { DateTime->now }
);
has 'object' => ( is => 'rw', isa => 'Str', required => 1 );
has 'params' => (
    metaclass => 'Collection::Hash',
    is => 'rw',
    isa => 'HashRef',
    default => sub{ {} },
    provides => {
        get => 'get_param',
        set => 'set_param'
    }
);

MooseX::Storage::Engine->add_custom_type_handler(
    'DateTime' => (
        expand => sub { DateTime::Format::ISO8601->parse_datetime(shift) },
        collapse => sub { (shift)->iso8601 }
    )
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Osgood::Event - An Osgood Event

=head1 DESCRIPTION

Events are characterized by an object and an action, which could be though
of as a noun and a verb.  The date_occurred is also important and, hopefully,
self-explanatory.  To round out the event there is a params method that
accepts a HashRef for name value pairs.

Note: object and action names are limited to 64 characters.

=head1 SYNOPSIS

  my $event = Osgood::Event->new(object => 'Test', action => 'create');

=head1 METHODS

=head2 new

Creates a new Osgood::Event object.  Requires an object and action.  If no
date_occurred is specifed, then the C<DateTime->now> is used.

=head2 action

The action this event represents.

=head2 date_occurred

The date and time this event occurred

=head2 object

The object this event pertains to.

=head2 params

A HashRef of name-value pairs for this event.

=head2 set_param

Allows setting a single name value pair directly.

=head2 get_param

Get the value of the specifed key.

=head1 AUTHOR

Cory 'G' Watson <gphat@cpan.org>

=head1 SEE ALSO

perl(1), Osgood::EventList

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 by Magazines.com, LLC

You can redistribute and/or modify this code under the same terms as Perl
itself.
