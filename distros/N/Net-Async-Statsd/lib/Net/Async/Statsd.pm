package Net::Async::Statsd;
# ABSTRACT: IO::Async support for statsd/graphite
use strict;
use warnings;

our $VERSION = '0.005';

=head1 NAME

Net::Async::Statsd - asynchronous API for Etsy's statsd protocol

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 use Future;
 use IO::Async::Loop;
 use Net::Async::Statsd::Client;
 my $loop = IO::Async::Loop->new;
 $loop->add(my $statsd = Net::Async::Statsd::Client->new(
   host => 'localhost',
   port => 3001,
 ));
 Future->needs_all(
  $statsd->timing(
   'some.task' => 133,
  ),
  $statsd->gauge(
   'some.value' => 80,
  )
 )->get;

=head1 DESCRIPTION

Provides an asynchronous API for statsd.

You probably wanted the client implementation - see L<Net::Async::Statsd::Client>.
There's a basic server implementation in L<Net::Async::Statsd::Server>, note that
this does little more than accept traffic and raise events.

If you're not using L<IO::Async>, this module is probably not what you wanted.
See L<Net::Statsd> instead.

=cut

use Net::Async::Statsd::Server;
use Net::Async::Statsd::Client;

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<Net::Statsd> - synchronous implementation

=back

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2014-2016. Licensed under the same terms as Perl itself.
