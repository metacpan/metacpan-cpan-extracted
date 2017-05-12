package Net::Squid::Purge;

use warnings;
use strict;
use English;

use base qw(Class::Accessor);

use Data::Dumper;

our $VERSION = '0.1';

sub new {
    my ($class, %args) = @_;
    my $type = $args{'type'} || 'HTTP';
	my $newclass = $class.'::'.$type;
	eval "use $newclass";
    $class = $EVAL_ERROR ? 'Net::Squid::Purge::HTTP' : $newclass;
    my $self = bless { %args }, $class;
    return $self;
}

sub purge { return 0; }

sub format_purge { return 0; }

1;
__END__

=pod

=head1 NAME

Net::Squid::Purge - Send purge requests to squid easily

=head1 SYNOPSIS

Allows you to send multiple purge requests to one or more squid servers
easily.

  use Net::Squid::Purge;
  my @squid_servers = (
    { host => '192.168.100.3' },
    { host => '192.168.100.4', port => '8080' },
  );
  my $purger = Net::Squid::Purge->new;
  $purger->squid_servers(\@squid_servers);
  $purger->purge('http://localhost/', 'http://localhost/home/');

=head1  How can I purge an object from my cache?

As taken directly from the squid docs:

A purge feature was added to Squid-1.1.6. It only allowed you to purge HTTP
objects until Squid-1.1.11. Squid does not allow you to purge objects unless
it is configured with access controls in squid.conf. First you must add
something like

  acl PURGE method purge
  acl localhost src 127.0.0.1
  http_access allow purge localhost
  http_access deny purge

The above only allows purge requests which come from the local host and denies
all other purge requests.

To purge an object, you can use the client program:

 squidclient -m PURGE http://www.miscreant.com/

If the purge was successful, you will see a '200 OK' response:

  HTTP/1.0 200 OK
  Date: Thu, 17 Jul 1997 16:03:32 GMT
  Server: Squid/1.1.14

If the object was not found in the cache, you will see a '404 Not Found'
response:

  HTTP/1.0 404 Not Found
  Date: Thu, 17 Jul 1997 16:03:22 GMT
  Server: Squid/1.1.14

=head1 FUNCTIONS

=head2 purge

Attempt to purge a set of urls from the squid cache. 

=head2 format_purge

This returns the PURGE request that is sent.

=head2 new

Creates the object.

=head1 AUTHORS

Nick Gerakines, C<< <nick at socklabs.com> >>

Paul Lindner, C<< <lindner at inuus.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-squid-purge at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Squid-Purge>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Squid::Purge

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Squid-Purge>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Squid-Purge>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Squid-Purge>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Squid-Purge>

=item * Squid cache purging documentation

L<http://meta.wikimedia.org/wiki/Squid_caching>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Nick Gerakines, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
