#############################################################################
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
##############################################################################

package Net::XMPP::Presence;

=head1 NAME

Net::XMPP::Presence - XMPP Presence Module

=head1 SYNOPSIS

Net::XMPP::Presence is a companion to the Net::XMPP module.
It provides the user a simple interface to set and retrieve all
parts of an XMPP Presence.

=head1 DESCRIPTION

A Net::XMPP::Presence object is passed to the callback function for
the message.  Also, the first argument to the callback functions is
the session ID from XML::Streams.  There are some cases where you
might want this information, like if you created a Client that
connects to two servers at once, or for writing a mini server.

    use Net::XMPP;

    sub presence {
      my ($sid,$Pres) = @_;
      .
      .
      .
    }

You now have access to all of the retrieval functions available.

To create a new presence to send to the server:

    use Net::XMPP;

    $Pres = Net::XMPP::Presence->new();

Now you can call the creation functions below to populate the tag
before sending it.

=head1 METHODS

=head2 Retrieval functions

=over 4

=item GetTo

  GetTo()

returns the value in the to='' attribute for the <presence/>.  

  GetTo("jid")


If you specify "jid" as an argument
then a Net::XMPP::JID object is returned and
you can easily parse the parts of the JID.

  $to    = $Pres->GetTo();
  $toJID = $Pres->GetTo("jid");

=item GetFrom

  GetFrom()

returns the value in the from='' attribute for the <presence/>.

  GetFrom("jid")

If you specify "jid" as an argument
then a Net::XMPP::JID object is returned and
you can easily parse the parts of the JID.

  $from    = $Pres->GetFrom();
  $fromJID = $Pres->GetFrom("jid");

=item GetType

  GetType()

returns the type='' attribute of the <presence/>.  Each
presence is one of seven types:

  available       available to receive messages; default
  unavailable     unavailable to receive anything
  subscribe       ask the recipient to subscribe you
  subscribed      tell the sender they are subscribed
  unsubscribe     ask the recipient to unsubscribe you
  unsubscribed    tell the sender they are unsubscribed
  probe           probe

  $type = $Pres->GetType();

=item GetStatus

  GetStatus()

returns a string with the current status of the resource.

  $status = $Pres->GetStatus();

=item GetPriority

  GetPriority()

returns an integer with the priority of the resource
The default is 0 if there is no priority in this
presence.

  $priority = $Pres->GetPriority();

=item GetShow

  GetShow()

Returns a string with the state the client should show.

  $show = $Pres->GetShow();

=back

=head2 Creation functions

=over 4

=item SetPresence

  SetPresence(to=>string|JID    
              from=>string|JID, 
              type=>string,     
              status=>string,   
              priority=>integer,
              meta=>string,     
              icon=>string,     
              show=>string,     
              loc=>string)      

set multiple fields in the <presence/>
at one time.  This is a cumulative
and over writing action.  If you set
the "to" attribute twice, the second
setting is what is used.  If you set
the status, and then set the priority
then both will be in the <presence/>
tag.  For valid settings read the
specific Set functions below.

  $Pres->SetPresence(TYPE=>"away", StatuS=>"Out for lunch");

=item SetTo

  SetTo(string)
  SetTo(JID)

sets the to attribute.  You can either pass a string
or a JID object.  They must be valid JIDs or the
server will return an error message.
(ie.  bob@jabber.org/Silent Bob, etc...)

  $Pres->SetTo("bob\@jabber.org");

=item SetFrom

  SetFrom(string)

sets the from='' attribute.  You can either pass

  SetFrom(JID)

A string or a JID object.  They must be valid JIDs
or the server will return an error message. (ie.
jabber:bob@jabber.org/Work)  This field is not
required if you are writing a Client since the
server will put the JID of your connection in there
to prevent spamming.

  $Pres->SetFrom("jojo\@jabber.org");

=item SetType

  SetType(string)

sets the type attribute.  Valid settings are:

  available      available to receive messages; default
  unavailable    unavailable to receive anything
  subscribe      ask the recipient to subscribe you
  subscribed     tell the sender they are subscribed
  unsubscribe    ask the recipient to unsubscribe you
  unsubscribed   tell the sender they are unsubscribed
  probe          probe

  $Pres->SetType("unavailable");

=item SetStatus

  SetStatus(string)

sets the status tag to be whatever string the user
wants associated with that resource.

  $Pres->SetStatus("Taking a nap");

=item SetPriority

  SetPriority(integer)

sets the priority of this resource.  The highest
resource attached to the xmpp account is the
one that receives the messages.

  $Pres->SetPriority(10);

=item SetShow

  SetShow(string)

Sets the name of the icon or string to display for this resource.

  $Pres->SetShow("away");

=item Reply

  Reply(hash)

creates a new Presence object and populates the to/from
fields.  If you specify a hash the same as with
SetPresence then those values will override the Reply
values.

  $Reply = $Pres->Reply();
  $Reply = $Pres->Reply(type=>"subscribed");

=back

=head2 Removal functions

=over 4

=item RemoveTo

removes the to attribute from the <presence/>.

  $Pres->RemoveTo();

=item RemoveFrom

removes the from attribute from the <presence/>.

 $Pres->RemoveFrom();

=item RemoveType

removes the type attribute from the <presence/>.

 $Pres->RemoveType();

=item RemoveStatus

removes the <status/> element from the <presence/>.

 $Pres->RemoveStatus();

=item RemovePriority

removes the <priority/> element from the <presence/>.

 $Pres->RemovePriority();

=item RemoveShow

removes the <show/> element from the <presence/>.

  $Pres->RemoveShow();

=back

=head2 Test functions

=over 4

=item  DefinedTo

returns 1 if the to attribute is defined in the <presence/>, 0 otherwise.

  $test = $Pres->DefinedTo();

=item DefinedFrom

returns 1 if the from attribute is defined in the <presence/>, 0 otherwise.

 $test = $Pres->DefinedFrom();

=item DefinedType

returns 1 if the type attribute is defined in the <presence/>, 0 otherwise.

  $test = $Pres->DefinedType();

=item DefinedStatus

returns 1 if <status/> is defined in the <presence/>, 0 otherwise.

  $test = $Pres->DefinedStatus();

=item DefinedPriority

returns 1 if <priority/> is defined in the <presence/>, 0 otherwise.

  $test = $Pres->DefinedPriority();

=item DefinedShow

returns 1 if <show/> is defined in the <presence/>, 0 otherwise.

  $test = $Pres->DefinedShow();

=back

=head1 AUTHOR

Originally authored by Ryan Eatmon.

Previously maintained by Eric Hacker. 

Currently maintained by Darian Anthony Patrick.

=head1 COPYRIGHT

This module is free software, you can redistribute it and/or modify it
under the LGPL 2.1.

=cut

require 5.008;
use strict;
use warnings;

use Carp;
use vars qw( %FUNCTIONS );
use Net::XMPP::Stanza;
use base qw( Net::XMPP::Stanza );

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = { };

    bless($self, $proto);

    $self->{DEBUGHEADER} = "Presence";
    $self->{TAG} = "presence";

    $self->{FUNCS} = \%FUNCTIONS;

    $self->_init(@_);

    return $self;
}

sub _presence { return Net::XMPP::Presence->new(); }


$FUNCTIONS{Error}->{path} = 'error/text()';

$FUNCTIONS{ErrorCode}->{path} = 'error/@code';

$FUNCTIONS{From}->{type} = 'jid';
$FUNCTIONS{From}->{path} = '@from';

$FUNCTIONS{ID}->{path} = '@id';

$FUNCTIONS{Priority}->{path} = 'priority/text()';

$FUNCTIONS{Show}->{path} = 'show/text()';

$FUNCTIONS{Status}->{path} = 'status/text()';

$FUNCTIONS{To}->{type} = 'jid';
$FUNCTIONS{To}->{path} = '@to';

$FUNCTIONS{Type}->{path} = '@type';

$FUNCTIONS{XMLNS}->{path} = '@xmlns';

$FUNCTIONS{Presence}->{type}  = 'master';

$FUNCTIONS{Child}->{type}  = 'child';
$FUNCTIONS{Child}->{path}  = '*[@xmlns]';
$FUNCTIONS{Child}->{child} = {};

##############################################################################
#
# Reply - returns a Net::XMPP::Presence object with the proper fields
#         already populated for you.
#
##############################################################################
sub Reply
{
    my $self = shift;
    my %args;
    while($#_ >= 0) { $args{ lc pop(@_) } = pop(@_); }

    my $reply = $self->_presence();

    $reply->SetID($self->GetID()) if ($self->GetID() ne "");

    $reply->SetPresence((($self->GetFrom() ne "") ?
                         (to=>$self->GetFrom()) :
                         ()
                        ),
                        (($self->GetTo() ne "") ?
                         (from=>$self->GetTo()) :
                         ()
                        ),
                       );

    $reply->SetPresence(%args);

    return $reply;
}


1;
