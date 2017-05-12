package TM::ObjectAble;

use strict;
use warnings;

use Data::Dumper;

use Class::Trait 'base';

=pod

=head1 NAME

TM::Synchronizable - Topic Maps, trait for storing objects into backends

=head1 SYNOPSIS

   my $tm = ....          # get a topic map from somewhere
   use Class::Trait;
   Class::Trait->apply ($tm, "TM::ObjectAble");

   my %store;            # find yourself a proper store, can be anything HASHish
                         # append it to the list of stores, or ....
   push @{ $tm->storages }, \%store;
                         # prepend it to the list of stores
   unshift @{ $tm->storages }, \%store;

   # store it (the proper storage will take it)
   $tm->objectify ('tm:some-topic', "whatever object or data");

   # get it back
   my @objects = $tm->object ('tm:some-topic', 'tm:some-topic2');

   # get rid of it
   $tm->deobjectify ('tm:some-topic');

=cut

=head1 DESCRIPTION

This trait implements functionality to store arbitrary data on a per-topic basis.

Conceptually, the storage can be thought as one large hash, as keys being use the internal topic
identifiers, as values the object data. But to allow different topics to store their object data in
different places, this interface works with a list of such hashes. Each hash (native or tied to some
implementation) in the list is visited (starting from the start of the list) and can take over the
storage. Whether this is based on the topic id, on some other topic information, or on the MIME type
of the data (if it has one), is up to the implementation to decide.

=head1 INTERFACE

=head2 Methods

=over

=item B<storages>

I<$listref> = I<$tm>->storages


This method returns an array reference. You can C<unshift> or C<push> your storage implementation
onto this list.

Example:

    my %store1;
    push @{ $tm->storages }, \%store1


=cut

sub storages {
    my $self = shift;
    $self->{'.storages'} //= [];
    return $self->{'.storages'}
}

=pod

=item B<objectify>

I<$tm>->objectify (I<$tid> => I<$some_data>, ...);

This method stores actually the data. It takes a hash, with the topic id as keys and according
values and tries to find for each of the pairs an appropriate storage. If none can be found, it will
raise an exception.

B<NOTE>: Yes, this is a stupid name.

=cut

sub objectify {
    my $self = shift;
    my $storages = $self->{'.storages'};
    my %bs = @_;

OBJECT:
    while (my ($tid, $obj) = each %bs) {              # go through the parameter list
	foreach my $store (@$storages) {              # now look at all registered storages
	    next OBJECT if $store->{$tid} = $obj;     # find the one which actually stores it (by returning the value)
	}
	die "no storage dispatched for $tid";         # if no storage found itself => exception raised
    }
}

=pod

=item B<deobjectify>

I<$tm>->deobjectify (I<$tid>, ...)

This method removes any data stored for the provided topic(s). If no data can be found in the
appropriate storage, an exception will be raised.

=cut

sub deobjectify {
    my $self = shift;
    my $storages = $self->{'.storages'};

OBJECT:
    foreach my $tid (@_) {                            # go through the parameter list
	foreach my $store (@$storages) {              # now look at all registered storages
	    next OBJECT if delete $store->{$tid};     # find the one which actually stored it (by returning the value)
	}
	die "no storage dispatched for $tid";         # if no storage found itself => exception raised
    }

}

=pod

=item B<object>

I<@objects> = I<$tm>->object (I<$tid>, ...)

This method returns any data stored for the provided objects. If no data can be found for a
particular topic, then C<undef> will be returned.

=cut

sub object {
    my $self = shift;
    my $storages = $self->{'.storages'};

    my @os;
    foreach my $tid (@_) {
	my $o;
	foreach my $store (@$storages) {              # now look at all registered storages
	    ($o = $store->{$tid}) and last;              # find the one which actually stored it (by returning the value)
	}
	push @os, $o;
    }
    return @os;
}

=pod

=back

=head1 SEE ALSO

L<TM>

=head1 AUTHOR INFORMATION

Copyright 20(10), Robert Barta <drrho@cpan.org>, All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.  http://www.perl.com/perl/misc/Artistic.html

=cut

our $VERSION = 0.1;

1;

__END__

