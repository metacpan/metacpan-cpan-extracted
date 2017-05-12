package RFID::Alien::Reader;
$VERSION = '0.003';
@ISA=qw(RFID::Reader);

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004-2006 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

=head1 NAME

RFID::Alien::Reader - Abstract base class for a Alien RFID reader

=head1 SYNOPSIS

This abstract base class provides most of the methods required for
interfacing Perl with an Alien RFID reader.  To actually create an
object, use L<RFID::Alien::Reader::Serial|RFID::Alien::Reader::Serial> or
L<RFID::Alien::Reader::TCP|RFID::Alien::Reader::TCP>.  For example:

    use RFID::Alien::Reader::Serial;
    use Win32::SerialPort;

    $com = Win32::SerialPort->new('COM1')
	or die "Couldn't open COM port 'COM1': $^E\n";
    my $reader = 
      RFID::Alien::Reader::Serial->new(Port => $com,
				       PersistTime => 0,
				       AcquireMode => 'Inventory',
				       )
        or die "Couldn't create reader object";

    $reader->set(AntennaSequence => [0,1],
                 TagListAntennaCombine => 'OFF') == 0
        or die "Couldn't set reader properties";

    my @tags = $reader->readtags();
    foreach my $tag (@tags)
    {
	print "I see tag ",$tag->id,"\n";
    }

=head1 DESCRIPTION

This abstract base class implements the commands for communicating
with an Alien reader.  It is written according to the specifications
in the I<Alien Technology Reader Interface Guide v02.00.00>.  It was
tested with the original tag reader and also the ALR-9780.  It
inherits from L<RFID::Reader|RFID::Reader>.

To actually create a reader object, use
L<RFID::Alien::Reader::Serial|RFID::Alien::Reader::Serial> or
L<RFID::Alien::Reader::TCP|RFID::Alien::Reader::TCP>.  Those classes
inherit from this one.

=cut

use Carp;
use POSIX qw(strftime);
use Time::Local;
use RFID::Reader;
use RFID::EPC::Tag;

# Internal initialization function, called by child objects
sub _init
{
    my $self = shift;
    my(%p) = @_;
    my $greeting;

    $self->SUPER::_init(%p);

    if (defined($p{Login}) and defined($p{Password}))
    {
	# Log in
	$self->debug("Logging in\n");
	my $s = $self->{_sock};
	print $s $p{Login},"\r\n";
	$self->_readuntil('Password>');
	print $s $p{Password},"\r\n";
	my $d = $self->_readuntil('>');
	if ($d !~ /Alien$/)
	{
	    die "Login failed";
	}
    }

    # Ignore unknown settings, since they may be for a child module.
    if ((my @err = grep { !/Unknown setting/i } $self->set(%p)) != 0)
    {
	croak "Error creating new tag: could not set requested options: @err\n";
    }
    scalar($self->_simpleset(TagListFormat => 'text')) == 0
	or die "Couldn't set TagListFormat to text!\n";
    $self;
}

=head2 Methods

=head3 set

Set various properties of the reader or the internal state of the
object.  This method takes a hash-style list of any number of
I<key/value> pairs, and returns a list of errors that occured.  In a
scalar context, that evaluates to the number of errors that occured,
so you can test for errors like this:

    my @errs = $alien->set(SomeVariable => "New Value") == 0
      or die "Couldn't set SomeVariable: @errs";

See L<Properties|/Properties> for the properties that can be set, and
see L<the RFID::Reader set method|RFID::Reader/set> for more details
about this method.

=cut

sub set
{
    my $self = shift;
    my(%p) = @_;
    my @errs;

    while (my($var,$val)=each(%p))
    {
	if (lc $var eq 'timeout')
	{
	    $self->{timeout}=$val;
	}
	elsif (lc $var eq 'mask')
	{
	    if ($val =~ /^([0-9a-f]*)(?:\/(\d*))?(?:\/(\d*))?$/i)
	    {
		my($mask,$len,$start) = ($1,$2,$3);
		$len ||= length($mask)*4;
		if ( (length($mask) % 2) == 1)
		{
		    $mask .= "0";
		}
		$start ||= 0;
		push(@errs,
		     $self->_simpleset($var,
				       sprintf("%d, %d, %s",
					       $len, $start,
					       join(' ',
						    unpack("a2" x (length($mask)/2), 
							   $mask)))));
	    }
	    else
	    {
		croak "Invalid mask in ",(caller(0))[3]," mask option\n";
	    }
	}
	elsif (lc $var eq 'time')
	{
	    # Timezone trick from tye on PerlMonks
	    # ( localtime time() + 3600*( 12 - (gmtime)[2] ) )[2] - 12
	    my $timestr;
	    if ($val and $val =~ /\D/)
	    {
		$timestr=$val;
	    }
	    else
	    {
		$val ||= time;
		$timestr = strftime("%Y/%m/%d %H:%M:%S",localtime($val));
	    }
	    push(@errs,$self->_simpleset($var,$timestr));
	}
	elsif (lc $var eq 'antennasequence')
	{
	    if (ref($val))
	    {
		$val = join(", ",@$val);
	    }
	    push(@errs,$self->_simpleset($var,$val));
	}
	elsif (grep { lc $var eq lc $_ } 
	       (qw(AcquireMode PersistTime AcqCycles AcqEnterWakeCount
		   AcqCount AcqSleepCount AcqExitWakeCount PersistTime
		   TagListAntennaCombine
		   AcquireSleep AcquireWakeCount
		   )))
	{
	    push(@errs,$self->_simpleset($var,$val));
	}
	else
	{
	    push(@errs,$self->SUPER::set($var,$val));
	}
    }
    @errs;
}

# Internal function implementing a very simple set command
sub _simpleset
{
    my $self = shift;
    my($var,$val)=@_; 
    my $resp = $self->_command("set $var = $val");
    my @ret;

    if ($resp !~ /^$var /i)
    {
	@ret = ("set $var command failed!  Reader said: ".$resp);
    }
    else
    {
	@ret = ();
    }
    @ret;
}

=head3 get

Get various properties of the reader or the internal state of the
object.  This method takes a list of parameters whose value you'd like
to get.  In a list context, it returns a hash with the parameters you
asked for as the keys, and their values as the values.  In a scalar
context, it returns the value of the last property requested.  If an
error occurs or a value for the requested property can't be found,
it is set to C<undef>.

For example:

    my $AcquireMode = $alien->get('AcquireMode');
    my %props = $alien->get(qw(AcquireMode PersistTime ReaderVersion));

See L<Properties|/Properties> for the properties that can be retreived
with I<get>, and L<the RFID::Reader get method|RFID::Reader/get> for
more information about this method.

=cut

sub get
{
    my $self = shift;
    my %ret;

    foreach my $var (@_)
    {
	if (lc $var eq 'mask')
	{
	    my $mask = $self->_simpleget($var);
	    if ($mask =~ /all tags/i)
	    {
		$ret{$var}='';
	    }
	    elsif ($mask =~ /^(\d+),\s*(\d+),\s*(.*)$/)
	    {
		my($len,$start,$bits)=($1,$2,$3);
		if ($len == 0)
		{
		    $ret{$var}='';
		}
		else
		{
		    $bits =~ s/\s//g;
		    $ret{$var} = "$bits/$len";
		    if ($start)
		    {
			$ret{$var} .= "/$start";
		    }
		}
	    }
	}
	elsif (lc $var eq 'time')
	{
	    my $timestr = $self->_simpleget($var);
	    if (defined($timestr) and
		$timestr =~ m|(\d+)/(\d+)/(\d+) (\d+):(\d+):(\d+)|)
	    {
		if ($1 > 2045)
		{
		    # Too big for a Unix date!
		    $ret{$var} = 0xffffffff;
		}
		else
		{
		    $ret{$var} = timelocal($6,$5,$4,$3,$2-1,$1);
		}
	    }
	}
	elsif (lc $var eq 'antennasequence')
	{
	    my $antstr = $self->_simpleget($var);
	    if (defined($antstr))
	    {
		$ret{$var} = [map { s/\*$//; $_ } split(/,\s*/,$antstr)];
	    }
	}
	elsif (lc $var eq 'readerversion')
	{
	    my $val = $self->_command('get ReaderVersion');
	    $ret{$var}=$val;
	}

# This parses the reader version.  It's currently disabled, but should
# probably come back in some form.
#	elsif (lc $var eq 'readerversion')
#	{
#	    my $val = $self->_command('get ReaderVersion');
#	    my $r = {};
#	    $r->{string} = $val;
#	    while ( $val =~ /([^:]+):\s*([^\x0d\s,]+),?\s*/sg )
#	    {
#		if ($1 eq 'Ent. SW Rev')
#		{
#		    $r->{software}=$2;
#		}
#		elsif ($1 eq 'Country Code')
#		{
#		    $r->{country_code}=$2;
#		}
#		elsif ($1 eq 'Reader Type')
#		{
#		    $r->{reader_type}=$2;
#		}
#		elsif ($1 eq 'Firmware Rev')
#		{
#		    $r->{firmware}=$2;
#		}
#	    }
#	    $ret{$var}=$r;
#	}
 	elsif (grep { lc $var eq lc $_ } 
	       (qw(AcquireMode PersistTime AcqCycles AcqEnterWakeCount
		   AcqCount AcqSleepCount AcqExitWakeCount PersistTime
		   TagListAntennaCombine
		   )))
	{
	    $ret{$var} = $self->_simpleget($var);
	}
	else
	{
	    %ret=(%ret, $self->SUPER::get($var));
	}
    }
    if (wantarray)
    {
	return %ret;
    }
    else
    {
	# Return last value
	return $ret{$_[$#_]};
    }
}

# Internal function implementing a very simple get
sub _simpleget
{
    my $self = shift;
    my($var)=@_;
    
    my $resp = $self->_command("get $var");
    if ($resp =~ /^$var\s+.*?=\s*(.*?)[\s\x0a\x0d]*$/is)
    {
	return $1;
    }
    return undef;
}

=head3 readtags

Read all of the tags in the reader's field, honoring the requested
L<Mask|/Mask> and L<AntennaSequence|/AntennaSequence> settings.  This
returns a (possibly empty) list of L<RFID::Tag|RFID::Tag> objects.
For example:

    my @tags = $reader->readtags();
    foreach my $tag (@tags)
    {
	print "I see tag ",$tag->id,"\n";
    }

Parameters are a hash-style list of parameters that should be
L<set|set> for just this read.  The parameters are actually set to the
requested value at the beginning of the method call, and set back
before returning, so if you want to use the same parameters for many
calls (say in a loop) you will probably want to set them just once
with L<set|set>.

See L<the RFID::Reader readtags method|RFID::Reader/readtags> for more
information about this method.

=cut

sub readtags
{
    my $self = shift;
    my(%p)=@_;
    my $numreads = '';
    if ($p{Numreads})
    {
	$numreads = ' '.$p{Numreads};
	delete $p{Numreads};
    }
    $self->pushoptions(%p)
	if (keys %p);
    
    my $taglist = $self->_command('get TagList'.$numreads);
    my @tags;
    foreach my $tagline (split /\x0d\x0a/, $taglist)
    {
	next unless $tagline =~ /^Tag:/i;
	my %tp = ();
	foreach my $prop (split /,\s*/, $tagline)
	{
	    if ($prop =~ /^(.*?):(.*)/)
	    {
		if (lc $1 eq 'tag')
		{
		    ($tp{id}=uc $2) =~ s/[^0-9A-f]//g;
		}
		elsif (lc $1 eq 'ant')
		{
		  $tp{antenna} = $2;
		}
		else
		{
		    $tp{lc $1}=$2;
		}
	    }
	}
	my $tag = RFID::EPC::Tag->new(%tp);
	# hack
	$tag->{count} = $tp{count};
	push(@tags,$tag);
    }
    
    $self->popoptions()
	if (keys %p);

    return @tags;
}

=head3 sleeptags

Request that all tags addressed by the reader go to sleep, causing
them to ignore all requests from the reader until they are
L<awakened|waketags>.  Which tags are addressed by the reader is
affected by the L<Mask|/Mask> and L<AntennaSequence|/AntennaSequence>
settings.

Returns 1 to indicate success; currently it dies on an error, but may
return C<undef> in the future.

This method is not very well tested yet.  In particular, although the
commands appear to be issued correctly to the reader, the tags don't
seem to actually go to sleep.

Parameters are a hash-style list of parameters that should be
L<set|set> for just this read.  The parameters are actually set to the
requested value at the beginning of the method call, and set back
before returning, so if you want to use the same parameters for many
calls (say in a loop) you will probably want to set them just once
with L<set|set>.

=cut

sub sleeptags
{
    my $self = shift;

    $self->pushoptions(@_)
	if (@_);

    $self->_command('Sleep');

    $self->popoptions(@_)
	if (@_);

    1;
}

=head3 waketags

Request that all tags addressed by the reader which are currently
L<asleep|sleeptags> wake up, causing them to once again pay attention
to requests from the reader.  Which tags are addressed by the reader
is affected by the L<Mask|/Mask> and L<AntennaSequence|/AntennaSequence>
settings.

Returns 1 to indicate success; currently it dies on an error, but may
return C<undef> in the future.

This method is not very well tested yet, since L<sleeptags|sleeptags>
doesn't quite behave as expected.

Parameters are a hash-style list of parameters that should be
L<set|set> for just this read.  The parameters are actually set to the
requested value at the beginning of the method call, and set back
before returning, so if you want to use the same parameters for many
calls (say in a loop) you will probably want to set them just once
with L<set|set>.

=cut

sub waketags
{
    my $self = shift;

    $self->pushoptions(@_)
	if (@_);

    $self->_command('Wake');

    $self->popoptions(@_)
	if (@_);
}

=head3 reboot

Request that the reader unit reboot.

The object may behave unpredictably after a reboot; if you want to
continue using the reader you should create a new object.  This new
object will sync up with the reader and should work OK, once the
reboot is completed.  This may be fixed in the future.

=cut

sub reboot
{
    my $self = shift;
    $self->_command("reboot");
}

# This was useful for the Matrics reader, but not so much here.
# Next version it will probably either be internal, or be exposed
# in some more reasonable way.
sub finish
{
    1;
}

# Send a command to the reader, and wait for a response.  The response
# string is returned.
sub _command
{
    my $self = shift;
    my($cmd)=@_;
    $self->debug("sending cmd: '$cmd'\n");
    $self->_writebytes("\x01".$cmd."\x0d\x0a")
	or die "Couldn't write: $^E";
    my $r = $self->_getresponse($com);
    $r =~ s/^$cmd\x0a//;
    $r;
}

# Wait for a response from the reader, and return the response string.
sub _getresponse
{
    my $self = shift;
    
    my $resp = $self->_readuntil("\0");
    $self->debug(" got resp: '$resp'\n");
    return $resp;
}

=head2 Properties

There are various properties that can be controlled by the L<get|get>
and L<set|set> methods.  Some of these settings will cause one or more
commands to be sent to the reader, while other will simply return the
internal state of the object.  The value for a property is often a
string, but can also be an arrayref or hashref.  These properties try
to hide the internals of the Alien reader, and so their syntax doesn't
always exactly match that of the actual Alien command.

=head3 AcqCycles, AcqEnterWakeCount, AcqCount, AcqSleepCount, AcqExitWakeCount

These settings affect the operations of the anti-collision algorithm
used by Alien to scan for tags.  See the Alien documentation for more
information.

=head3 AcquireMode

Affects the way in which tags are found during a call to
L<readtags|readtags>.  If the mode is set to the string I<Inventory>,
an anti-collision search algorithm is used to find all tags in the
reader's view; if the mode is set to the string I<Global Scroll>, the
reader will quickly search for a single tag.

See the Alien documentation for more information.

=head3 AntennaSequence

An arrayref of the antenna numbers that should be queried, and in what
order.  Antennas are numbered from 0 to 3 (the same as on the front of
the reader unit).  For example:

    $alien->set(AntennaSequence => [0,1,2,3]);

The default AntennaSequence is C<[0]>; you must override this if you
want to read from more than one antenna.

=head3 Debug

Send debugging information to C<STDERR>.  Currently this is only on or
off, but in the future various debugging levels may be supported.
Debugging information is currently mostly I/O with the reader.

=head3 Mask

Set or get a bitmask for the tags.  After setting the mask, all
commands will only apply to tags whose IDs match the given mask.

The mask format is a string beginning with the bits of the tag as a
hex number, optionally followed by a slash and the size of the mask,
optionally followed by the bit offset in the tag ID where the
comparison should start.  For example, to look for 8 ones at the end
of a tag, you could use:

    $alien->set(Mask => 'ff/8/88');

A zero-length mask (which matches all tags) is represented by an empty
string.

=head3 PersistTime

Controls how long the reader will remember a tag after seeing it.  If
the reader has seen a tag within this time period when you use
L<readtags|readtags>, it will be returned even if it is no longer in
view of the reader.  You can set it to a number of seconds to remember
a tag, to C<0> to not remember tags, or to C<-1> to remember tags
until the L<readtags|readtags> method is executed.  The default is
C<-1>.

See the Alien documentation for more information.

=head3 TagListAntennaCombine

If this is set to C<ON>, a tag seen by multiple antennas will only
return one tag list entry.

See the Alien documentation for more information.

=head3 Time

The current time on the reader unit.  All tag responses are
timestamped, so setting the time may be useful.

The time is represented as Unix epoch time---that is, the number of
seconds since midnight on January 1 1970 in GMT.  You can either set
or get it using this format.

If you set the time to an empty string, the reader's time will be set
to the current time of the computer running the script.

Currently, no attempt is made to deal with the timezone.  That may be
addressed in the future.

=head3 Timeout

Request that requests to the reader that do not complete in the given
number of seconds cause a C<die> to happen.

=head3 ReaderVersion

Cannot be set.  Returns a string containing information about the
reader.

=head1 SEE ALSO

L<RFID::Alien::Reader::Serial>, L<RFID::Alien::Reader::TCP>,
L<RFID::Reader>, L<RFID::EPC::Tag>, L<http://whereabouts.eecs.umich.edu/code/rfid-perl/>.

=head1 AUTHOR

Scott Gifford E<lt>gifford@umich.eduE<gt>, E<lt>sgifford@suspectclass.comE<gt>

Copyright (C) 2004-2006 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.

=cut


1;
