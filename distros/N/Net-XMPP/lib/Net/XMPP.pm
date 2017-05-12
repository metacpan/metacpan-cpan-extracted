###############################################################################
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Library General Public
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Library General Public License for more details.
#
#  You should have received a copy of the GNU Library General Public
#  License along with this library; if not, write to the
#  Free Software Foundation, Inc., 59 Temple Place - Suite 330,
#  Boston, MA  02111-1307, USA.
#
#  Copyright (C) 1998-2004 Jabber Software Foundation http://jabber.org/
#
###############################################################################

package Net::XMPP;

=head1 NAME

Net::XMPP - XMPP Perl Library

=head1 SYNOPSIS

Net::XMPP provides a Perl user with access to the Extensible
Messaging and Presence Protocol (XMPP).

For more information about XMPP visit:

L<http://www.xmpp.org>

=head1 DESCRIPTION

Net::XMPP is a convenient tool to use for any perl script that would
like to utilize the XMPP Instant Messaging protocol.  While not a
client in and of itself, it provides all of the necessary back-end
functions to make a CGI client or command-line perl client feasible
and easy to use.  Net::XMPP is a wrapper around the rest of the
official Net::XMPP::xxxxxx packages.

There is are example scripts in the example directory that provide you
with examples of very simple XMPP programs.


NOTE: The parser that L<XML::Stream::Parser> provides, as are most Perl
parsers, is synchronous.  If you are in the middle of parsing a packet
and call a user defined callback, the Parser is blocked until your
callback finishes.  This means you cannot be operating on a packet,
send out another packet and wait for a response to that packet.  It
will never get to you.  Threading might solve this, but as of this
writing threading in Perl is not quite up to par yet.  This issue will
be revisted in the future.


=head1 EXAMPLES

  use Net::XMPP;
  my $client = Net::XMPP::Client->new();

=head1 METHODS

The Net::XMPP module does not define any methods that you will call
directly in your code.  Instead you will instantiate objects that call
functions from this module to do work.  The three main objects that
you will work with are the Message, Presence, and IQ modules. Each one
corresponds to the Jabber equivalent and allows you get and set all
parts of those packets.

There are a few functions that are the same across all of the objects:

=head2 Retrieval functions

=over 4

=item GetXML

Returns the XML string that represents the data contained
in the object.

  $xml  = $obj->GetXML();

=item GetChild

Returns an array of L<Net::XMPP::Stanza> objects
that represent all of the stanzas in the object
that are namespaced.  If you specify a namespace
then only stanza objects with that XMLNS are
returned.

  @xObj = $obj->GetChild();
  @xObj = $obj->GetChild("my:namespace");

=item GetTag

Return the root tag name of the packet.

=item GetTree

Return the L<XML::Stream::Node> object that contains the data.
See XML::Stream::Node for methods you can call on this
object.

=back

=head2 Creation functions

=over 4

=item NewChild

  NewChild(namespace)
  NewChild(namespace,tag)

Creates a new Net::XMPP::Stanza object with
the specified namespace and root tag of
whatever the namespace says its root tag
should be.  Optionally you may specify
another root tag if the default is not
desired, or the namespace requres you to set
one.

  $xObj = $obj->NewChild("my:namespace");
  $xObj = $obj->NewChild("my:namespace","foo");

ie. <foo xmlns='my:namespace'...></foo>

=item InsertRawXML

  InsertRawXML(string)

puts the specified string raw into the XML
packet that you call this on.

  $message->InsertRawXML("<foo></foo>")
    <message...>...<foo></foo></message>

  $x = $message->NewChild(..);
  $x->InsertRawXML("test");

  $query = $iq->GetChild(..);
  $query->InsertRawXML("test");

=item ClearRawXML

  ClearRawXML()

Removes the raw XML from the packet.

=back

=head2 Removal functions

=over 4

=item RemoveChild

  RemoveChild()
  RemoveChild(namespace)

Removes all of the namespaces child elements
from the object.  If a namespace is provided,
then only the children with that namespace are
removed.

=back

=head2 Test functions

=over 4

=item DefinedChild

  DefinedChild()
  DefinedChild(namespace)

Returns 1 if there are any known namespaced
stanzas in the packet, 0 otherwise.
Optionally you can specify a namespace and
determine if there are any stanzas with that
namespace.

  $test = $obj->DefinedChild();
  $test = $obj->DefinedChild("my:namespace");

=back

=head1 PACKAGES

For more information on each of these packages, please see the man page
for each one.

=head2 Net::XMPP::Client

This package contains the code needed to communicate with an XMPP
server: login, wait for messages, send messages, and logout.  It uses
XML::Stream to read the stream from the server and based on what kind
of tag it encounters it calls a function to handle the tag.

=head2 Net::XMPP::Protocol

A collection of high-level functions that Client uses to make their
lives easier.  These methods are inherited by the Client.

=head2 Net::XMPP::JID

The XMPP IDs consist of three parts: user id, server, and resource.
This module gives you access to those components without having to
parse the string yourself.

=head2 Net::XMPP::Message

Everything needed to create and read a <message/> received from the
server.

=head2 Net::XMPP::Presence

Everything needed to create and read a <presence/> received from the
server.

=head2 Net::XMPP::IQ

IQ is a wrapper around a number of modules that provide support for
the various Info/Query namespaces that XMPP recognizes.

=head2 Net::XMPP::Stanza

This module represents a namespaced stanza that is used to extend a
<message/>, <presence/>, and <iq/>.

The man page for Net::XMPP::Stanza contains a listing of all supported
namespaces, and the methods that are supported by the objects that
represent those namespaces.

=head2 Net::XMPP::Namespaces

XMPP allows for any stanza to be extended by any bit of XML.  This
module contains all of the internals for defining the XMPP based
extensions defined by the IETF.  The documentation for this module
explains more about how to add your own custom namespace and have it
be supported.

=head1 AUTHOR

Originally authored by Ryan Eatmon.

Previously maintained by Eric Hacker. 

Currently maintained by Darian Anthony Patrick.

=head1 BUGS

See unpatched issues at L<https://rt.cpan.org/Dist/Display.html?Queue=Net-XMPP>.

There is at least one issue with L<XML::Stream|XML::Stream> providing different
node structures depending on how the node is created. Net::XMPP 
should now be able to handle this, but who knows what else lurks.

=head1 COPYRIGHT

This module is free software, you can redistribute it and/or modify it
under the LGPL 2.1.

=cut

require 5.008;
use strict;
use warnings;
use Time::Local;
use POSIX;
use vars qw( $AUTOLOAD $VERSION $PARSING );

$VERSION = "1.05";

use XML::Stream;
use Net::XMPP::Debug;
use Net::XMPP::JID;
use Net::XMPP::Namespaces;
use Net::XMPP::Stanza;
use Net::XMPP::Message;
use Net::XMPP::IQ;
use Net::XMPP::Presence;
use Net::XMPP::Protocol;
use Net::XMPP::Client;


##############################################################################
#
# printData - debugging function to print out any data structure in an
#             organized manner.  Very useful for debugging XML::Parser::Tree
#             objects.  This is a private function that will only exist in
#             in the development version.
#
##############################################################################
sub printData
{
    print &sprintData(@_);
}


##############################################################################
#
# sprintData - debugging function to build a string out of any data structure
#              in an organized manner.  Very useful for debugging
#              XML::Parser::Tree objects and perl hashes of hashes.
#
#              This is a private function.
#
##############################################################################
sub sprintData
{
    return &XML::Stream::sprintData(@_);
}


##############################################################################
#
# GetTimeStamp - generic funcion for getting a timestamp.
#
##############################################################################
sub GetTimeStamp
{
    my($type,$time,$length) = @_;

    return "" if (($type ne "local") && ($type ne "utc") && !($type =~ /^(local|utc)delay(local|utc|time)$/));

    $length = "long" unless defined($length);

    my ($sec,$min,$hour,$mday,$mon,$year,$wday);
    if ($type =~ /utcdelay/)
    {
        ($year,$mon,$mday,$hour,$min,$sec) = ($time =~ /^(\d\d\d\d)(\d\d)(\d\d)T(\d\d)\:(\d\d)\:(\d\d)$/);
        $mon--;
        ($type) = ($type =~ /^utcdelay(.*)$/);
        $time = timegm($sec,$min,$hour,$mday,$mon,$year);
    }
    if ($type =~ /localdelay/)
    {
        ($year,$mon,$mday,$hour,$min,$sec) = ($time =~ /^(\d\d\d\d)(\d\d)(\d\d)T(\d\d)\:(\d\d)\:(\d\d)$/);
        $mon--;
        ($type) = ($type =~ /^localdelay(.*)$/);
        $time = timelocal($sec,$min,$hour,$mday,$mon,$year);
    }

    return $time if ($type eq "time");
    ($sec,$min,$hour,$mday,$mon,$year,$wday) =
        localtime(((defined($time) && ($time ne "")) ? $time : time)) if ($type eq "local");
    ($sec,$min,$hour,$mday,$mon,$year,$wday) =
        gmtime(((defined($time) && ($time ne "")) ? $time : time)) if ($type eq "utc");

    return sprintf("%d%02d%02dT%02d:%02d:%02d",($year + 1900),($mon+1),$mday,$hour,$min,$sec) if ($length eq "stamp");

    $wday = ('Sun','Mon','Tue','Wed','Thu','Fri','Sat')[$wday];

    my $month = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec')[$mon];
    $mon++;

    return sprintf("%3s %3s %02d, %d %02d:%02d:%02d",$wday,$month,$mday,($year + 1900),$hour,$min,$sec) if ($length eq "long");
    return sprintf("%3s %d/%02d/%02d %02d:%02d",$wday,($year + 1900),$mon,$mday,$hour,$min) if ($length eq "normal");
    return sprintf("%02d:%02d:%02d",$hour,$min,$sec) if ($length eq "short");
    return sprintf("%02d:%02d",$hour,$min) if ($length eq "shortest");
}


##############################################################################
#
# GetHumanTime - convert seconds, into a human readable time string.
#
##############################################################################
sub GetHumanTime
{
    my $seconds = shift;

    my $minutes = 0;
    my $hours = 0;
    my $days = 0;
    my $weeks = 0;

    while ($seconds >= 60) {
        $minutes++;
        if ($minutes == 60) {
            $hours++;
            if ($hours == 24) {
                $days++;
                if ($days == 7) {
                    $weeks++;
                    $days -= 7;
                }
                $hours -= 24;
            }
            $minutes -= 60;
        }
        $seconds -= 60;
    }

    my $humanTime;
    $humanTime .= "$weeks week " if ($weeks == 1);
    $humanTime .= "$weeks weeks " if ($weeks > 1);
    $humanTime .= "$days day " if ($days == 1);
    $humanTime .= "$days days " if ($days > 1);
    $humanTime .= "$hours hour " if ($hours == 1);
    $humanTime .= "$hours hours " if ($hours > 1);
    $humanTime .= "$minutes minute " if ($minutes == 1);
    $humanTime .= "$minutes minutes " if ($minutes > 1);
    $humanTime .= "$seconds second " if ($seconds == 1);
    $humanTime .= "$seconds seconds " if ($seconds > 1);

    $humanTime = "none" if ($humanTime eq "");

    return $humanTime;
}

1;
