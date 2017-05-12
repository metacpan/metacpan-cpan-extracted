package Net::RackSpace::CloudServers::Server;
$Net::RackSpace::CloudServers::Server::VERSION = '0.15';
use warnings;
use strict;
our $DEBUG = 0;
use Any::Moose;
use HTTP::Request;
use JSON;
use YAML;
use Net::RackSpace::CloudServers::Image;
use Carp;

has 'cloudservers' =>
    (is => 'rw', isa => 'Net::RackSpace::CloudServers', required => 1);
has 'id' => (is => 'ro', isa => 'Int', required => 1, default => 0);
has 'name'     => (is => 'ro', isa => 'Str',        required => 1);
has 'imageid'  => (is => 'ro', isa => 'Maybe[Int]', required => 1);
has 'flavorid' => (is => 'ro', isa => 'Maybe[Int]', required => 1);
has 'hostid' =>
    (is => 'ro', isa => 'Maybe[Str]', required => 1, default => undef);
has 'status' =>
    (is => 'ro', isa => 'Maybe[Str]', required => 1, default => undef);
has 'adminpass' =>
    (is => 'ro', isa => 'Maybe[Str]', required => 1, default => undef);
has 'progress' =>
    (is => 'ro', isa => 'Maybe[Str]', required => 1, default => undef);
has 'public_address' => (
    is       => 'ro',
    isa      => 'Maybe[ArrayRef[Str]]',
    required => 1,
    default  => undef
);
has 'private_address' => (
    is       => 'ro',
    isa      => 'Maybe[ArrayRef[Str]]',
    required => 1,
    default  => undef
);
has 'metadata' =>
    (is => 'ro', isa => 'Maybe[HashRef]', required => 1, default => undef);
has 'personality' =>
    (is => 'ro', isa => 'Maybe[ArrayRef]', required => 1, default => undef);

no Any::Moose;
__PACKAGE__->meta->make_immutable();

sub change_root_password {
    my $self     = shift;
    my $password = shift;
    my $uri      = '/servers/' . $self->id;
    my $request  = HTTP::Request->new(
        'PUT',
        $self->cloudservers->server_management_url . $uri,
        [
            'X-Auth-Token' => $self->cloudservers->token,
            'Content-Type' => 'application/json',
        ],
        to_json({ server => { adminPass => $password, } }));
    my $response = $self->cloudservers->_request($request);
    confess 'Unknown error' if $response->code != 202;
    return $response;
}

sub change_name {
    my $self    = shift;
    my $name    = shift;
    my $uri     = '/servers/' . $self->id;
    my $request = HTTP::Request->new(
        'PUT',
        $self->cloudservers->server_management_url . $uri,
        [
            'X-Auth-Token' => $self->cloudservers->token,
            'Content-Type' => 'application/json',
        ],
        to_json({ server => { name => $name, } }));
    my $response = $self->cloudservers->_request($request);
    confess 'Unknown error' if $response->code != 202;
    return $response;
}

sub delete_server {
    my $self    = shift;
    my $request = HTTP::Request->new(
        'DELETE',
        $self->cloudservers->server_management_url . '/servers/' . $self->id,
        [
            'X-Auth-Token' => $self->cloudservers->token,
            'Content-Type' => 'application/json',
        ],
    );
    my $response = $self->cloudservers->_request($request);
    confess 'Unknown error' if $response->code != 202;
    return;
}

sub create_image {
    my $self    = shift;
    my $imgname = shift;
    my $request = HTTP::Request->new(
        'POST',
        $self->cloudservers->server_management_url . '/images',
        [
            'X-Auth-Token' => $self->cloudservers->token,
            'Content-Type' => 'application/json',
        ],
        to_json({ image => { serverId => $self->id, name => $imgname, } }));
    my $response = $self->cloudservers->_request($request);
    if ($response->code != 202) {
        confess 'Unknown error ' . $response->code, "\n",
            Dump($response->content);
    }
    my $hash_response = from_json($response->content);
    if (!defined $hash_response->{image}) {
        confess 'response does not contain "image":', Dump($hash_response);
    }
    return Net::RackSpace::CloudServers::Image->new(
        cloudservers => $self->cloudservers,
        id           => $hash_response->{image}->{id},
        serverid     => $hash_response->{image}->{serverId},
        name         => $hash_response->{image}->{name},
        created      => $hash_response->{image}->{created},
        status       => $hash_response->{image}->{status},
        progress     => $hash_response->{image}->{status},
        updated      => undef,
    );
}

sub create_server {
    my $self    = shift;
    my $request = HTTP::Request->new(
        'POST',
        $self->cloudservers->server_management_url . '/servers',
        [
            'X-Auth-Token' => $self->cloudservers->token,
            'Content-Type' => 'application/json',
        ],
        to_json({
                server => {
                    name     => $self->name,
                    imageId  => int $self->imageid,
                    flavorId => int $self->flavorid,
                    defined $self->metadata ? (metadata => $self->metadata)
                    : (),
                    defined $self->personality
                    ? (personality => $self->personality)
                    : (),
                } }));
    my $response = $self->cloudservers->_request($request);
    confess 'Unknown error' if $response->code != 202;
    my $hash_response = from_json($response->content);
    warn Dump($hash_response) if $DEBUG;
    confess 'response does not contain key "server"'
        if (!defined $hash_response->{server});
    confess 'response does not contain hashref of "server"'
        if (ref $hash_response->{server} ne 'HASH');
    my $hserver = $hash_response->{server};
    return __PACKAGE__->new(
        cloudservers    => $self->cloudservers,
        adminpass       => $hserver->{adminPass},
        id              => $hserver->{id},
        name            => $hserver->{name},
        imageid         => $hserver->{imageId},
        flavorid        => $hserver->{flavorId},
        hostid          => $hserver->{hostId},
        status          => $hserver->{status},
        progress        => $hserver->{progress},
        public_address  => $hserver->{addresses}->{public},
        private_address => $hserver->{addresses}->{private},
        metadata        => $hserver->{metadata},
        personality     => $hserver->{personality},
    );
}

1;

__END__

=head1 NAME

Net::RackSpace::CloudServers::Server - a RackSpace CloudServers Server instance

=head1 VERSION

version 0.15

=head1 SYNOPSIS

  use Net::RackSpace::CloudServers;
  use Net::RackSpace::CloudServers::Server;
  my $cs = Net::RackSpace::CloudServers->new( user => 'myusername', key => 'mysecretkey' );
  my $server = Net::RackSpace::CloudServers::Server->new(
    cloudservers => $cs,
    id => '1', name => 'test',
  );
  # get list:
  my @servers = $cs->get_server;
  foreach my $server ( @servers ) {
    print 'Have server ', $server->name, ' id ', $server->id, "\n";
  }
  # get detailed list
  my @servers = $cs->get_server_detail();
  foreach my $server ( @servers) {
    print 'Have server ', $server->name, ' id ', $server->id,
      # ...
      "\n";
  }

  ## Create server from template
  my $tmp = Net::RackSpace::CloudServer::Server->new(
    cloudservers => $cs, name => 'myserver',
    flavorid => 2, imageid => 8,
    # others
  );
  my $srv = $tmp->create_server;
  print "root pass: ", $srv->adminpass, " IP: @{$srv->public_address}\n";

=head1 METHODS

=head2 new / BUILD

The constructor creates a Server object, see L<create_server> to create a server instance from a template:

  my $server = Net::RackSpace::CloudServers::Server->new(
    cloudserver => $cs
    id => 'id', name => 'name',
  );

This normally gets created for you by L<Net::RackSpace::Cloudserver>'s L<get_server> or L<get_server_detail> methods.
Needs a Net::RackSpace::CloudServers object as B<cloudservers> parameter.

=head2 create_server

This creates a real server based on a Server template object (TODO: will accept all the other build parameters).

=head2 delete_server

This will ask RackSpace to delete the cloud server instance specified in this object's ID from the system.
This operation is irreversible. Please notice that all images created from this server (if any) will also
be removed. This method doesn't return anything on success, and C<confess()>es on failure.

=head2 change_name

Changes the server's name to the new value given. Dies on error, or returns the response

  $srv->change_name('newname');

=head2 change_root_password

Changes the server's root password to the new value given. Dies on error, or returns the response

  $srv->change_root_password('toor');

=head2 create_image

Creates a named backup image of the current server. Returns the newly created
C<Net::RackSpace::CloudServers::Image> object, which includes the new image's C<id>.

  $srv->create_image("test backup 001");

=head1 ATTRIBUTES

=head2 id

The id is used for the creation of new cloudservers

=head2 name

The name which identifies the server

=head2 adminpass

When newly built ONLY, the automatically generated password for root

=head2 imageid

The ID of the L<Net::RackSpace::CloudServer::Image> from which the server has been created

=head2 flavorid

The ID of the L<Net::RackSpace::CloudServer::Flavor> the server is currently running as

=head2 hostid

An ID which univocally identifies a server on your account. May not be unique across accounts.

=head2 status

The status of the server: building, etc

=head2 progress

The progress of the current B<status> operation: 60%, etc.

=head2 public_address

Arrayref containing the list of public addresses the server is configured to use

=head2 private_address

Arrayref containing the list of private addresses the server is configured to use

=head2 metadata

Hashref containing any metadata that has been set for the server

=head1 AUTHOR

Marco Fontani, C<< <mfontani at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-rackspace-cloudservers at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-RackSpace-CloudServers>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::RackSpace::CloudServers::Server

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-RackSpace-CloudServers>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-RackSpace-CloudServers>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-RackSpace-CloudServers>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-RackSpace-CloudServers/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Marco Fontani, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
