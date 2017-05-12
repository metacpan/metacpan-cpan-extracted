package Net::Cassandra;
use Moose;
use MooseX::StrictConstructor;
use Net::Cassandra::Backend::Cassandra;
use Net::Cassandra::Backend::Thrift;
use Net::Cassandra::Backend::Thrift::Socket;
use Net::Cassandra::Backend::Thrift::BufferedTransport;
use Net::Cassandra::Backend::Thrift::BinaryProtocol;

our $VERSION = '0.35';

has 'hostname' => ( is => 'ro', isa => 'Str', default => 'localhost' );
has 'port'     => ( is => 'ro', isa => 'Int', default => 9160 );
has 'client'   => (
    is         => 'ro',
    isa        => 'Net::Cassandra::Backend::CassandraClient',
    lazy_build => 1
);

__PACKAGE__->meta->make_immutable;

sub _build_client {
    my $self = shift;

    my $socket
        = Net::Cassandra::Backend::Thrift::Socket->new( $self->hostname,
        $self->port );
    my $transport
        = Net::Cassandra::Backend::Thrift::BufferedTransport->new($socket);
    my $protocol
        = Net::Cassandra::Backend::Thrift::BinaryProtocol->new($transport);
    my $client = Net::Cassandra::Backend::CassandraClient->new($protocol);

    eval { $transport->open };
    confess $@->{message} if $@;
    return $client;
}

1;

__END__

=head1 NAME

Net::Cassandra - Interface to Cassandra

=head1 SYNOPSIS

  my $cassandra = Net::Cassandra->new( hostname => 'localhost' );
  my $client    = $cassandra->client;

  my $key       = '123';
  my $timestamp = time;

  eval {
      $client->insert(
          'Keyspace1',
          $key,
          Net::Cassandra::Backend::ColumnPath->new(
              { column_family => 'Standard1', column => 'name' }
          ),
          'Leon Brocard',
          $timestamp,
          Net::Cassandra::Backend::ConsistencyLevel::ZERO
      );
  };
  die $@->why if $@;

  eval {
      my $what = $client->get(
          'Keyspace1',
          $key,
          Net::Cassandra::Backend::ColumnPath->new(
              { column_family => 'Standard1', column => 'name' }
          ),
          Net::Cassandra::Backend::ConsistencyLevel::QUORUM
      );
      my $value     = $what->column->value;
      my $timestamp = $what->column->timestamp;
      warn "$value / $timestamp";
  };
  die $@->why if $@;

  eval {
      $client->remove(
          'Keyspace1',
          $key,
          Net::Cassandra::Backend::ColumnPath->new(
              { column_family => 'Standard1', column => 'name' }
          ),
          $timestamp
      );
  };
  die $@->why if $@;

=head1 DESCRIPTION

This module provides an interface the to Cassandra distributed database.
It uses the Thrift interface. This is changing rapidly and supports
version 0.5.0 of Cassandra.

=head1 AUTHOR

Leon Brocard <acme@astray.com>.

=head1 COPYRIGHT

Copyright (C) 2009-2010, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
