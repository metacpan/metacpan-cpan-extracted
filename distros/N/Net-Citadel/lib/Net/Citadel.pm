package Net::Citadel;

use strict;
use warnings;

require Exporter;
use base qw(Exporter);

use Carp qw( croak );

use IO::Socket;
use Data::Dumper;

use Readonly;

=pod

=head1 NAME

Net::Citadel - Citadel.org protocol coverage

=head1 VERSION

Version 0.23

=cut

our $VERSION = '0.23';

=head1 SYNOPSIS

  use Net::Citadel;
  my $c = new Net::Citadel (host => 'citadel.example.org');
  $c->login ('Administrator', 'goodpassword');
  my @floors = $c->floors;

  eval {
     $c->assert_floor ('Level 6 (Management)');
  }; warn $@ if $@;

  $c->retract_floor ('Level 6 (Management)');

  $c->logout;

=head1 DESCRIPTION

Citadel is a "turnkey open-source solution for email and collaboration" (this is as far as marketing
can go :-). The main component is the I<citadel server>. To communicate with it you can use either
a web interface, or - if you have to automate things - with a protocol

   L<http://www.citadel.org/doku.php?id=documentation:appproto:start>

This package tries to do a bit of abstraction (more could be done) and handles some of the protocol
handling.  The basic idea is that the application using the package deals with Citadel's objects:
rooms, floors, users.

=head1 CONSTANTS

=head2 Configuration

=over 4

=item CITADEL_PORT

The constant $CITADEL_PORT is equal to C<504>, which is the IANA standard Citadel port.

=back

=cut

Readonly our $CITADEL_PORT => 504;

=head2 Result Codes

=over 4

=item LISTING_FOLLOWS

The result code $LISTING_FOLLOWS is equal to C<100> and is used by the Citadel
server to indicate that after the server response, the server will output a
listing of some sort.

=cut

Readonly our $LISTING_FOLLOWS => 100;

=item CIT_OK

The result code $CIT_OK is equal to C<200> and is used by the Citadel
server to indicate that the requested operation succeeded.

=cut

Readonly our $CIT_OK => 200;

=item MORE_DATA

The result code $MORE_DATA is equal to C<300> and is used by the Citadel server
to indicate that the requested operation succeeded but that another command is
required to complete it.

=cut

Readonly our $MORE_DATA => 300;

=item SEND_LISTING

The result code $SEND_LISTING is equal to C<400> and is used by the Citadel
server to indicate that the requested operation is progressing and it is now
expecting zero or more lines of text.

=cut

Readonly our $SEND_LISTING => 400;

=item ERROR

The result code $ERROR is equal to C<500> and is used by the Citadel server to
indicate that the requested operation failed. The second and third digits of
the error code and/or the error message following it describes why.

=cut

Readonly our $ERROR => 500;


=item BINARY_FOLLOWS

The result code $BINARY_FOLLOWS is equal to C<600> and is used by the Citadel server to
indicate that after this line, read C<n> bytes. (<Cn> follows after a blank)

=cut

Readonly our $BINARY_FOLLOWS => 600;

=item SEND_BINARY

The result code $SEND_BINARY is equal to C<700> and is used by the Citadel server to
indicate that C<n> bytes of binary data can now be sent. (C<n> follows after a blank.

=cut

Readonly our $SEND_BINARY => 700;

=item START_CHAT_MODE

The result code $START_CHAT_MODE is equal to C<800> and is used by the Citadel
server to indicate that the system is in chat mode now. Every line sent will be
broadcasted.

=cut

Readonly our $START_CHAT_MODE => 800;

=item ASYNC_MSG

The result code $ASYC_MSG is equal to C<900> and is used by the Citadel
server to indicate that there is a page waiting that needs to be fetched.

=back

=cut

Readonly our $ASYNC_MSG => 900;

=head2 Room Access

=over 4

=item PUBLIC

The room access code $PUBLIC is equal to C<0> and is used to indicate that a
room is to have public access.

=cut

Readonly our $PUBLIC => 0;

=item PRIVATE

The room access code $PRIVATE is equal to C<1> and is used to indicate that a
room is to have private access.

=cut

Readonly our $PRIVATE => 1;

=item PRIVATE_PASSWORD

The room access code $PRIVATE_PASSWORD is equal to C<2> and is used to indicate
that a room is to have private access using a password.

=cut

Readonly our $PRIVATE_PASSWORD => 2;

=item PRIVATE_INVITATION

The room access code $PRIVATE_INVITATION is equal to C<3> and is used to indicate
that a room is to have private access by invitation.

=cut

Readonly our $PRIVATE_INVITATION => 3;

=item PERSONAL

The room access code $PERSONAL is equal to C<4> and is used to indicate
that a room is to be a private mailbox only for a particular user.

=back

=cut

Readonly our $PERSONAL => 4;

=head2 User related

=over 4

=item DELETED_USER

The room access code $DELETED_USER is equal to C<0>.

=cut

Readonly our $DELETED_USER => 0;

=item NEW_USER

The User related constant $NEW_USER is equal to C<1>.

=cut

Readonly our $NEW_USER => 1;

=item PROBLEM_USER

The User related constant $PROBLEM_USER is equal to C<2>.

=cut

Readonly our $PROBLEM_USER => 2;

=item LOCAL_USER

The User related constant $LOCAL_USER is equal to C<3>.

=cut

Readonly our $LOCAL_USER => 3;

=item NETWORK_USER

The User related constant $NETWORK_USER is equal to C<4>.

=cut

Readonly our $NETWORK_USER => 4;

=item PREFERRED_USER

The User related constant $PREFERRED_USER is equal to C<5>.

=cut

Readonly our $PREFERRED_USER => 5;

=item AIDE_USER

The User related constant $AIDE user is equal to C<6>.

=back

=cut

Readonly our $AIDE => 6;

=pod

=head1 INTERFACE

=head2 Constructor

C<$c = new Net::Citadel (host => $ctdl_host)>

The constructor creates a handle to the citadel server (and creates the TCP
connection). It uses the following named parameters:

=over

=item I<host> (default: C<localhost>)

The hostname (or IP address) where the citadel server is running. Defaults
to C<localhost>.

=item I<port> (default: C<$CITADEL_PORT>)

The port where the citadel server is running. Defaults to the standard Citadel
port number C<504>.

=back

The constructor will croak if no connection can be established.

=cut

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    $self->{host} ||= 'localhost';
    $self->{port} ||= $CITADEL_PORT;
    use IO::Socket::INET;
    $self->{socket} = IO::Socket::INET->new (PeerAddr => $self->{host},
                                             PeerPort => $self->{port},
                                             Proto    => 'tcp',
                                             Type     => SOCK_STREAM) or croak "cannot connect to $self->{host}:$self->{port} ($@)";
    my $s = $self->{socket}; <$s>; # consume banner
    return $self;
}

=pod

=head2 Methods

=head3 Authentication

=over

=item I<login>

I<$c>->login (I<$user>, I<$pwd>)

Logs in this user, or will croak if that fails.

=cut

sub login {
    my $self = shift;
    my $user = shift;
    my $pwd  = shift;
    my $s    = $self->{socket};

    print $s "USER $user\n";
    <$s> =~ /(\d).. (.*)/ and ($1 == 3 or croak $2);

    print $s "PASS $pwd\n";
    <$s> =~ /(\d).. (.*)/ and ($1 == 2 or croak $2);

    return 1;
}

=pod

=item I<logout>

I<$c>->logout

Well, logs out the current user.

=cut

sub logout {
    my $self = shift;
    my $s    = $self->{socket};

    print $s "LOUT\n";
    <$s> =~ /(\d).. (.*)/ and ($1 == 2 or croak $2);

    return 1;
}

=pod

=back

=head3 Floors

=over

=item I<floors>

I<@floors> = I<$c>->floors

Retrieves a list (ARRAY) of known floors. Each entry is a hash reference with the name, the number
of rooms in that floor and the index as ID. The index within the array is also the ID of the floor.

=cut

sub floors {
    my $self = shift;
    my $s    = $self->{socket};

    print $s "LFLR\n";
    <$s> =~ /(\d).. (.*)/ and ($1 == 1 or croak $2);

    my @floors;
    while (($_ = <$s>) !~ /^000/) {
#warn "_floors $_";
	my ($nr, $name, $nr_rooms) = /(.+)\|(.+)\|(.+)/;
	push @floors, { id => $nr, name => $name, nr_rooms => $nr_rooms };
    }
    return @floors;
#100 Known floors:
#0|Main Floor|33
#1|SecondLevel|1
#000
}

=pod

=item I<assert_floor>

I<$c>->assert_floor (I<$floor_name>)

Creates the floor with the name provided, or if it already exists simply returns. This only croaks if
there are insufficient privileges.

=cut

sub assert_floor {
    my $self = shift;
    my $name = shift;

    my $s    = $self->{socket};
    print $s "CFLR $name|1\n";  # we really want to create it
    <$s> =~ /(\d).. (.*)/ and ($1 == 1 or $1 == 2 or $2 =~ /already exists/ or croak $2);
#CFLR XXX|1
#550 This command requires Aide access.
    return 1;
}

=pod

=item I<retract_floor>

I<$c>->retract_floor (I<$floor_name>)

Retracts a floor with this name. croaks if that fails because of insufficient privileges. Does
not croak if the floor did not exist.

B<NOTE>: Citadel server (v7.20) seems to have the bug that you cannot
delete an empty floor without restarting the server. Not much I can do
here about that.

=cut

sub retract_floor {
    my $self = shift;
    my $name = shift;

    my @floors = $self->floors;
    for (my $i = 0; $i <= $#floors; $i++) {
	if ($floors[$i]->{name} eq $name) {
	    my $s    = $self->{socket};
	    print $s "KFLR $i|1\n";  # we really want to delete it
	    <$s> =~ /(\d).. (.*)/ and ($1 == 2 or $2 =~ /not in use/ or croak $2);
	    return;
	}
    }
    return 1;
}

=pod

=item I<rooms>

I<@rooms> = I<$c>->rooms (I<$floor_name>)

Retrieves the rooms on that given floor.

=cut

sub rooms {
    my $self = shift;
    my $name = shift;

    my $s    = $self->{socket};

    my @floors  = $self->floors;
#warn "looking for $name rooms ". Dumper \@floors;
    my ($floor) = grep { $_->{name} eq $name } @floors or croak "no floor '$name' known";
#warn "found floor: ".Dumper $floor;

    print $s "LKRA ".$floor->{id}."\n";
    <$s> =~ /(\d).. (.*)/ and ($1 == 1 or croak $2);
    my @rooms;
    while (($_ = <$s>) !~ /^000/) {
#warn "processing $_";
 	my %room;
	@room{ ('name', 'qr_flags', 'qr2_flags', 'floor', 'order', 'ua_flags', 'view', 'default', 'last_mod') } = split /\|/, $_;
 	push @rooms, \%room;
     }
     return @rooms;
#LKRA
#100 Known rooms:
#Calendar|16390|0|0|0|230|3|3|1191241353|
#Contacts|16390|0|0|0|230|2|2|1191241353|
#..
#ramsti|2|1|64|0|230|0|0|1191241691|
#000
}

=pod

=back

=head3 Rooms

=over

=item I<assert_room>

I<$c>->assert_room (I<$floor_name>, I<$room_name>, [ I<$room_attributes> ])

Creates the room on the given floor. If the room already exists there, nothing
else happens. If the floor does not exist, it will complain.

The optional room attributes are provided as hash with the following fields

=over

=item C<access> (default: C<PUBLIC>)

One of the constants C<PUBLIC>, C<PRIVATE>, C<PRIVATE_PASSWORD>, C<PRIVATE_INVITATION> or
C<PERSONAL>.

=item C<password> (default: empty)

=item C<default_view> (default: empty)

=back

=cut

sub assert_room {
    my $self    = shift;
    my $fname   = shift;
    my @floors  = $self->floors;
    my ($floor) = grep { $_->{name} eq $fname } @floors or croak "no floor '$fname' known";

    my $name  = shift;
    my $attrs = shift;
    $attrs->{access}       ||= $PUBLIC;
    $attrs->{password}     ||= '';
    $attrs->{default_view} ||= '';

    my $s    = $self->{socket};

    print $s "CRE8 1|$name|".
	           $attrs->{access}.'|'.
		   $attrs->{password}.'|'.
		   $floor->{id}.'|'.
		   '|'.   # no idea what this is
		   $attrs->{default_view}.'|'.
		   "\n";
    <$s> =~ /(\d).. (.*)/ and ($1 == 2 or $2 =~ /already exists/ or croak $2);

    return 1;
}

#CRE8 1|Bumsti|0||0|||
#200 'Bumsti' has been created.

=pod

=item I<retract_room>

I<$c>->retract_room (I<$floor_name>, I<$room_name>)

B<NOTE>: Not implemented yet.

=cut

sub retract_room {
    my $self = shift;
    my $name = shift;
    my $s    = $self->{socket};
    print $s "GOTO $name\n";
#GOTO Bumsti
    <$s> =~ /(\d).. (.*)/ and ($1 == 2 or croak $2);
#200 Lobby|0|0|0|2|0|0|0|1|0|0|0|0|0|0|
    print $s "KILL 1\n";
#KILL 1
    <$s> =~ /(\d).. (.*)/ and ($1 == 2 or croak $2);
#200 'Bumsti' deleted.
    return 1;
}

=pod

=back

=head3 Users

=over

=item I<create_user>

I<$c>->create_user (I<$username>, I<$password>)

Tries to create a user with name and password. Fails if this user already exists (or some other
reason).

=cut

sub create_user {
    my $self = shift;
    my $name = shift;
    my $pwd  = shift;
    my $s    = $self->{socket};
    print $s "CREU $name|$pwd\n";
#CREU TestUser|xxx
    <$s> =~ /(\d).. (.*)/ and ($1 == 2 or croak $2);
#200 User 'TestUser' created and password set.
    return 1;
}

=pod

=item I<change_user>

I<$c>->change_user (I<$user_name>, I<$aspect> => I<$value>)

Changes certain aspects of a user. Currently understood aspects are

=over

=item C<password> (string)

=item C<access_level> (0..6, constants available)

=back

=cut

sub change_user {
    my $self = shift;
    my $name = shift;
    my %changes = @_;
    my $s    = $self->{socket};

    print $s "AGUP $name\n";
#AGUP TestUser
    <$s> =~ /(\d).. (.*)/ and ($1 == 2 or croak $2);
#200 TestUser|ggg|10768|1|0|4|4|1191255938|0
    my %user;
    my @attrs = ('name', 'password', 'flags', 'times_called', 'messages_posted', 'access_level', 'user_number', 'timestamp', 'purge_time');
    @user{ @attrs } = split /\|/, $2;

    $user{password}     = $changes{password}     if $changes{password};
    $user{access_level} = $changes{access_level} if $changes{access_level};

    print $s "ASUP ".(join "|", @user{ @attrs })."\n";
    <$s> =~ /(\d).. (.*)/ and ($1 == 2 or croak $2);

    return 1;
}

=pod

=item I<remove_user>

I<$c>->remove_user (I<$name>)

Removes the user (actually sets level to C<DELETED_USER>).

=cut

sub remove_user {
    my $self = shift;
    my $name = shift;

    my $s    = $self->{socket};

    print $s "AGUP $name\n";
#AGUP TestUser
    <$s> =~ /(\d).. (.*)/ and ($1 == 2 or croak $2);
#200 TestUser|ggg|10768|1|0|4|4|1191255938|0
    my %user;
    my @attrs = ('name', 'password', 'flags', 'times_called', 'messages_posted', 'access_level', 'user_number', 'timestamp', 'purge_time');
    @user{ @attrs } = split /\|/, $2;

    $user{access_level} = $DELETED_USER;

    print $s "ASUP ".(join "|", @user{ @attrs })."\n";
    <$s> =~ /(\d).. (.*)/ and ($1 == 2 or croak $2);

    return 1;
}

=pod

=back

=head3 Miscellaneous

=over

=item I<citadel_echo>

I<$c>->citadel_echo (I<$string>)

Tests a connection to the Citadel server by sending a message string to it and
then checking to see if that same string is echoed back.

=cut

sub citadel_echo {
    my $self = shift;
    my $msg  = shift;
    my $s    = $self->{socket};

    print $s "ECHO $msg\n";
    croak "message not echoed ($msg)" unless <$s> =~ /2.. $msg/;

    return 1;
}

=item I<citadel_info>

$info_aref = I<$c>->citadel_info()

Sends the C<INFO> command to the Citadel server and returns the lines it receives
from that as a reference to an array. An example of getting and then displaying the
server information lines the following:

 my $c = new Net::Citadel (host => $host_name);
 my $info_aref = $c->citadel_info;
 foreach $line (@{$info_aref}) {
    print $line;
 }

For more details about the server information lines that are returned, see the
C<INFO> entry at L<http://www.citadel.org/doku.php/documentation:appproto:connection>.

=cut

sub citadel_info {
    my $self = shift;
    my $s    = $self->{socket};
    my ( @info, $line );

    print $s "INFO\n";

    if ((<$s>) !~ /1../) { croak "Incorrect response from Citadel INFO command." };

    while ($line = <$s>) {
        if ( $line !~ /^000/ ) {
            push @info, $line;
        }
        else { last; }
    }

    return \@info;
}

=item I<citadel_mrtg>

%mrtg_hash = I<$c>->citadel_mrtg($type)

Sends the C<MRTG> command to the Citadel server. It expects a type of either
C<users> or C<messages> to be passed to it and returns a hash containing the
information from the server.

=over 4

=item ActiveUsers
Number of active users on the system.  Only returned for type C<users>.

=item ConnectedUsers

Number of connected users on the system.  Only returned for type C<users>.

=item HighMsg

Higest message number on the system.  Only returned for type C<messages>.

=item SystemUptime

The uptime for the system formatted as days, hours, minutes.

=item SystemName

Human readable name of the Citadel system.

=back

=cut

sub citadel_mrtg {
    my $self = shift;
    my $type = shift;
    my $s    = $self->{socket};
    my ( %mrtg, @mrtg_lines, $line );

    print $s "MRTG $type\n";

    if ((<$s>) !~ /1../) { croak "Incorrect response from Citadel MRTG command." };

    # Get the listing of the MRTG information from the server.
    while ($line = <$s>) {
        if ( $line !~ /^000/ ) {
            push @mrtg_lines, $line;
        }
        else { last; }
    }

    # Create the %mrtg hash from the information in the @mrtg_lines array
    if ( lc($type) eq q{users} ) {
        $mrtg{'ConnectedUsers'} = $mrtg_lines[0];
        $mrtg{'ActiveUsers'} = $mrtg_lines[1];
    } else {
        $mrtg{'HighMsg'} = $mrtg_lines[0];
    }
    $mrtg{'SystemUptime'} = $mrtg_lines[2];
    $mrtg{'SystemName'} = $mrtg_lines[3];

    # Return the MRTG information as the mrtg hash.
    return %mrtg;
}

=pod

=item I<citadel_time>

I<$t> = I<$c>->citadel_time

Gets the current system time and time zone offset from UTC in UNIX timestamp format from the Citadel server.

C<TODO>: Rewrite function to return the unpacked parameters as a hash upon success.

=cut

sub citadel_time {
    my $self = shift;
    my $s    = $self->{socket};
    print $s "TIME\n";
    croak "protocol: citadel_time failed" unless <$s> =~ /2.. (.*)\|(.*)\|(.*)/;  # not sure what the others are
    return $1;
}

=pod

=back

=head1 TODOs

- Decent GUI using Mason + AJAX

=head1 SEE ALSO

   L<http://www.citadel.org/doku.php?id=documentation:appproto:app_proto>

=head1 AUTHORS

Robert Barta, E<lt>drrho@cpan.orgE<gt>
Robert James Clay, E<lt>jame@rocasa.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2008 by Robert Barta
Copyright (C) 2012-2016 by Robert James Clay

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut


1;

__END__
