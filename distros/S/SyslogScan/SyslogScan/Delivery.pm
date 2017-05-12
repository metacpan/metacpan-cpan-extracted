package SyslogScan::Delivery;

$VERSION = 0.20;
sub Version { $VERSION };

use strict;
use Carp;

my @LEGAL_KEY_LIST = qw( Date Size Id Sender ReceiverList Instance );
my $VERSION = 1;
my $HEADER = "DeliveryV$VERSION";

sub new
{
    my $type = shift;
    my %selfHash = @_;

    my $self = \%selfHash;

    my $key;
    foreach $key (keys %$self)
    {
	grep($_ eq $key,@LEGAL_KEY_LIST) or
	    die "illegal key for Delivery object: $key";
    }
    bless($self,$type);
    return $self;
}

sub persist
{
    my $self = shift;
    my $outFH = shift;

    print $outFH "$HEADER start\n";
    my $key;
    foreach $key (@LEGAL_KEY_LIST)
    {
	next if $key eq 'ReceiverList';
	my $val = $$self{$key};
	$val =~ /\n/ and
	    die "value $val contains embedded newline, cannot persist";
	print $outFH $val, "\n";
    }
    print $outFH "ReceiverList:\n";
    my $receiver;
    foreach $receiver (@{$$self{ReceiverList}})
    {
	$receiver =~ /\n/ and
	    die "value $receiver contains embedded newline, cannot persist";
	$receiver =~ /^$HEADER/ and
	    die "value $receiver looks too much like boundary marks, cannot persist";
	print $outFH "$receiver\n";
    }

    print $outFH "$HEADER end\n";
}

sub restore
{
    my $type = shift;
    my $inFH = shift;

    defined $inFH or croak "filehandle not defined";

    my $line = <$inFH>;
    if ($line ne "$HEADER start\n")
    {
	$line or return undef;   # at eof

	# not at eof; something is fishy
	die "expected $HEADER start, got $line";
    }

    my $self = { ReceiverList => [] };
    bless ($self, $type);

    my $key;
    foreach $key (@LEGAL_KEY_LIST)
    {
	next if $key eq 'ReceiverList';
	$line = <$inFH>;
	chop($line);
	$$self{$key} = $line;
    }
    $line = <$inFH>;

    $line eq "ReceiverList:\n" or die "expected ReceiverList but got $line";

    my $receiver;
    while (defined($line = <$inFH>))
    {
	return $self if $line eq "$HEADER end\n";
	die "missed $HEADER end line" if $line eq "$HEADER start\n";
	chop($line);
	push(@{$$self{ReceiverList}},$line);
    }

    die "never saw $HEADER end line";
}

sub summary
{
    my $self = shift;

    return "$$self{Size} bytes from $$self{Sender} to " .
	join(' ',@{$$self{ReceiverList}}) . "\n";
}

sub dump
{
    my $self = shift;
    my $retString = "";

    my $key;
    foreach $key (keys %$self)
    {
	$retString .= "$key is ";
	if (ref($$self{$key}) eq "ARRAY")
	{
	    $retString .= join(' ',@{$$self{$key}});
	}
	else
	{
	    $retString .= $$self{$key};
	}
	$retString .= "\n";
    }
    return $retString;
}

1;

__END__

=head1 NAME

SyslogScan::Delivery - encapsulates a logged, successful delivery of mail from a sender to a list of recipients.

=head1 SYNOPSIS

see L<SyslogScan::DeliveryIterator>

=head1 DESCRIPTION

A 'Delivery' object is an indication that mail was successfully
delivered or forwarded from a sender to a list of recipients.  You can
extract Delivery objects from a syslog file by using
L<SyslogScan::DeliveryIterator>.

=head2 Variables

    my $delivery = $iter -> next();
    
    #-----------------------------------------
    #  Sender, ReceiverList, Size, and Date are the most useful
    #-----------------------------------------
    
    # e-mail address of sender, may be 'undef' if the sender
    # could not be determined from the syslog
    my $sender = $$delivery{Sender};
    
    # reference to array of e-mail addresses of recipients
    my $paReceiverList = $$delivery{ReceiverList};
    my @aReceiverList = @$paReceiverList;
    print "The recipient(s) of the message was (were) ",
        join(' ',@aReceiverList), "\n";
    
    # size of message, may be 'undef' if the size could not be
    # determined from the syslog
    my $sizeInBytes = $$delivery{Size};
    
    # date the message was succesfully delivered or forwarded
    my $date = $$delivery{Date};
    
    #-----------------------------------------
    #    Id and Instance are more advanced features
    #-----------------------------------------
    
    # 'id' in syslog, useful for cross-referencing
    my $id = $$delivery{Id};
    
    # The first delivery of any message has Instance of 1; the next
    # deliveries will have Instance > 1, specifically a number equal to
    # the number of people who the message has previously been delivered
    # to, plus 1.  This is useful for detecing mass-mailings.
    
    # Suppose I send a message to 5 people, but only three copies are
    # delivered right away, the other two are deferred.  The first
    # Delivery has instance 1; the next delivery of the same message
    # will have instance 4.
    my $instance = $$delivery{Instance};
    my @aReceiverList = @{$$delivery{ReceiverList}};
    print "This message has so far been delivered to ",
        $instance + $@aReceiverList - 1, "people so far\n";

=head1 METHODS

    # Manually create a new Delivery object.
    my $delivery = new SyslogScan::Delivery (Date => time(),
    					 Size => 100,
    					 From => 'foo@bar.com',
    					 ReceiverList =>
    					   [him@baz.edu, her@baz.edu],
    					 Instance => 1,
    					 Id => 'manual' . $id++);
    
    # print out contents, either in summary or in verbose mode
    print $delivery -> summary();
    print $delivery -> dump();
    
    # save/restore delivery to/from file
    open(OUT,">save.txt");
    $delivery -> persist(\*OUT);
    close(OUT);
    undef($delivery);
    
    open(IN,"save.txt");
    $delivery = SyslogScan::Delivery -> restore(\*IN);
    # $delivery is restored to its original state

=head1 SUPPORT

E-mail bugs to rolf@usa.healthnet.org.

=head1 AUTHOR and COPYRIGHT

This code is Copyright (C) SatelLife, Inc. 1996.  All rights reserved.
This code is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

IN NO EVENT SHALL THE AUTHORS BE LIABLE TO ANY PARTY FOR DIRECT,
INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF
THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION (INCLUDING, BUT NOT
LIMITED TO, LOST PROFITS) EVEN IF THE AUTHORS HAVE BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

=head1 SEE ALSO

L<SyslogScan::DeliveryIterator>, L<SyslogScan::Summary>
