package Protocol::XMPP::IQ::Roster;
$Protocol::XMPP::IQ::Roster::VERSION = '0.006';
use strict;
use warnings;
use parent qw(Protocol::XMPP::ElementBase);

=head1 NAME

=head1 SYNOPSIS

=head1 VERSION

Version 0.006

=head1 DESCRIPTION

Example from RFC3921:

 <iq from='juliet@example.com/balcony'
     id='bv1bs71f'
     type='get'>
  <query xmlns='jabber:iq:roster'/>
 </iq>

Response from server:

 <iq id='bv1bs71f'
     to='juliet@example.com/chamber'
     type='result'>
  <query xmlns='jabber:iq:roster' ver='ver7'>
    <item jid='nurse@example.com'/>
    <item jid='romeo@example.net'/>
  </query>
 </iq>

IQ start - stash current IQ on stream
Query start - set IQ query type to xmlns

Each item is parsed as a roster entry.

A roster request for a user that does not exist will return an error as follows:

 <iq id='bv1bs71f'
     to='juliet@example.com/chamber'
     type='error'>
  <error type='auth'>
    <item-not-found
        xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
  </error>
 </iq>

Updates:

An update request is as follows:

 <iq from='juliet@example.com/balcony'
     id='rs1'
     type='set'>
  <query xmlns='jabber:iq:roster'>
    <item jid='nurse@example.com'/>
  </query>
 </iq>

Pass C<subscription='remove'> as the item attribute to remove rather than adding the contact.

More detailed example:

   C: <iq from='juliet@example.com/balcony'
          id='ph1xaz53'
          type='set'>
        <query xmlns='jabber:iq:roster'>
          <item jid='nurse@example.com'
                name='Nurse'>
            <group>Servants</group>
          </item>
        </query>
      </iq>
Server push requests can be sent through as follows:

 <iq id='a78b4q6ha463'
     to='juliet@example.com/chamber'
     type='set'>
  <query xmlns='jabber:iq:roster'>
    <item jid='nurse@example.com'/>
  </query>
 </iq>

with the client reponse being an empty result:

 <iq from='juliet@example.com/balcony'
     id='a78b4q6ha463'
     type='result'/>

Until the client sends the initial roster request, it will not receive any server push information.

Subscribe by sending something like this:

   UC: <presence id='xk3h1v69'
                 to='juliet@example.com'
                 type='subscribe'/>
Requesting a new contact will cause the server to send out an ask request:

   US: <iq id='b89c5r7ib574'
           to='romeo@example.net/foo'
           type='set'>
         <query xmlns='jabber:iq:roster'>
           <item ask='subscribe'
                 jid='juliet@example.com'
                 subscription='none'/>
         </query>
       </iq>
=head1 METHODS

=cut

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2010-2014. Licensed under the same terms as Perl itself.
