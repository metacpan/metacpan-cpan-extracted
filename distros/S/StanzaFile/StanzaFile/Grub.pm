package StanzaFile::Grub ;

#
# Revision History:
#
#   21-Dec-2002 Dick Munroe (munroe@csworks.com)
#       Add documentation detailing the overridden methods.
#
#   17-May-2003 Dick Munroe (munroe@csworks.com)
#       Fix things so that package variables can't leak and clobber
#       other packages.
#
#   20-May-2003 Dick Munroe (munroe@csworks.com)
#       Make the test harness happy.
#

use strict ;
use vars qw($VERSION @ISA) ;

use StanzaFile ;

our $VERSION = "1.02" ;

our @ISA = qw(StanzaFile) ;

sub addHeader
{
    my ($theObject, $theLHS, $theRHS) = @_ ;

    $theObject->{'header'}->add($theLHS, $theRHS) ;

    return $theObject ;
} ;

sub isBeginning
{
    die "Too few arguments passed to StanzaFile::Grub::isBeginning" if (scalar(@_) < 2) ;

    my ($theObject, $theLine) = @_ ;

    if ($theLine =~ m/^title\s+(.*)/i)
    {
	my $theName = $1 ;

	$theName =~ s/(.*?)\s+$/$1/ ;
	$theName =~ s/\s{2,}/ /g ;

	return $theName ;
    } ;

    return undef ;
} ;

sub isValue
{
    my ($theObject, $theLine) = @_ ;

    #
    # The grub.conf file format consists of two distinct types of data.
    # The first is global configuration data and appears before the first
    # stanza (stanzaFlag in the object will be false when this data is
    # valid and required.  After that, there are image sections containing
    # menu commands and those have a substantially different format.
    #

    if ($theObject->{'stanzaFlag'})
    {
	#
	# If we really wanted to be anal, we could check for all the possible
	# keywords that could be in grub stanzas.  I don't really think there
	# is any reason to do that.
	#

	if ($theLine =~ m/^\s*(\w+)\s+(.*)/)
	{
	    return ($1, $2)
	} ;

	return undef ;
    }
    else
    {
	return $theObject->SUPER::isValue($theLine) ;
    } ;
} ;

sub headerAsString
{
    my $theObject = shift ;

    my $theString = $theObject->SUPER::stanzaAsString($theObject->header()) ;

    $theString =~ s/.*?\n// ;

    return $theString ;
} ;

sub stanzaAsString
{
    my ($theObject, $theStanza) = @_ ;

    my $theString = "title\t" . $theStanza->name() . "\n" ;

    my $theLength ;

    map { $theLength = length($_) if (length($_) > $theLength) ; } $theStanza->order() ;

    $theLength++ ;

    $theLength = "%-" . $theLength . "s" ;

    foreach ($theStanza->order())
    {
	$theString = $theString . "\t" . sprintf($theLength,$_) . $theStanza->item($_) . "\n" ;
    } ;

    return $theString ;
} ;

1;

=pod

=head1 NAME

StanzaFile::Grub - read, parse, and write Grand Unified Bootloader configuration
files.

=head1 SYNOPSIS
    
There are no interface changes between this and the parent
class, StanzaFile.  This is included, partly, as an example
of the ease with which additional different stanza file
formats can be supported using the StanzaFile class and,
mostly, because I used the StanzaFile::Grub class in a kernel
build and installation management package I wrote (check it
out, kif at sourceforge.net).

=head1 DESCRIPTION

The grub configuration file format differs in a couple of ways
from the WINDOWS.INI format.  It has a "global" section that
appears before any of the stanzas actually start.  This global
section is stored in a dummy stanza accessable via the header
method defined in StanzaFile.

The format of entries in the global section also differs from 
entries in the stanzas.

All this is dealt with by overriding 5 methods.

=over 4

=item $theObject->addHeader($leftHandSide, $rightHandSide)

addHeader puts a new global header item into the Grub StanzaFile
object.  The value of the new header item is the value of the
$rightHandSide variable and is optional for those header items
without values.

=item $theObject->headerAsString()

Produce a string suitable for printing that represents the contents
of the header portion of the Grub stanza file object.

=item $theObject->isBeginning($line)

A predicate which tests the line to see if it is the beginning of
a new stanza.  If it is, the value of the predicate is the name of
the new stanza.  Otherwise the value of the predicate is undefined.

=item $theObject->isValue($line)

A predicate which tests the line to see if it contains a name/value
pair and returns that pair as the value of the prediate.  Otherwise
it returns and undefined.

=item $theObject->stanzaAsString()

Produce a string suitable for printing that represents a Grub file
stanza other than the header.

=back

=head1 EXAMPLES

=head1 BUGS

None known.

=head1 WARNINGS

No comments or whitespace are preserved in the configuration file
when it is read and/or written.

=head1 AUTHOR

Dick Munroe (munroe@csworks). I'm looking for work.  If you hear
of anything that might be of interest to a VERY senior engineer/architect
drop me a note.  See 
L<http://www.acornsw.com/resume/dick.html> for details.

=head1 SEE ALSO

The Kernel Installation Facility uses these classes extensively.  For more
details see L<http://sourceforge.net/projects/kif/>

=cut

