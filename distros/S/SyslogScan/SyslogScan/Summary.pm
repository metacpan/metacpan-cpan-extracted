package SyslogScan::Summary;

$VERSION = 0.20;
sub Version { $VERSION };

use SyslogScan::Usage;
use SyslogScan::Volume;
use SyslogScan::Delivery;
use SyslogScan::DeliveryIterator;
use SyslogScan::FilterUser;
use Carp;
use strict;

my $HEADER = "Summary v1";
my $EMPTY_FILTER = new SyslogScan::FilterUser();

sub new
{
    my $type = shift;
    my @iterList = @_;
    
    my $self = {};
    bless ($self,$type);

    $self -> registerAllInIterators('','',
				    @iterList);

    return $self;
}

sub registerAllInIterators
{
    my $self = shift;
    my $selfPattern = shift;
    my $otherPattern = shift;
    my @iterList = @_;

    # check for developer error, since this is counter-intuitive usage.
    defined($otherPattern)
	or die "bad usage of registerAllInIterators function";

    my $iter;
    foreach $iter (@iterList)
    {
	my $delivery;
	while ($delivery = $iter -> next)
	{
	    $self -> registerDelivery($delivery,$selfPattern, $otherPattern);
	}
    }
}

sub registerDelivery
{
    my $self = shift;
    my $delivery = shift;
    my $selfPattern = shift;  # undefined means match everything
    my $otherPattern = shift; # undefined means match everything

    my $filter;
    if (defined $selfPattern)
    {
	$filter = new SyslogScan::FilterUser($selfPattern, $otherPattern);
    }
    else
    {
	# let everything through
	$filter = $EMPTY_FILTER;
    }

    my $size = $$delivery{Size};
    my $sender = $$delivery{Sender};
    my $paReceiverList = $$delivery{ReceiverList};
    ref($paReceiverList) eq 'ARRAY' or die "$paReceiverList not array ref";

    my $gotThroughFilter = 0;
    my $receiver;
    foreach $receiver (@$paReceiverList)
    {
	if ($filter -> matchesFilter($sender,$receiver))
	{
	    $gotThroughFilter++;
	    $self -> _registerUsage($sender,"Sender",$size);
	}
	if ($filter -> matchesFilter($receiver,$sender))
	{
	    $self -> _registerUsage($receiver,"Receive",$size);
	}
    }

    $gotThroughFilter and $$delivery{Instance} eq 1 and
	$self -> _registerUsage($sender,"Broadcast",$size);
}

sub persist
{
    my $self = shift;
    my $outFH = shift;

    print $outFH "$HEADER start\n";
    my $address;
    foreach $address (keys %$self)
    {
	next unless defined $$self{$address};  # skip deleted

	$address =~ /\n/ and
	    die "address $address contains embedded newline, cannot persist";
	print $outFH "address=$address\n";
	$$self{$address} -> persist($outFH);
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

    my $self = {};
    bless ($self, $type);

    my $headerLine;
    while (defined($headerLine = <$inFH>))
    {
	if (! ($headerLine =~ /^address\=(.*)/))
	{
	    return $self if $headerLine eq "$HEADER end\n";
	    die "expected address= or $HEADER end, got $headerLine";
	}
	my $address = $1;

	defined($$self{$address}) and
	    die "address $address seen multiple times, stopped";
	$$self{$address} = SyslogScan::Usage -> restore($inFH);
    }
    die "never saw $HEADER end line";
}

sub dump
{
    my $self = shift;
    my $retString;

    my $address;
    foreach $address (sort keys %$self)
    {
	$retString .= "$address:\n";
	$retString .= $$self{$address} -> dump();
    }
    return $retString;
}

sub _registerUsage
{
    my $self = shift;

    my $address = shift;
    my $role = shift;
    my $size = shift;

    defined $$self{$address} or
	$$self{$address} = new SyslogScan::Usage;

    if ($role eq 'Receive')
    {
	$$self{$address} -> registerReceive($size);
    }
    elsif ($role eq 'Sender')
    {
	$$self{$address} -> registerSend($size);
    }
    elsif ($role eq 'Broadcast')
    {
	$$self{$address} -> registerBroadcast($size);
    }
    else
    {
	die "illegal role: $role";
    }
    return 0;
}

sub addSummary
{
    my $self = shift;
    my $other = shift;

    my $address;
    foreach $address (keys %$other)
    {
	if (! $$self{$address})
	{
	    $$self{$address} = new SyslogScan::Usage();
	}
	$$self{$address} -> addUsage($$other{$address});
    }
}

__END__

=head1 NAME

SyslogScan::Summary -- encapsulates a tally of how many bytes people
have sent and received through sendmail

=head1 SYNOPSIS

    Use SyslogScan::Summary;
    Use SyslogScan::DeliveryIterator;

    my $iter = new SyslogScan::DeliveryIterator(syslogList => 
						[/var/log/syslog]);
    my $summary;
    if (defined $DOING_IT_THE_HARD_WAY_FOR_NO_PARTICULAR_REASON)
    {
	# feed a series of SyslogScan::Delivery objects
	$summary = new SyslogScan::Summary();
	my $delivery;
	while ($delivery = $iter -> next())
	{
	    $summary -> registerDelivery($delivery);

	    # You would instead use:
	    # $summary -> registerDelivery($delivery,'foo\.com\.$')
	    # if you only cared to get statistics relating to how
	    # much mail users at foo.com sent or received.
	}
    }
    else
    {
	# slurps up all deliveries in the iterator,
	# producing the same effect as the block above
	$summary = new SyslogScan::Summary($iter);
    }

    print $summary -> dump();

    use SyslogScan::Usage;
    my $usage = $$summary{'john_doe@foo.com'};
    if (defined $usage)
    {
	print "Here is the usage of John Doe at foo.com:\n";
	print $usage -> dump();
    }
    else
    {
        print "John Doe has neither sent nor received messages lately.\n";
    }

=head1 DESCRIPTION

A SyslogScan::Summary object will 'register' a series of
SyslogScan::Delivery objects.  All registered deliveries are grouped
by sender and receiver e-mail addresses, and then added up.  Three
sums are kept: Total Bytes Recieved, Total Bytes Sent, and Total Bytes
Broadcast.

=head2 Methods

=over 4

=item static new() method

I<new> takes as arguments a (possibly null) list of
SyslogScan::DeliveryIterator objects, from which it extracts
and registers all queued deliveries.

=item registerDelivery() method

I<registerDelivery> takes as its first argument a SyslogScan::Delivery
object followed by up to two optional patterns.  If the first pattern
is specified, only those e-mail addresses which match the pattern are
tallied.  This enables you to create an accounting summary for only
those users at your site.

If the second pattern is also specified, then deliveries will only be
registered to the person matched by the first pattern if the second
pattern matches the address at 'the other end of the pipe'.

Pattern-matches are case-insensitive.  Remember the '(?!regexp)'
operation if you want only addresses which do _not_ match the pattern
to get passed through the filter.  For example, if mail to or from
'support' is exempt from billing charges, note that the pattern-match

/^(?!support)/

does _not_ match 'support@foo.com' but _does_ match
'random_guy@foo.com'.

=item registerAllInIterators() method

Takes as parameters two patterns and a list of iterators, then feeds
deliveries in the iterators and the patterns to I<registerDelivery()>.

For example:

    $sum -> registerAllInIterators('foo\.com$','^(?!.*bar\.com$)',@iterList)

will bill users at foo.com for all mail extracted from @iterList which
was sent from foo.com to somewhere besides bar.com, or sent to foo.com
from somewhere besides bar.com.

=item dump() method

I<dump> returns a string containing address lines alternating with
usage reports.  Usage reports are in the form:

        B#,Bb        S#,Sb        R#,Rb

Where:

B# is the number of messages broadcast
B# is the total number of bytes broadcast

S# is the number of messages sent
S# is the total number of bytes sent

R# is the number of messages received
R# is the total number of bytes received

=item persist() method

I<persist> takes as its single argument an output file-handle, and
then persists the state of the summary to the file.

=item static restore() method

I<restore> takes as its single argument an input file-handle which
stores the results of a previous persist() command, and then returns a
copy of the object in the state in which it was originally persisted.

=item addSummary() method

I<addSummary> takes as its single argument a second
SyslogScan::Summary object, and then adds this second summary to the
$self object.

=back

=head2 Example of use

Suppose I have a function getTodaySummary() which gets a Summary of
the last 24 hours of sendmail logging.

    my $summary = getTodaySummary();
    open(SUMMARY1,">summary1.sav");
    $summary -> persist(\*SUMMARY1);
    close(SUMMARY1);
    exit 0;

    # wait 24 hours

    my $summary = getTodaySummary();
    open(SUMMARY2,">summary2.sav");
    $summary -> persist(\*SUMMARY2);
    close(SUMMARY2);
    exit 0;

    # some time later, you decide you want a summary of the total
    # for both days.  So, you write this program:

    open(INSUM1,"summary1.sav");
    my $sum = SyslogScan::Summary -> restore(\*INSUM1);

    open(INSUM2,"summary2.sav");
    my $sum2 = SyslogScan::Summary -> restore(\*INSUM2);

    $sum -> addSummary($sum2);
    print "Here is the grand total for both days:\n\n";
    print $sum -> dump();

=head2 Internals

A SyslogScan::Summary object is a hash of SyslogScan::Usage objects,
where the key is the e-mail address of the user in question.
SyslogScan::Usage has its own man page which describes how to extract
information without having to use the dump() method.

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

L<SyslogScan::Usage>, L<SyslogScan::DeliveryIterator>,
L<SyslogScan::Delivery>, L<SyslogScan::ByGroup>
