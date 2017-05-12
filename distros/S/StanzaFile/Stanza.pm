#
# Revision History:
#
#   21-Dec-2002 Dick Munroe (munroe@csworks.com)
#       Finish Documentation.
#
#   20-May-2003 Dick Munroe (munroe@csworks.com)
#       Make sure package variables don't leak.
#       Make the test harness happy.
#

package Stanza ;

use vars qw($VERSION) ;
use strict ;

our $VERSION = "1.02" ;

sub new
{
    my ($thePackage, $theName) = @_ ;

    my $theClass = ref($thePackage) || $thePackage ;
    my $theParent = ref($thePackage) && $thePackage ;

    my $theStanza =
    {
	'name' => $theName,
	'order' => [],
	'data' => {}
    } ;

    bless $theStanza, $theClass ;

    if ($theParent)
    {
	$theStanza->name($theParent->name()) ;

	foreach ($theParent->order())
	{
	    $theStanza->add($_, $theParent->item($_)) ;
	} ;
    } ;

    return $theStanza ;
} ;

sub add
{
    die "Too few arguments to add" if (scalar(@_) < 3) ;

    my ($theObject, $theName, $theData) = @_ ;

    $theObject->{'data'}->{$theName} = $theData ;
    push @{$theObject->{'order'}},$theName ;
    
    return $theObject ;
} ;

sub item
{
    my ($theObject, $theName, $theValue) = @_ ;

    if (scalar(@_) > 2)
    {
	if (exists($theObject->{'data'}->{$theName}))
	{
	    $theObject->{'data'}->{$theName} = $theValue ;
	}
	else
	{
	    $theObject->add($theName, $theValue) ;
	} ;
    } ;

    return $theObject->{'data'}->{$theName} ;
} ;

#
# Merge the contents of two stanzas.
#
# If an item exists in both stanzas, replace it in the
# target.  If it doesn't exist in the target, add it to
# the target.  This updates the order array to hold the
# order of addition stable.
#

sub merge
{
    my ($theObject, $theNewStanza) = @_ ;

    foreach ($theNewStanza->order())
    {
	if (defined($theObject->item($_)))
	{
	    $theObject->item($_,$theNewStanza->item($_)) ;
	}
	else
	{
	    $theObject->add($_,$theNewStanza->item($_)) ;
	} ;
    } ;

    return $theObject ;
} ;

sub name
{
    my ($theObject, $theName) = @_ ;

    $theObject->{'name'} = $theName if (scalar(@_) > 1) ;

    return $theObject->{'name'} ;
} ;

sub order
{
    my ($theObject) = @_ ;

    return @{$theObject->{'order'}} ;
} ;

1 ;

=pod

=head1 NAME

Stanza - Container for holding data parsed from stanza
files.

=head1 SYNOPSIS

    # Instantiate or clone a copy of a stanza.
    #
    my $theStanza = new Stanza('Stanza Name') ;

    # Add a datum to a Stanza.
    #
    $theStanza->add('newDatum', 'value') ;

    # Fetch or store an item in a Stanza.
    #
    my $theOldValue = $theStanza->item('newDatum') ;
    $theStanza->item('newDatum', 'newValue') ;

    # Merge the contents of two stanzas.
    #
    $theNewStanza->merge($theOldStanza) ;

    # Get/set the name of the stanza.
    #
    $theStanza->name() ;
    $theStanza->name('newName') ;

    # Get the order in which data were added to the stanza.
    #
    foreach ($theStanza->order())
    {
	... ;
    } ;

=head1 DESCRIPTION

The Stanza class provides a syntax free container for holding
stanza datum/value pairs.  As a consequence, StanzaFile formatting
must be done in the classes using the Stanza class, not by 
the Stanza class or sub-classes thereof.

=head1 EXAMPLES

=head1 BUGS

None known.

=head1 WARNINGS

=head1 AUTHOR

Dick Munroe (munroe@csworks).  I'm looking for work.  If you hear
of anything that might be of interest to a VERY senior engineer/architect
drop me a note.  See http://www.acornsw.com/resume/dick.html for
details.

=head1 SEE ALSO

=cut

