package RFID::Reader;
$VERSION=0.005;
@ISA=qw(Exporter);
@EXPORT_OK=qw(hexdump ref_tainted);

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004-2006 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

=head1 NAME

RFID::Reader - Abstract base class for an RFID reader

=head1 SYNOPSIS

This abstract base class provides a general framework for a generic
RFID reader.  To actually create a reader, you'll have to use an
object corresponding to the type of reader you're using.

This documentation discusses aspects of an RFID reader that apply to
all readers.

Here's an example of how you might use a class derived from this one:

    use RFID::Blammo::Reader::TCP;
    my $reader = 
      RFID::Blammo::Reader::TCP->new(PeerAddr => 10.20.30.40,
                                     PeerPort => 4001)
        or die "Couldn't create Blammo reader";
    my $version = $reader->get("ReaderVersion");
    $reader->set(AntennaSequence => [ 4,3,2,1]);
    my @tags = $reader->readtags();
    foreach my $tag (@tags)
    {
	print "I see tag ",$tag->type,".",$tag->id,"\n";
    }

=head1 DESCRIPTION

This abstract base class provides a general framework and some utility
functions for writing an RFID reader.  It also provides emulation for
some features which may not be supported by all readers.

Because of its general nature, many of the options and methods
described here may not be supported in your specific reader.  They are
documented here so that all readers that implement these features will
implement them in the same manner.  To make this clearer, elements of
this class that should work for all readers will be marked I<All
Readers>, while elements that will only work with some readeres will
be marked I<Some Readers>.  To find out whether your reader supports a
specific reader, consult its documentation.

=cut

use strict;
use warnings;

use Carp;

# Prototype
sub uniq(&@);

sub _init
{
    my $self = shift;

    if ($ENV{RFID_DEBUG})
    {
	warn "Turning on debugging.\n";
	$self->set(Debug => $ENV{RFID_DEBUG});
    }
    $self;
}


=head2 Methods

=cut


# We should emulate:
#  Mask

=head3 set

This method must be supported by I<All Readers>.

Set one or more properties associated with a reader.  Depending on
implementation, this may send one or more commands to the reader, set
an internal flag, or take some other action.

This method takes a hash with the properties to be set as keys, and
their new values as values.  It returns a list of errors that occured;
if no errors occured, it will return an empty list. In a scalar
context, that evaluates to the number of errors that occured, so you
can test for errors like this:

    my @errs = $reader->set(SomeVariable => "New Value") == 0
      or die "Couldn't set SomeVariable: @errs";

See L<Properties|/Properties> for the properties that can be set.

=cut

sub set
{
    my $self = shift;
    my(%p)=@_;
    my @errs;

    while(my($k,$v) = each(%p))
    {
	if ($k eq 'UniqueTags')
	{
	    $self->{_unique_tags} = $v;
	}
	elsif ($k eq 'Debug')
	{
	    $self->{_debug} = $v;
	}
	else
	{
	    push(@errs,"Unknown setting '$k'\n");
	}
    }
    @errs;
}

=head3 get

This method must be supported by I<All Readers>.

Get various properties of the reader or the internal state of the
object.  This method takes a list of parameters whose values you'd
like to get.  In a list context, it returns a hash with the parameters
you asked for as the keys, and their values as the values.  In a
scalar context, it returns the value of the last property requested.
If a value for the requested property can't be found, it is set to
C<undef>.

For example:

    my $ReaderVersion = $reader->get('ReaderVersion');
    my %props = $reader->get(qw(ReaderVersion AntennaSequence ));

See L<Properties|/Properties> for the properties that can be retreived
with I<get>.

=cut

sub get
{
    my $self = shift;
    my %ret;

    foreach my $var (@_)
    {
	if ($var eq 'UniqueTags')
	{
	    $ret{$var} = $self->{_unique_tags}||0;
	}
	elsif ($var eq 'Debug')
	{
	    $ret{$var} = $self->{_unique_tags}||0;
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

=head3 readtags

This method must be supported by I<All Readers>.

Read all of the tags in the reader's field, honoring any settings
affecting the reading and filtering of tags.  This returns a (possibly
empty) list of L<RFID::Tag|RFID::Tag> objects (or objects derived from
this type) .  For example:

    my @tags = $reader->readtags();
    foreach my $tag (@tags)
    {
	print "I see tag ",$tag->type,".",$tag->id,"\n";
    }

In the event of a serious error, this method will raise an exception
with C<die>.  If you want your program to keep going in the face of
serious errors, you should catch the exception with C<eval>.

Parameters are a hash-style list of parameters that should be
L<set|set> for just this read.

=cut

sub readtags
{
    croak "readtags is not implemented in abstract base clase ".__PACKAGE__;
}


=head3 sleeptags

This method is supported by I<Some Readers>.

Request that all tags addressed by the reader go to sleep, causing
them to ignore all requests from the reader until they are
L<awakened|waketags>.  Which tags are addressed by the reader is
affected by various settings, possibly including L<Mask|/Mask> and
L<AntennaSequence|/AntennaSequence>.

Parameters are a hash-style list of parameters that should be
L<set|set> for just this read.

In the event of a serious error, this method will raise an exception
with C<die>.  If you want your program to keep going in the face of
serious errors, you should catch the exception with C<eval>.

=cut

sub sleeptags
{
    croak "sleeptags is not implemented in abstract base clase ".__PACKAGE__;
}

=head3 waketags

Request that all tags addressed by the reader which are currently
L<asleep|sleeptags> wake up, causing them to once again pay attention
to requests from the reader.  Which tags are addressed by the reader
is affected by various settings, possibly including L<Mask|/Mask> and
L<AntennaSequence|/AntennaSequence>.

Parameters are a hash-style list of parameters that should be
L<set|set> for just this read.

In the event of a serious error, this method will raise an exception
with C<die>.  If you want your program to keep going in the face of
serious errors, you should catch the exception with C<eval>.

=cut

sub waketags
{
    croak "waketags is not implemented in abstract base clase ".__PACKAGE__;
}



#####
# Functions for use by derived classes.
#####

# Push the current values for various settings onto an internal stack,
# then set them to their new values.  popoptions will restore the
# original values.
sub pushoptions
{
    my $self = shift;
    my(%p)=@_;

    my %prev;
    while (my($k,$v)=each(%p))
    {
	# Get the option
	my $curval = $self->get($k);
	defined($curval)
	    or croak "Couldn't get initial value of '$k'!\n";
	$prev{lc $k} = $curval;
    }
    push(@{$self->{_option_stack}},\%prev);
    $self->set(%p);
}

# Restore values set by pushoptions.
sub popoptions
{
    my $self = shift;

    my $prev = pop(@{$self->{_option_stack}})
	or croak "No options to pop!!";
    $self->set(%$prev);
}

# Functions for use by derived classes.
sub filter_tags
{
    my $self = shift;
    my @tags = @_;

    if ($self->{_unique_tags} || $self->{_combine_antennas})
    {
	@tags = uniq { $a->tagcmp($b) } 
	  sort { $a->tagcmp($b) } 
  	    @tags;
	
	# This is never used, but the code is written already, so it's
	# here as a placeholder in case it's implemented later.
	if ($self->{_combine_antennas})
	{
	    my $lasttag;
	    foreach my $i (0..$#tags)
	    {
		if (defined($lasttag) and ($tags[$i]->id eq $lasttag))
		{
		    splice(@tags,$i,1);
		}
	    }
	}
    }
    @tags;
}

# Utility Functions
sub sortcmp
{
    my $sub = shift;
    local($a,$b)=@_;
    $sub->();
}

sub uniq(&@)
{
    my($cmpsub, @list)=@_;
    my $last = shift @list
	or return ();
    my @ret =($last);
    foreach (@list)
    {
	push(@ret,$_)
	    unless sortcmp($cmpsub,$_,$last)==0;
	$last = $_;
    }
    @ret;
}

# Internal debugging function.
sub debug
{
    return unless $_[0]->{_debug};

    my $self = shift;
    if ($_[0] =~ /^\d+$/)
    {
	return unless $self->{_debug} >= $_[0];
	shift;
    }
    warn((caller(1))[3],": ",@_);
}

# Return the current debug level
sub debuglevel
{
    my $self = shift;
    $self->{_debug};
}

sub hexdump
{
    join(' ',unpack("H2 " x length($_[0]),$_[0]),'');
}

# From perlsec(1)
sub ref_tainted {
    return ! eval { eval("#" . substr(${$_[0]}, 0, 0)); 1 };
}

=head2 Properties

There are various properties that are managed by the L<get|get> and
L<set|set> methods.  Some of these settings will cause one or more
commands to be sent to the reader, while other will simply return the
internal state of the object.  The value for a property is often a
string, but can also be an arrayref or hashref.

=head3 AntennaSequence

I<Some Readers>.

An arrayref of the antenna names that should be queried, and in what
order.  RFID drivers can name their antennas any way they like, though
often they will be numbers.  For example:

    $reader->set(AntennaSequence => [0,1,2,3]);

The default AntennaSequence is reader-specific.

=head3 Debug

I<All Readers>.

Control the amount of debugging information sent to C<STDERR>.  A
higher value for this property will cause more information to be
output.

=head3 Mask

I<Some Readers>.

Set or get a bitmask for the tags.  After setting the mask, all
commands will only apply to tags whose IDs match the given mask.

The mask format is a string beginning with the bits of the tag as a
hex number, optionally followed by a slash and the size of the mask,
optionally followed by the bit offset in the tag ID where the
comparison should start.  For example, to look for 8 ones at the end
of a tag, you could use:

    $reader->set(Mask => 'ff/8/88');

A zero-length mask (which matches all tags) is represented by an empty
string.

=head3 UniqueTags

I<All Readers>, possibly through emulation.

A boolean value controlling whether duplicate tags should be removed
from the list returned by L<readtags|/readtags>.

=head1 SEE ALSO

L<RFID::Tag>, L<RFID::Reader::Serial>, L<RFID::Reader::TCP>,
L<http://whereabouts.eecs.umich.edu/code/rfid-perl/>, The manual for
your particular RFID driver class.

=head1 AUTHOR

Scott Gifford E<lt>gifford@umich.eduE<gt>, E<lt>sgifford@suspectclass.comE<gt>

Copyright (C) 2004-2006 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.

=cut


1;

