package RFID::Tag;
use RFID::Reader; $VERSION=$RFID::Reader::VERSION;
@ISA=qw(Exporter);
@EXPORT_OK = qw(tagcmp);

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004-2006 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

=head1 NAME

RFID::Tag - Abstract base class for an RFID tag object

=head1 SYNOPSIS

This abstract base class provides a general framework for an abstract
RFID tag.  These objects are usually returned by an
L<RFID::Reader|RFID::Reader> object:

    use RFID::SchmoozeMatic::Reader;

    my $reader = 
      RFID::SchmoozeMatic::Reader::TCP->new(PeerAddr => 'schmooze.example.com',
	 		            PeerPort => 4001,
				    )
        or die "Couldn't create reader object";

    my @tags = RFID::SchmoozeMatic::Reader->new->readtags();
    foreach my $tag (@tags)
    {
	my %t = $tag->get(qw(id Type Location))
	print "I see tag $t{Type}.$t{id} at $t{Location}\n";
    }

Tags don't support changing their properties; if you need to do that,
create a new tag using some of the properties of the tag you want to
change.

=cut

use strict;
use warnings;

use Carp;
use Exporter;

use constant TAGTYPE => 'unknown';

=head1 DESCRIPTION

=head2 Methods

=cut

# A simple initializer function that will just set the id and the
# antenna

sub _init
{
    my $self = shift;
    my(%p) = @_;

    foreach my $param (keys %p)
    {
	if (grep { lc $param eq $_ } qw(id antenna time location))
	{
	    $self->{lc $param} = $p{$param}
  	        unless defined($self->{lc $param});
	}
    }

    $self;
}

=head3 get

Get various properties of the tag.  This method takes a list of
parameters whose values you'd like to get.  In a list context, it
returns a hash with the parameters you asked for as the keys, and
their values as the values.  In a scalar context, it returns the value
of the last property requested.  If an error occurs or a value for the
requested property can't be found, it is set to C<undef>.

For example:

    my $tagtype = $tag->get('Type');
    my %tag_properties = $tag->get(qw(Type ID Location));

See L<Properties|/Properties> for the properties that can be retreived
with I<get>.

=cut

sub get
{
    my $self = shift;
    my %ret;

    foreach my $var (@_)
    {
	if (lc $var eq 'type')
	{
	    $ret{$var} = $self->type;
	}
	elsif (grep {lc $var eq $_} qw(id antenna time location))
	{
	    $ret{$var}=$self->{lc $var};
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

=head3 id method

Returns the tag's ID as a string.  This is a shortcut for using the
L<get|get> method.

=cut

sub id
{
    my $self = shift;
    $self->{id};
}

=head3 type

Returns the tag's type as a string.  This is a shortcut for using the
L<get|get> method.

=cut

sub type
{
    my $self = shift;
    TAGTYPE;
}


=head3 tagcmp

Compares another tag to this one, returning a value like C<cmp>: -1 if
this tag is smaller, 0 if the tags are the same, or 1 if the other tag
is smaller.

You can use this method in a call to C<sort>:

    @sorted_tags = sort { $a->tagcmp($b) } @tags;

The implementation in the abstract base class does an alphabetic
comparison of the tags IDs converted to strings.

=cut

# This is a fallback method that just compares tags as strings.  Most
# tag types should implement a better method than this if the tag
# types are the same, and if the types are different then fall back on
# this.

sub tagcmp
{
    my $self = shift;
    my($other) = @_;

    $self->id cmp $other->id;
}


=head2 Properties

These are the properties you can retreive with L<get|get>.  Properties
which must be available with all types of tags are marked with I<All
Tags>; properties which may or may not be available are marked with
I<Some Tags>.

=head3 Antenna

I<Some Tags>.

Which antenna this tag was detected from.

=head3 id

I<All Tags>.

The identifier for this tag as a string.

=head3 Location

I<Some Tags>.

The location where this tag was detected as a string.

=head3 Time

I<Some Tags>.

The time when this tag was detected, in the format returned by C<time>
(Unix epoch time).

=head3 Type

A string describing the type of this tag.

=head1 SEE ALSO

L<RFID::Reader>,
L<http://whereabouts.eecs.umich.edu/code/rfid-perl/>, The manual for
your particular RFID driver class, The manual for your RFID driver's
tag class.

=head1 AUTHOR

Scott Gifford E<lt>gifford@umich.eduE<gt>, E<lt>sgifford@suspectclass.comE<gt>

Copyright (C) 2004-2006 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.

=cut


1;
