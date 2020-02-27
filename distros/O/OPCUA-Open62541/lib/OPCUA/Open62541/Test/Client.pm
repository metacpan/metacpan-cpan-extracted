package OPCUA::Open62541::Test::Client;

use strict;
use warnings;
use OPCUA::Open62541 ':statuscode';

use Test::More;

sub planning {
    # number of ok() and is() calls in this code
    return 5;
}

sub new {
    my $class = shift;
    my %args = @_;
    my $self = {};
    $self->{port} = $args{port};
    $self->{timeout} = $args{timeout} || 10;

    ok($self->{client} = OPCUA::Open62541::Client->new(), "client new");
    ok($self->{config} = $self->{client}->getConfig(), "client get config");
    is($self->{config}->setDefault(), "Good", "client config set default");

    return bless($self, $class);
}

sub start {
    my $self = shift;

    my $url = "opc.tcp://localhost";
    $url .= ":$self->{port}" if $self->{port};
    note("going to connect client");
    is($self->{client}->connect($url), STATUSCODE_GOOD, "client connect");
}

sub stop {
    my $self = shift;

    note("going to disconnect client");
    is($self->{client}->disconnect(), STATUSCODE_GOOD, "client disconnect");
}

1;

__END__

=head1 NAME

OPCUA::Open62541::Test::Client - run open62541 client for testing

=head1 SYNOPSIS

  use OPCUA::Open62541::Test::Client;
  use Test::More tests => OPCUA::Open62541::Test::Client::planning();

  my $client = OPCUA::Open62541::Test::Client->new();

=head1 DESCRIPTION

In a module test start and run an open62541 OPC UA client that
connects to a server.
The client is considered part of the test and will write to the TAP
stream.

=over 4

=item OPCUA::Open62541::Test::Client::planning

Return the number of tests results that running one client will
create.
Add this to your number of planned tests.

=back

=head2 METHODS

=over 4

=item $client = OPCUA::Open62541::Test::Client->new(%args);

Create a new test client instance.

=over 8

=item $args{port}

Port number of the server.

=item $args{timeout}

Maximum time the client will run during iterate.
Defaults to 10 seconds.

=back

=item $client->start()

Connect the client to the open62541 server.

=item $client->stop()

Disconnect the client from the open62541 server.

=back

=head1 SEE ALSO

OPCUA::Open62541,
OPCUA::Open62541::Test::Server

=head1 AUTHORS

Alexander Bluhm E<lt>bluhm@genua.deE<gt>,

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2020 Alexander Bluhm

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Thanks to genua GmbH, https://www.genua.de/ for sponsoring this work.

=cut
