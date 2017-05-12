package Net::Riak::Types;
{
  $Net::Riak::Types::VERSION = '0.1702';
}

use MooseX::Types::Moose qw/Str ArrayRef HashRef/;
use MooseX::Types::Structured qw(Tuple Optional Dict);
use MooseX::Types -declare =>
  [qw(Socket Client HTTPResponse HTTPRequest RiakHost)];

class_type Socket,       { class => 'IO::Socket::INET' };
class_type Client,       { class => 'Net::Riak::Client' };
class_type HTTPRequest,  { class => 'HTTP::Request' };
class_type HTTPResponse, { class => 'HTTP::Response' };

subtype RiakHost, as ArrayRef [HashRef];

coerce RiakHost, from Str, via {
    [ { node => $_, weight => 1 } ];
};

1;

__END__

=pod

=head1 NAME

Net::Riak::Types

=head1 VERSION

version 0.1702

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>, robin edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
