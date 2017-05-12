package Padre::Swarm::Manual;

=pod

=head1 NAME

Padre::Swarm::Manual - Guide to Swarm

=head1 DESCRIPTION

=head1 PROTOCOL

The Swarm protocol at present is B<very> ad-hoc and subject to change. Message delivery is NEVER guaranteed, there are no unique
message IDs - nor any acknowledgement that a sent message has arrived.. anywhere.

A swarm message B<should> always have a C<type> , C<service> , C<from>, 
C<title> and C<body>. It B<may> also have a C<to> , C<resource>.

=head2 type=disco

Discovery message requesting information from other swarm agents. Generally a
discovery will trigger a C<promote> response from a service, if that service
chooses to advertise itself.

=head2 type=promote

Advertisment of a service provided by an agent.

=head2 type=chat

A public chat message. Expected to contain a C<body>.

=head2 type=runme

Request for remote execution! Receivers brave enough are expected to run
message C<body> with string eval. :)

=head2 type=openme

Suggestion to open an editor document containing message C<body>


=cut

1;
