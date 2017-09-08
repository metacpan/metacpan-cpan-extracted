package Net::Easypost::Resource;
$Net::Easypost::Resource::VERSION = '0.21';
use Moo::Role;

use Carp qw(croak);
use Net::Easypost::Request;

# all Net::Easypost::Resource objects must implement clone and serialize
requires qw(serialize clone);

has id => (
   is => 'rwp',
);

has 'operation' => (
   is      => 'ro',
   builder => 1,
);

has 'role' => (
   is      => 'ro',
   builder => 1,
);

has 'fieldnames' => (
   is      => 'ro',
   builder => 1,
);

has 'requester' => (
   is      => 'ro',
   default => sub { Net::Easypost::Request->new },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Easypost::Resource

=head1 VERSION

version 0.21

=head1 SYNOPSIS

=head1 NAME 

Net::Easypost::Resource

=head1 ATTRIBUTES

=over 4 

=item id

A unique field that represent this Object to Easypost

=item endpoint

base API operation endpoint for this Object

=item role

Role of this object: address, shipment, parcel, etc...

=item fieldnames

attributes of this Object in the Easypost API

=item requester

HTTP client to make GET & POST requests

=back

=head1 AUTHOR

Mark Allen <mrallen1@yahoo.com>, Hunter McMillen <mcmillhj@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Mark Allen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
