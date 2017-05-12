package Net::Async::Webservice::Common;
$Net::Async::Webservice::Common::VERSION = '1.0.2';
{
  $Net::Async::Webservice::Common::DIST = 'Net-Async-Webservice-Common';
}
use strict;
use warnings;
use 5.010;

# ABSTRACT: Some common classes to write async webservice clients


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::Common - Some common classes to write async webservice clients

=head1 VERSION

version 1.0.2

=head1 DESCRIPTION

This distribution provides a few common roles, types, and classes to
help writing webservice client based on L<Net::Async::HTTP>.

=head2 L<Net::Async::Webservice::Common::WithConfigFile>

Allows loading constructor arguments from a file, via L<Config::Any>.

=head2 L<Net::Async::Webservice::Common::WithUserAgent>

Provides a C<user_agent> attribute, guaranteeing that its value
behaves like L<Net::Async::HTTP>. If a L<LWP::UserAgent>-like object
is passed in, L<Net::Async::Webservice::Common::SyncAgentWrapper> is
used to wrap it.

=head2 L<Net::Async::Webservice::Common::WithRequestWrapper>

Provides a few methods to perform simple HTTP requests and handle
failures.

=head2 L<Net::Async::Webservice::Common::SyncAgentWrapper>

Wraps a L<LWP::UserAgent>-like object in a L<Net::Async::HTTP>-like
interface. Does not support everything that L<Net::Async::HTTP> can
do, but it should be enough for most uses.

=head2 L<Net::Async::Webservice::Common::Types>

A few types, including the coercion from L<LWP::UserAgent>-like to
L<Net::Async::HTTP>-like via
L<Net::Async::Webservice::Common::SyncAgentWrapper>.

=head2 L<Net::Async::Webservice::Common::Exception>

A few exceptions thrown by the other packages.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
