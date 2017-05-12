# DeliveryIterator: an object which scans a syslog for
# successful sendmail deliveries.

# TODO: add documentation
# TODO: use undef value rather than END_OF_TIME

package main;

require 'timelocal.pl';

package SyslogScan::DeliveryIterator;

$VERSION = 0.30;
sub Version { $VERSION };

use SyslogScan::Delivery;
use SyslogScan::SendmailUtil;
use SyslogScan::ParseDate;

use Carp;
use strict;

# internal subroutines
my ($pValidateRule, $pParseDate);

# time_t start and end values
my $END_OF_TIME = 4294967295;  #  2 ** 32 - 1;
my $START_OF_TIME = 0;

sub new
{
    my $type = shift;
    my %deliveryRule = @_;

    my $Rule = {};
    my $self = { Rule => $Rule,
	     seenFromLine => {},
	     syslogList => [] };

    bless $self, $type;

    &$pValidateRule(\%deliveryRule);
    
    $$Rule{startDate} = $deliveryRule{startDate} || $START_OF_TIME;
    $$Rule{endDate} = $deliveryRule{endDate} || $END_OF_TIME;

    $$Rule{unknownSender} = $deliveryRule{unknownSender};
    $$Rule{unknownSize} = $deliveryRule{unknownSize};

    # User should call setDefaultYear() directly instead of through here.
    # But, for backwards compatibility:
    if (defined $deliveryRule{defaultYear})
    {
	&SyslogScan::ParseDate::setDefaultYear($deliveryRule{defaultYear});
	warn "setting default year in DeliveryIterator deprecated"
	    unless $::gbQuiet;
    }
    # $$Rule{defaultYear} = $deliveryRule{defaultYear};

    $$Rule{startDate} = &SyslogScan::ParseDate::parseDate($$Rule{startDate});
    $$Rule{endDate} = &SyslogScan::ParseDate::parseDate($$Rule{endDate});

    # $$Rule{startDate} = &$pParseDate($$Rule{startDate});
    # $$Rule{endDate} = &$pParseDate($$Rule{endDate});
    
    my $paFileName = $deliveryRule{syslogList};
    if (defined $paFileName)
    {
	ref($paFileName) eq "ARRAY" or
	    die "fileNameList is not an array, stopped";
	my $fileName;

	foreach $fileName (@$paFileName)
	{
	    $self -> appendSyslog($fileName);
	}
    }
    
    return $self;
}

sub next
{
    my $self = shift;
    my $fh;

    return $self -> _nextInFileHandle($fh)
	if defined($fh = shift);
    
    while (1)
    {
	if (!$$self{fileHandle})
	{
	    my $fileName = shift(@{$$self{syslogList}});
	    defined($fileName) or return undef;

	    open(SYSLOG,$fileName) or die "could not open $fileName: $!";
	    $$self{fileHandle} = \*SYSLOG;
	}
	my $next = $self -> _nextInFileHandle($$self{fileHandle});
	return $next if defined($next);
	close($$self{fileHandle});
	undef($$self{fileHandle});
    }
    die;
}
    
sub appendSyslog
{
    my $self = shift;
    my $fileName = shift;
    
    push(@{$$self{syslogList}},$fileName);
    return 0;
}

sub _transferToDelivery
{
    my $self = shift;
    my $pLogLine = shift;

    my $pRule = $$self{Rule};

    my $lineClass = ref $pLogLine;
    die "sanity check of class failed for $lineClass"
	unless ($lineClass =~ /^SyslogScan::SendmailLine/);
    
    my $date = "$$pLogLine{month} $$pLogLine{day} " .
	"$$pLogLine{'time'}";
    
    my $dateValue = $pLogLine -> unix_time;
    # my $dateValue = &$pParseDate($date, $$pRule{defaultYear});
    die "invalid date and time: $date" unless $dateValue > 0;
    
    defined $$pRule{endDate} || die "no start date defined";
    if ($dateValue > $$pRule{endDate})
    {
	return undef;
    }
    
    # for debugging purposes
    my $id = $$pLogLine{'messageID'};
    
    if ($lineClass =~ /From/)
    {
	$self -> _storeFromLine($pLogLine);
	return undef;
    }
    
    if ($lineClass =~ /Clone/)
    {
	$self -> _storeCloneLine($pLogLine);
	return undef;
    }
    
    if ($dateValue < $$pRule{startDate})
    {
	return undef;
    }
    
    my $pAttrHash = $$pLogLine{'attrHash'};
    die "could not access hash" unless defined $pAttrHash;
    return undef unless ($$pAttrHash{'stat'} =~ /^Sent/);
    
    my @receiverList = @{$$pLogLine{'toList'}};
    
    my $instance = $self -> _recallInstanceAndIncrement($pLogLine);
    my $size = $self -> _recallSize($pLogLine);
    my $sender = $self -> _recallSender($pLogLine);
    
    if (! defined $size)
    {
	#never saw the associated From: line
	print STDERR "could not find sender for msg id $id to @receiverList\n"
	    unless $::gbQuiet;
	$size = $$pRule{unknownSize};      # may be undefined
	$sender = $$pRule{unknownSender};  # may be undefined
    }
    
    return new SyslogScan::Delivery ( Date => $date,
				     Size => $size,
				     Id => $id,
				     Sender => $sender,
				     ReceiverList => \@receiverList,
				     Instance => $instance );
}


sub _nextInFileHandle
{
    my $self = shift;
    my $fh = shift;

    my $pLogLine;
    while ($pLogLine = &SyslogScan::SendmailUtil::getNextMailTransfer($fh))
    {
	my $delivery = $self -> _transferToDelivery($pLogLine);
	return $delivery if defined($delivery);
    }
    return undef;  #at EOF
}    

# internal routines for storing and retrieving the information
#   in 'From:' lines.

# A 'mini-fromline' is a three-element array of (size, sender,
# instance), which stores the all the information we need about a
# formerly-seen from-line in a compact form.  By putting it in a
# compact form, the already-seen table only takes up about 2 mb in our
# environment when chomping through 3 days of mail, rather than 20 mb
# or more like it would take up if we stored the full SendmailLineFrom
# object.

sub _storeFromLine
{
    my $self = shift;
    my $pFromLine = shift;

    my $pSeenFromLine = $$self{seenFromLine};
    my $pFromHash = $$pFromLine{attrHash};
    my $id = $$pFromLine{messageID};

    my $miniFromLine;
    if (defined $$pSeenFromLine{$id})
    {
	print STDERR "already saw from-line with id $id\n"
	    unless $::gbQuiet;

	# We should probably use a Rule same as for messages where
	# the sender is unknown... but, this does not happen very
	# often, so no big deal.
	$miniFromLine = [0,"duplicate",0];
    }
    else
    {
        # to save on memory, we do not store the whole line
	$miniFromLine = [ $$pFromHash{'size'}, $$pFromHash{'from'},0 ];
    }
    $$pSeenFromLine{$id} = $miniFromLine;
}

sub _storeCloneLine
{
    my $self = shift;
    my $pCloneLine = shift;

    my $pSeenFromLine = $$self{seenFromLine};
    my $id = $$pCloneLine{messageID};

    my $miniFromLine;
    if (defined $$pSeenFromLine{$id})
    {
	print STDERR "already saw from-line with id $id\n"
	    unless $::gbQuiet;
	$miniFromLine = [0,"duplicate",0];
    }
    else
    {
	my $originalID = $$pCloneLine{clonedFrom};
	defined($originalID) || die "originalID undefined for ID $id";
	$miniFromLine = $$pSeenFromLine{$originalID};
    }
    $$pSeenFromLine{$id} = $miniFromLine;
}

sub _getIncrementAmount
{
    my $self = shift;
    my $pToLine = shift;
    my $receiverCount = @{$$pToLine{'toList'}};
    die "no receivers" unless $receiverCount > 0;
    return $receiverCount;
}

sub _recallFromLine
{
    my $self = shift;
    my $pToLine = shift;

    my $id = $$pToLine{messageID};
    my $pSeenFromLine = $$self{seenFromLine};
    my $miniFromLine = $$pSeenFromLine{$id};

    return $miniFromLine;   # undefined if we did not see from-line
}

sub _recallSize
{
    my $self = shift;
    my $fromLine = $self -> _recallFromLine(@_);
    return $$fromLine[0];
}

sub _recallSender
{
    my $self = shift;
    my $fromLine = $self -> _recallFromLine(@_);
    return $$fromLine[1];
}

sub _recallInstanceAndIncrement
{
    my $self = shift;
    my $fromLine = $self -> _recallFromLine(@_);
    my $incrementAmount = $self -> _getIncrementAmount(@_);
    
    $$fromLine[2] = 0 if ! defined($$fromLine[2]);
    $$fromLine[2] += $incrementAmount;

    #instance number starts at 1
    return $$fromLine[2] + 1 - $incrementAmount; 
}

my $ONE_MONTH = 30*24*60*60;
my $ELEVEN_MONTH = 11 * $ONE_MONTH;

my @LEGAL_KEY_LIST = qw( startDate endDate syslogList unknownSender
			unknownSize defaultYear );

$pValidateRule = sub {
    my $rule = shift;
    my $myKey;
    foreach $myKey (keys %$rule)
    {
	confess("illegal key for delivery rule: $myKey")
	    unless grep ($_ eq $myKey, @LEGAL_KEY_LIST);

	# sanity check
	die "internal error: wrong kind of reference"
	    unless $myKey
    }
};

my @gMonthList = qw ( jan feb mar apr may jun jul aug sep oct nov dec );
my %gMonthTable = ();
my ($i, $month);
foreach $month (@gMonthList)
{
    $gMonthTable{$month} = $i++;
}

1;

__END__

=head1 NAME

SyslogScan::DeliveryIterator -- scans a syslog file for "deliveries",
successful transfers of mail to mailboxes or to other machines.

=head1 SYNOPSIS

    use SyslogScan::Delivery;
    use SyslogScan::DeliveryIterator;
    
    my $iter = new SyslogScan::DeliveryIterator(syslogList =>
						["/var/log/syslog"]);
    
    my $delivery;
    while ($delivery = $iter -> next())
    {
        print $delivery -> summary();
    }

=head1 DESCRIPTION

A DeliveryIterator goes through your sendmail logging file (which may
be /var/log/syslog, /var/adm/messages, or something completely
different) looking for successful deliveries of mail to local
user-accounts or successful transfers of mail to remote machines.

Here is an excerpt from a sample syslog:

Jun 13 01:50:16 satellife sendmail[29556]: DAA29556: from=<shookway@fs1.ho.man.ac.uk>, size=954, class=0, pri=30954, nrcpts=1, msgid=<5B013544E0D@fs1.ho.man.ac.uk>, proto=ESMTP, relay=curlew.cs.man.ac.uk [130.88.13.7]

Jun 13 01:50:17 satellife sendmail[29558]: DAA29556: to=<shoko@time.healthnet.org>, delay=00:00:05, mailer=fidogate, stat=Deferred (Remote host is busy)

...

Jun 13 14:55:50 satellife sendmail[29558]: DAA29556: to=<shoko@time.healthnet.org>, delay=13:00:05, mailer=fidogate, stat=Sent

The delivery is not registered until 14:55:50.  In order to figure out
the size and sender, the iterator needs to have gone over the 'from'
entry associated with message DAA29566, otherwise it will return a
delivery with 'Sender' and 'Size' set to an undefined value (unless
you specified defaults when constructing your DeliveryIterator.)

=head2 METHOD 'NEW'

'new' creates a new iterator.

    my $iter =
        new SyslogScan::DeliveryIterator(startDate => "06.01.96 18:00:00",
					 endDate => "06.02.96 06:00:00",
					 syslogList =>
					 [/var/log/syslog.090696,
					  /var/log/syslog.090796],
					 unknownSender => 'antiquity',
					 unknownSize => 0,
					 defaultYear => 1996);

All of the above parameters are optional.

I<startDate> and I<endDate> define a span of time; we ignore
deliveries that fall before I<startDate> or after I<endDate>.  This
allows you to generate statistical reports about mail delivered over a
given span of time.

I<syslogList> is a list of files to search through for deliveries.
The alternative to specifying syslogList is to supply a file-handle to
a syslog file on each call to the next() method.

I<unknownSender> and I<unknownSize> are what to specify as the sender
and the size if we cannot determine from the logs who sent the message
and how large the message is.

I<defaultYear> is the year in which the deliveries are assumed to have
taken place (this is not specified in the syslog file.)  Default is to
guess the year that makes the delivery take place close to now.  (For
example, if 'now' is February 3rd 1996, then by default a delivery
made on December 14th is assumed to be in 1995, and a delivery made on
February 4th is assumed to be in 1996.

I<defaultYear> is deprecated, set the default year instead
with I<SyslogScan::ParseDate::setDefaultYear>.

=head2 METHOD 'NEXT'

Once an iterator is defined, the next() method will search for the
next delivery, skipping any deliveries which don't match the time
constraints of I<startDate> and I<endDate>.  There are two ways to
call next():

    # poll syslogList members
    $delivery = $iter -> next;

    # poll filehandle
    open(LOG,"/var/log/syslog");
    $delivery = $iter -> next(\*LOG);

=head2 OTHER OPERATIONS

The 'appendSyslog' method can add a syslog filename to the list
of syslog filenames which were specified at construction time
as 'syslogList'.

Setting the global variable I<$::gbQuiet> to 1 will suppress some
of the error messages to STDERR.

=head1 BUGS

If two messages have the same message ID through a bad coincidence, a
message is produced with sender of 'duplicate' and size of '0' rather
than using the unknownSender and unknownSize parameters.

Sender and receiver address are downcased automatically.  It would
probably be better if this module downcased only the host-name part of
the address and not the user-name.

Some mailings have a 'ctladdr' field; DeliveryIterator should probably
try to parse this as a backup clue for figuring out the sender.

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

L<SyslogScan::Delivery>, L<SyslogScan::Summary>
