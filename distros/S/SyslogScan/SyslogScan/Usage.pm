package SyslogScan::Usage;

$VERSION = 0.20;
sub Version { $VERSION };

use SyslogScan::Volume;

my $SEND = 0;
my $RECEIVE = 1;
my $BROADCAST = 2;

my @ROLE_LIST = ($BROADCAST,$SEND,$RECEIVE);

use strict;

sub new
{
    my $type = shift;

    my $self = ();

    my $role;
    foreach $role (@ROLE_LIST)
    {
	$$self[$role] = new SyslogScan::Volume;
    }
    bless($self,$type);
    return $self;
}

sub addUsage
{
    my $self = shift;
    my $other = shift;
    my $role;
    foreach $role (@ROLE_LIST)
    {
	$$self[$role] -> addVolume($$other[$role]);
    }
}

sub registerSend
{
    my $self = shift;
    my $size = shift;
    
    $self -> register($size,$SEND);
}

sub registerReceive
{
    my $self = shift;
    my $size = shift;
    
    $self -> register($size,$RECEIVE);
}

sub registerBroadcast
{
    my $self = shift;
    my $size = shift;
    
    $self -> register($size,$BROADCAST);
}

sub getBroadcastVolume
{
    my $self = shift;
    return $$self[$BROADCAST] -> deepCopy();
}

sub getSendVolume
{
    my $self = shift;
    return $$self[$SEND] -> deepCopy();
}

sub getReceiveVolume
{
    my $self = shift;
    return $$self[$RECEIVE] -> deepCopy();
}

sub register
{
    my $self = shift;
    my $size = shift;
    my $role = shift;

    defined($$self[$role]) or
	die "illegal Role: $role";

    $$self[$role] -> addSize($size);
}

sub persist
{
    my $self = shift;
    my $outFH = shift;

    my $role;
    foreach $role (@ROLE_LIST)
    {
	$$self[$role] -> persist($outFH);
    }
}

sub restore
{
    my $type = shift;
    my $inFH = shift;

    my $self = ();

    my $role;
    foreach $role (@ROLE_LIST)
    {
	$$self[$role] =
	  SyslogScan::Volume -> restore($inFH);
    }

    bless($self,$type);

    return $self;
}

sub dump
{
    my $self = shift;
    my $retString;

    my $role;
    foreach $role (@ROLE_LIST)
    {
	$retString .= "\t\t". $$self[$role] -> dump();
    }
    return $retString."\n";
}

sub deepCopy
{
    my $self = shift;
    my $copy = ();
    
    my $role;
    foreach $role (@ROLE_LIST)
    {
	$$copy[$role] = $$self[$role] -> deepCopy();
    }

    bless($copy,ref($self));
    return $copy;
}

1;

__END__

=head1 NAME

SyslogScan::Usage -- encapsulates the total volumes of mail broadcast,
sent, and received through sendmail by a single user or group.

SyslogScan::Volume -- encapsulates a number of messages along with a
total number of bytes

=head1 SYNOPSIS

# $summary is a SyslogScan::Summary object

use SyslogScan::Usage;
my $usage = $$summary{'john_doe@foo.com'};
$usage -> dump();

use SyslogScan::Volume;
my $broadcastVolume = $usage -> getBroadcastVolume();
my $sendVolume = $usage -> getSendVolume();
my $receiveVolume = $usage -> getReceiveVolume();

print "John Doe sent $$sendVolume[0] messages with $$sendVolume[1] bytes\n";

=head1 DESCRIPTION

=head2 Broadcast, Send, and Receive

Volume of messages received has the obvious meaning.  Volume of
messages sent and volume of messages broadcast require more
explanation.

If I send out a message which has three recipients, then for the
purposes of the SyslogScan modules, I am I<broadcasting> the message
once, but I am I<sending> it three times.

=head2 Usage methods

=over 4

=item new() method

Creates a new, empty Usage object.

=item addUsage() method and deepCopy() method

   # $usage1 is 4 messages of 100 bytes Received
   # $usage2 is 1 message of 35 bytes Received

   my $usageTotal = $usage1 -> deepCopy();
   # $usageTotal is 4 messages of 100 bytes Received

   $usageTotal -> addUsage($usage2);
   # $usageTotal is 5 messages of 135 bytes Received

Note that because we used deepCopy, I<$usage1> is still 4 messages of
100 bytes.

=item registerBroadcast, registerSend, registerReceive methods

    my $usage = new SyslogScan::Usage();
    $usage -> registerSend(512);
    $usage -> registerSend(34);
    $usage -> registerBroadcast(34);
    # $usage is now 2 messages, 546 bytes Sent,
    # and 1 message, 34 bytes Broadcast

=item getBroadcastVolume, getSendVolume, getReceiveVolume methods

Returns deep copy of the applicable SyslogScan::Volume objects.

=item static deepCopy method

Returns deep copy of the whole SyslogScan::Usage object.

=item static dump

Returns a string containing (Message,Bytes) pairs for Broadcast, Send,
and Receive volumes.

=back

=head2 Volume methods

=over 4

=item new() method

Creates a new Volume object of 0 messages, 0 bytes.

=item deepCopy() method

Creates a new Volume object with the same number of messages and bytes
as the current Volume object.

=item addVolume(), addSize() methods

addVolume() adds the volume of a second Volume object onto the volume
of the current Volume object.

addSize() adds on one message of the given size.

    use SyslogScan::Volume;

    my $volume1 = new SyslogScan::Volume();
    $volume1 -> addSize(512);

    my $volume2 = $volume1 -> deepCopy();
    # $volume2 is 1 message, 512 bytes

    $volume2 -> addSize(31);
    # $volume2 is 2 messages, 543 bytes

    $volume2 -> addVolume($volume1);
    # $volume2 is 3 messages, 1055 bytes

    $volume2 -> addVolume($volume2);
    # $volume2 is 6 messages, 2110 bytes

=item getMessageCount, getByteCount

Gets the number of messages and the total number of bytes, respectively.

=item dump()

Returns the string "getMessageCount(),getByteCount()"

=back

=head2 Volume internals

A Volume is simply a two-element array of ($messages, $bytes).

$$volume[0] is the number of messages
$$volume[1] is the number of bytes

=head1 AUTHOR and COPYRIGHT

The author (Rolf Harold Nelson) can currently be e-mailed as
rolf@usa.healthnet.org.

This code is Copyright (C) SatelLife, Inc. 1996.  All rights reserved.
This code is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

In no event shall SatelLife be liable to any party for direct,
indirect, special, incidental, or consequential damages arising out of
the use of this software and its documentation (including, but not
limited to, lost profits) even if the authors have been advised of the
possibility of such damage.

=head1 SEE ALSO

L<SyslogScan::Summary>
