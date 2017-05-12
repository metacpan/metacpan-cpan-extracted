#
# Revision History:
#
#   27-Nov-2002 Dick Munroe (munroe@csworks.com)
#       Break structure initialization out of the new function to make
#       inheritance easier.
#       Allow Stanzas to have keywords without arguments when converting
#       back to strings.
#
#   20-Dec-2002 Dick Munroe (munroe@csworks.com)
#       Add use strict, restrict the version of perl to 5.8.0 or higher,
#       and necessary changes imposed by use strict.
#
#
#   17-May-2003 Dick Munroe (munroe@csworks.com)
#       Fix things so that package variables can't leak.
#
#   20-May-2003 Dick Munroe (munroe@csworks.com)
#       Make the test harness happy.
#       Forgot the tests in the MANIFEST.
#       Backport to 5.6.1
#

package StanzaFile ;

use strict ;
use vars qw($VERSION) ;

use FileHandle ;
use Stanza ;

our $VERSION = "1.05" ;

sub _new
{
    my $thePackage = shift ;

    $thePackage = ref($thePackage) || $thePackage ;

    my $theStanzaFile =
    {
	'stanzaFlag' => undef,
	'header' => new Stanza('header'),
	'stanza' => {},
	'order'  => []
    } ;

    return bless $theStanzaFile, $thePackage ;
} ;

#
# Create a new stanza file object.
#
# Arguments:
#
#   file_name => string
#   file_handle => FileHandle object reference.
#   file_string => string
#

sub new
{
    my $thePackage = shift ;

    die "Odd number of arguments passed to StanzaFile::new"  if ((scalar(@_) % 2) != 0) ;

    my %ARGS = @_ ;

    my $theStanzaFile = $thePackage->_new() ;

    $theStanzaFile->read(%ARGS) if (%ARGS) ;

    return $theStanzaFile ;
} ;

#
# Interface to be able to add "header" information which is simply
# information that appears in the file prior to the occurance of
# a stanza.  By default, this is an invalid syntax.
#

sub addHeader
{
    my ($theObject, $theHeader) = @_ ;

    die "Information not in a Stanza: $theHeader" ;
} ;

#
# Add a new stanza.  Keep track of the order of addition.
#

sub add
{
    my ($theObject, $theStanza) = @_ ;

    die "Can't add anything but Stanza's" if (ref($theStanza) ne "Stanza") ;

    $theObject->{'stanza'}->{$theStanza->name}=$theStanza ;
    push @{$theObject->{'order'}},$theStanza->name ;

    return $theObject ;
} ;

#
# Does the specified stanza exist?
#

sub exists
{
    die "Too few arguments passed to StanzaFile::exists" if (scalar(@_) < 2) ;

    my ($theObject, $theStanzaName) = @_ ;

    if (ref($theStanzaName) && ($theStanzaName->isa('Stanza')))
    {
	return $theObject->{'stanza'}->{$theStanzaName->name()} ;
    }
    else
    {
	return $theObject->{'stanza'}->{$theStanzaName} ;
    } ;
} ;

#
# True if this is the beginning of a stanza, otherwise false.  The
# true value is the contents marking the beginning of a stanza.
#

sub isBeginning
{
    die "Too few arguments passed to StanzaFile::isBeginning" if (scalar(@_) < 2) ;

    my ($theObject, $theLine) = @_ ;

    if ($theLine =~ m/\s*\[([^\]]+)\]/)
    {
	my $theName = $1 ;

	$theName =~ s/^\s+(.*)/$1/ ;
	$theName =~ s/(.*?)\s+$/$1/ ;
	$theName =~ s/\s{2,}/ /g ;

	return $theName ;
    } ;

    return undef ;
} ;

#
# Return true if this is a comment or a blank line.
#

sub isComment
{
    die "Too few arguments passed to StanzaFile::isComment" if (scalar(@_) < 2) ;

    my ($theObject, $theLine) = @_ ;

    return $theLine =~ m/^\s*(\#|$)/ ;
} ;

#
# Return the name/value pair if this is, indeed, a name/value pair
# otherwise return false.
#

sub isValue
{
    my ($theObject, $theLine) = @_ ;

    if ($theLine =~ m/\s*([\w ]+?)\s*=\s*(.*)/)
    {
	return ($1, $2) ;
    } ;

    return undef ;
} ;

#
# Create a new stanza of the "appropriate" type.
#

sub newStanza
{
    my ($theObject, $theName) = @_ ;

    return new Stanza($theName) ;
} ;

#
# Parse the stanza file into stanzas.  The contents of the
# file is passed as array arguments.
#

sub parse
{
    my $theObject = shift ;

    die "Too few arguments to StanzaFile::parse" if (scalar(@_) < 2) ;

    my $theStanza ;

    foreach (@_)
    {
	#
	# Don't process comment characters or blank lines
	#

	next if $theObject->isComment($_) ;

	my $theStanzaName ;

	if ($theStanzaName = $theObject->isBeginning($_))
	{
	    #
	    # Found the beginning of a stanza, create a new stanza object,
	    # add it to the contents of the current object and continue.
	    #

	    $theStanza = $theObject->newStanza($theStanzaName) ;
	    
	    $theObject->add($theStanza) ;

	    $theObject->{'stanzaFlag'} = 1 ;
	}
        else
	{
	    #
	    # If it isn't a comment, a stanza introduction, or a blank line,
	    # then it must be a line to be added to the current stanza (if
	    # there is a stanza in progress) or to the header (if there isn't
	    # a stanza in progress).
	    #

	    if ($theObject->{'stanzaFlag'})
	    {
		eval
		{
		    $theStanza->add($theObject->isValue($_)) ;
		} ;
	    }
	    else
	    {
		eval
		{
		    $theObject->addHeader($theObject->isValue($_)) ;
		} ;
	    } ;

	    die "Invalid format in Stanza $theStanza->name(): $_" if ($@) ;
	} ;
    } ;
    
    return $theObject ;
} ;

#
# Process a file into a set of stanzas.
#
# Arguments (one of the following):
#
#       file_handle=>FileHandle object reference to opened file.
#       file_name  =>Path to file.
#       file_string=>Contents of file.
#

sub read
{
    die "Too few arguments to StanzaFile::Read" if (scalar(@_) < 2) ;
    
    my $theObject = shift ;

    die "Wrong number of arguments passed to StanzaFile::read" if ((scalar(@_) % 2) ne 0) ;

    my %ARGS = @_ ;

    my @theFile ;

    if (defined($ARGS{'file_string'}))
    {
	@theFile = split /\n/,$ARGS{'file_string'} ;
    }
    elsif (defined($ARGS{'file_name'}))
    {
	my $theFileHandle = new FileHandle "< " . $ARGS{'file_name'} ;
	
	die "Can't open " . $ARGS{'file_name'} . " for input" if (!defined($theFileHandle)) ;

	@theFile = $theFileHandle->getlines() ;

	undef $theFileHandle ;
    }
    elsif (defined($ARGS{'file_handle'}))
    {
	die "Must be a FileHandle class in StanzaFile::read('file_handle=>...)" if (!$ARGS{'file_handle'}-isa("FileHandle")) ;
	
        @theFile = $ARGS{'file_handle'}->getlines
    }
    else
    {
	die "Missing argument for StanzaFile::read" ;
    } ;

    return $theObject->parse(@theFile) ;
} ;

#
# Produce a string representation of a stanza file.  The default
# "windows.ini" form which the base class parses is of the form:
#
# [name]
# name=value
# ...
#
# [name]
# ...
#
# Note that all comments are lost during the input/output process
# using StanzaFile.
#
# FIX ME It seems more natural for the stanza's do be doing the
# stringifying but the parseing is being done in the stanza file
# class and all stanzas are are containers for data, so ...
#

sub headerAsString
{
    return "" ;
} ;

sub stanzaAsString
{
    my ($theObject, $theStanza) = @_ ;

    my $theString = "[" . $theStanza->name() . "]\n" ;

    foreach ($theStanza->order())
    {
	if (defined($theStanza->item($_)))
	{
	    $theString = $theString . $_ . "=" . $theStanza->item($_) . "\n" ;
	}
	else
	{
	    $theString = $theString . $_ . "\n" ;
	} ;
    } ;

    return $theString ;
} ;

sub asString
{
    my $theObject = shift ;

    my $theString = $theObject->headerAsString() . "\n" ;

    foreach ($theObject->order())
    {
	$theString = $theString . $theObject->stanzaAsString($theObject->stanza($_)) . "\n" ;
    } ;

    $theString =~ s/^\n+// ;
    chomp($theString) ;

    return $theString ;
} ;

#
# Produce a file from a set of stanzas.
#
# Arguments (one of the following):
#
#       file_handle=>FileHandle object reference to opened file.
#       file_name  =>Path to file.
#       file_string=>Reference to string to contain file.
#

sub write
{
    die "Too few arguments to StanzaFile::write" if (scalar(@_) < 2) ;
    
    my $theObject = shift ;

    die "Wrong number of arguments passed to StanzaFile::read" if ((scalar(@_) % 2) ne 0) ;

    my %ARGS = @_ ;

    my $theFile = $theObject->asString() ;

    if (defined($ARGS{'file_string'}))
    {
	${$ARGS{'file_string'}} = $theFile ;
    }
    elsif (defined($ARGS{'file_name'}))
    {
	my $theFileHandle = new FileHandle "> " . $ARGS{'file_name'} ;
	
	die "Can't open " . $ARGS{'file_name'} . " for output" if (!defined($theFileHandle)) ;

	$theFileHandle->print($theFile) ;

	undef $theFileHandle ;
    }
    elsif (defined($ARGS{'file_handle'}))
    {
	die "Must be a FileHandle class in StanzaFile::write('file_handle=>...)" if (!$ARGS{'file_handle'}-isa("FileHandle")) ;
	
        $ARGS{'file_handle'}->print($theFile) ;
    }
    else
    {
	die "Missing argument for StanzaFile::write" ;
    } ;

    return $theFile ;
} ;

#
# Replace an [possibly] existing Stanza.
#

sub replace
{
    my ($theObject, $theStanza) = @_ ;

    die "Can't replace anything but Stanza's" if (ref($theStanza) ne "Stanza") ;

    if (!$theObject->exists($theStanza))
    {
	push @{$theObject->{'order'}},$theStanza->name ;
    } ;

    $theObject->{'stanza'}->{$theStanza->name}=$theStanza ;

    return $theObject ;
} ;

#
# Accessor Functions.
#

sub header
{
    my $theObject = shift ;

    return $theObject->{'header'} ;
} ;

sub order
{
    my $theObject = shift ;

    return @{$theObject->{'order'}} ;
} ;

sub stanza
{
    my ($theObject, $theName) = @_ ;

    if (ref($theName) && ($theName->isa('Stanza')))
    {
	return $theObject->{'stanza'}->{$theName->name()} ;
    }
    else
    {
	return $theObject->{'stanza'}->{$theName} ;
    } ;
} ;

1 ;

=pod

=head1 NAME

StanzaFile - read, parse, and write files containing "stanzas".

=head1 SYNOPSIS
    
    # Parse a .ini format file into stanzas.
    #

    use StanzaFile ;
    my $a = new StanzaFile(file_name=>"/etc/wvdial.conf") ;

    # Add a new stanza to a StanzaFile.
    #
    $a->add(new Stanza('Stanza Name')) ;

    # Check for a stanza's existance.
    #
    if ($a->exists('New Stanza'))
    {
	...
    } ;

    # Parse a .ini format file into stanzas.
    #

    use StanzaFile ;
    my $a = new StanzaFile ;
    $a->read(file_name=>"/etc/wvdial.conf") ;

    # Produce a string version of the StanzaFile
    # (Comments and other formatting are lost)
    #

    my $theString = $a->asString() ;

    # Write the StanzaFile.
    #
    $a->write("/etc/newFile.conf") ;

    # Add a new stanza to the file, replacing the stanza if it
    # already exists in the file.
    #
    $theNewStanza = new Stanza('New Stanza') ;
    $a->replace($theNewStanza) ;

    # Access the "header" stanza.
    #
    my $theHeaderStanza = $a->header() ;

    # Order in which the stanzas were added to the stanza file.
    #
    my @theAdditionOrder = $a->order() ;

    # Get a stanza object from the stanza file.
    #
    my $theStanzaObject = $a->stanza('The Stanza') ;

=head1 DESCRIPTION

A number of Linux configuration files are stored in a Windows format
know as "stanzas" or WINDOWS.INI format.  These files are of the form

     [name]
         variable=value
         variable1=value1
         ...

     [name1]
         variableA=valueA
         variable1A=value1A

and so on.  This class is designed to provide parsing and processing
capabilities for the WINDOWS.INI format and provide a general enough
framework so that other formats of stanzas can be easily supported
(see StanzaFile::Grub for an example).

With the StanzaFile and it's companion class Stanza it is reasonably
easy to read, parse, process, and write virtually any type of stanza
formatted information.

=head1 EXAMPLES

The following is a somewhat contrived example, but it shows the
merging of two StanzaFiles.

    my $a = new StanzaFile("/etc/wvfile.conf") ;
    my $b = new StanzaFile("newWvfile.conf") ;

    foreach ($b->order())
    {
        if ($a->exists($_))
        {
            $a->stanza($_)->merge($b->stanza($_)) ;
        }
        else
        {
            $a->add($b->stanza($_)) ;
        } ;
    } ;

    $a->write(file_name=>"/etc/mergedWvdial.conf") ;

=head1 BUGS

None known.

=head1 WARNINGS

=head1 AUTHOR

Dick Munroe (munroe@csworks.com). 

I'm looking for work (contract or permanent).  I
do a lot more than just hack Perl.  Take a look at my:

Resume:	http://www.csworks.com/resume
Skills:	http://www.csworks.com/skills
CV:	http://www.csworks.com/cv

for the gory details.  If you see a match, drop me a note and we'll see what we
can work out.

=head1 SEE ALSO

=cut

