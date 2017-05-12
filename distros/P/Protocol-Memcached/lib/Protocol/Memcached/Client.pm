package Protocol::Memcached::Client;
{
  $Protocol::Memcached::Client::VERSION = '0.004';
}
use strict;
use warnings;
use parent qw(Protocol::Memcached);

=head1 NAME

Protocol::Memcached::Client - memcached client binary protocol implementation

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 package Subclass::Of::Protocol::Memcached;
 use parent qw(Protocol::Memcached::Client);

 sub write { $_[0]->{socket}->write($_[1]) }

 package main;
 my $mc = Subclass::Of::Protocol::Memcached->new;
 my ($k, $v) = ('hello' => 'world');
 $mc->set(
   $k => $v,
   on_complete => sub {
     $mc->get(
       'key',
       on_complete => sub { my $v = shift; print "Had $v\n" },
       on_error => sub { die "Failed because of @_\n" },
     );
   }
 );

=head1 DESCRIPTION

Bare minimum protocol support for memcached. This class is transport-agnostic and as
such is not a working implementation - you need to subclass and provide your own ->write
method.

If you're using this class, you're most likely doing it wrong - head over to the
L</SEE ALSO> section to rectify this.

=head1 SUBCLASSING

Provide the following method:

=head2 write

This will be called with the data to be written, and zero or more named parameters:

=over 4

=item * on_flush - coderef to execute when the data has left the building, if this is
not supported by the transport layer then the subclass should call the coderef
before returning

=back

and when you have data, call L</on_read>.

=cut


1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.
