package Net::FleetDB;
use warnings;
use strict;
use Carp qw(croak);
use IO::Socket::INET;
use JSON::XS::VersionOneAndTwo;
our $VERSION = '0.33';

sub new {
    my ( $class, %args ) = @_;

    my $host = delete $args{host} || '127.0.0.1';
    my $port = delete $args{port} || 3400;

    my $socket = IO::Socket::INET->new(
        PeerHost => $host,
        PeerPort => $port,
        Timeout  => 60
    ) || die "Error connecting to $host:$port: $!";

    my $self = bless {
        host   => $host,
        port   => $port,
        socket => $socket,
    }, $class;
    return $self;
}

sub query {
    my ( $self, @args ) = @_;
    my $socket  = $self->{socket};
    my $request = to_json( \@args );
    warn "-> $request\n" if 0;
    $socket->print( $request . "\n" ) || die $!;
    my $response = $socket->getline || die $!;
    warn "<- $response" if 0;
    my $return = from_json($response);

    if ( $return->[0] != 0 ) {
        croak( $return->[1] );
    } else {
        return $return->[1];
    }
}

1;

__END__

=head1 NAME

Net::FleetDB - Query FleetDB

=head1 SYNOPSIS

  my $fleetdb = Net::FleetDB->new(
      host => '127.0.0.1',
      port => 3400,
  );
  my $updates = $fleetdb->query( 'insert', 'people',
    { 'id' => 1, 'name' => 'Bob' } );
  my $people = $fleetdb->query( 'select', 'people',
    { 'order' => [ 'id', 'asc' ] } )

=head1 DESCRIPTION

FleetDB is a "schema-free database optimized for agile development".
Read more about it including the types of queries you can run at
http://fleetdb.org/

This module allows you to query a FleetDB database.

=head1 AUTHOR

Leon Brocard <acme@astray.com>.

=head1 COPYRIGHT

Copyright (C) 2010, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
