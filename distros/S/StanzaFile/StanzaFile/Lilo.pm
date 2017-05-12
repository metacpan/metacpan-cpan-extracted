#
# Revision History:
#   27-Nov-2002 Dick Munroe (munroe@csworks.com)
#       Initial Version Created.
#
#   22-Dec-2002 Dick Munroe (munroe@csworks.com)
#       Add documentation on use and overridden methods.
#
#   17-May-2003 Dick Munroe (munroe@csworks.com)
#       Fix things so that package variables can't leak and clobber
#       other packages.
#
#   20-May-2003 Dick Munroe (munroe@csworks.com)
#       Make the test harness happy.
#

package StanzaFile::Lilo ;

use strict ;
use vars qw($VERSION @ISA) ;

use StanzaFile::Grub ;

our $VERSION = "1.02" ;

our @ISA = qw(StanzaFile::Grub) ;

sub isBeginning
{
    die "Too few arguments passed to StanzaFile::Lilo::isBeginning" if (scalar(@_) < 2) ;

    my ($theObject, $theLine) = @_ ;

    if ($theLine =~ m/^image\s*=\s*(.*)/i)
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

    if ($theLine =~ m/^\s*(.*?)\s*=\s*(.*)/)
    {
	return ($1, $2) ;
    }
    elsif ($theLine =~ m/^\s*(.*?)(\s|$)/)
    {
	return ($1, undef) ;
    }
    else
    {
	return undef ;
    } ;
} ;

sub stanzaAsString
{
    my ($theObject, $theStanza) = @_ ;

    my $theString = "image=" . $theStanza->name() . "\n" ;

    my $theLength ;

    map { $theLength = length($_) if (length($_) > $theLength) ; } $theStanza->order() ;

    $theLength++ ;

    $theLength = "%-" . $theLength . "s" ;

    foreach ($theStanza->order())
    {
	$theString = $theString . "\t" . sprintf($theLength,$_) ;
	if (defined($theStanza->item($_)))
	{
	    $theString = $theString . "= " . $theStanza->item($_) ;
	} ;
	$theString = $theString . "\n" ;
    } ;

    return $theString ;
} ;

1;

=pod

=head1 NAME

StanzaFile::Lilo - read, parse, and write Linux Loader configuration
files.

=head1 SYNOPSIS
    
There are no interface changes between this and the parent
class, StanzaFile::Grub.  This is included, partly, as an example
of the ease with which additional different stanza file
formats can be supported using the StanzaFile class and,
mostly, because I used the StanzaFile::Lilo class in a kernel
build and installation management package I wrote (check it
out, L<http://www.sourceforge.net/projects/kif/>).

=head1 DESCRIPTION

The lilo configuration file format differs in a couple of ways
from the grug.conf format.  Both are in stanzas, but the stanza
beginning and the format of the lines in the file are slightly
different.

These differences are accommodated by overriding three of the
methods defined in StanzaFile::Grub.  These are:

=item $theObject->isBeginning($line)

A predicate which tests the line to see if it is the beginning of
a new stanza.  If it is, the value of the predicate is the name of
the new stanza.  Otherwise the value of the predicate is undefined.

=item $theObject->isValue($line)

A predicate which tests the line to see if it contains a name/value
pair and returns that pair as the value of the prediate.  Otherwise
it returns and undefined.

=item $theObject->stanzaAsString()

Produce a string suitable for printing that represents a lilo
configuration file stanza other than the header.

=head1 EXAMPLES

=head1 BUGS

=head1 WARNINGS

No comments or whitespace are preserved in the configuration file
when it is read and/or written.

=head1 AUTHOR

Dick Munroe (munroe@csworks). I'm looking for work.  If you hear
of anything that might be of interest to a VERY senior engineer/architect
drop me a note.  See 
http://www.acornsw.com/resume/dick.html for details.

=head1 SEE ALSO

=cut

