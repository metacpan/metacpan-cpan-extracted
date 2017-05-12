package Net::Async::Webservice::Common::Types;
$Net::Async::Webservice::Common::Types::VERSION = '1.0.2';
{
  $Net::Async::Webservice::Common::Types::DIST = 'Net-Async-Webservice-Common';
}
use strict;
use warnings;
use Type::Library
    -base,
    -declare => qw( AsyncUserAgent SyncUserAgent
                    HTTPRequest
              );
use Type::Utils -all;
use namespace::autoclean;

# ABSTRACT: common types for async webservice clients


duck_type AsyncUserAgent, [qw(GET POST do_request)];
duck_type SyncUserAgent, [qw(get post request)];

coerce AsyncUserAgent, from SyncUserAgent, via {
    require Net::Async::Webservice::Common::SyncAgentWrapper;
    Net::Async::Webservice::Common::SyncAgentWrapper->new({ua=>$_});
};


class_type HTTPRequest, { class => 'HTTP::Request' };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::Common::Types - common types for async webservice clients

=head1 VERSION

version 1.0.2

=head1 Types

=head2 C<AsyncUserAgent>

Duck type, any object with a C<do_request>, C<GET> and C<POST>
methods.  Coerced from L</SyncUserAgent> via
L<Net::Async::Webservice::Common::SyncAgentWrapper>.

=head2 C<SyncUserAgent>

Duck type, any object with a C<request>, C<get> and C<post> methods.

=head2 C<HTTPRequest>

Class type for L<HTTP::Request>.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
