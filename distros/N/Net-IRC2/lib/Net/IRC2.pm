#
# Copyright 2005, Karl Y. Pradene <knotty@cpan.org> All rights reserved.
#

package Net::IRC2;

use strict;      use warnings   ;
use Exporter                    ;
use Carp                        ;

our @ISA       = qw( Exporter ) ;
our @EXPORT_OK = qw( new      ) ;
our @Export    = qw( new      ) ;

use vars qw( $VERSION $DEBUG )  ;
$VERSION =                       '0.27' ;
$DEBUG   =                            0 ;


sub new         { shift and return bless {@_} } ;

sub newconn     {
    use Net::IRC2::Connection;
    my $self = shift;
    return $self->connections( Net::IRC2::Connection->new( @_,
							   _parent => $self ) );
}

sub add_default_handler { $_[0]->add_handler( [ 'WaterGate' ], $_[1] )          }

sub add_handler         { map { $_->add_handler( @_ ) } @{ shift->connections } }

sub start       {
    use threads;
    # FIXME
    my @threads = map { threads->create( sub { $_->start() } ) } @{$_[0]->connections};
    map { $_->join } @threads ;
}

sub connections {
    my ( $self, $param ) = @_                           ;
    return $self->{'connections'} unless defined $param ;
    push @{$self->{'connections'}}, $param              ;
    return $param                                       ;
                                                        }
sub callback    {
    my ( $self, $param ) = @_                                  ;
    if ( ref $param eq 'CODE' ) {
	map { $_->callback( $param ) } @{ $self->connections } ;
	return 0                                               ;
    }
    return $_[0]->{'callback'}( $param ) if defined $param     ;
                                                               }

1; # End of Net::IRC2



=head1 NAME

Net::IRC2 - Client interface to the Internet Relay Chat protocol.

=head1 VERSION

 !!! UNDER PROGRAMMING !!!
 You can use and feedback is welcome ( in english or french )

=cut

#This is the documentation for the Version __.__.__ of Net::IRC2 , released _______________.

=pod

=head1 SYNOPSIS

 use Net::IRC2                                                        ;
 my $bot  = new Net::IRC2                                             ;
 my $conn = $bot->newconn( uri => 'irc://Nick!User@localhost:6667/' ) ; 
 $conn->mode( $conn->nick, '+B' )                                     ;
 $conn->mode(  '#Ailleurs +m'   )                                     ;
 $bot->add_default_handler( \&process_event )                         ;
 $bot->start                                                          ;
 ...

=head1 DESCRIPTION

This module will provide you an access to the IRC protocol suitable to write your own IRC-Bots, or your
IRC Client. The API will provide you the sames functions than Net::IRC, so change should be trivial.
This module C<use L<Parse::RecDescent>;> by Dr. Conway Damian.

=head1 FUNCTIONS

=over

=item new()

The constructor, takes no argument. Return a Net::IRC2 object. It's your IRC-Bot.

=item newconn()

Make a new connection. Like Net::IRC + can process a home-made tasty pseudo-URI :
irc://Nick!User@localhost:6667/ . Yummy.

=item start()

Start the bot

=item add_handler()

set handler for all messages matching a command in commands list.
 $bot->add_handler( [ '001'..'005' ], \&function ) ;

=item add_default_handler()

The simple way to handle all events with only one function.
set handler for ALL messages
 $bot->add_default_handler( \&function ) ;

=item connections()

return un ARRAY of Net::IRC2::Connection objects

=item irc_grammar()

! Internal !

=item callback()

! DEPRECATED !
 
=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-irc2@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-IRC2>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

Others Perl modules working with IRC connections: Net::IRC, POE::Component::IRC

IRC Request For Comment 1459 L<http://www.ietf.org/rfc/rfc1459.txt>

=head1 AUTHOR

Karl Y. Pradene, C<< <knotty@cpan.org>, irc://knotty@freenode.org/ >> 

=head1 COPYRIGHT & LICENSE

Copyright 2005, Karl Y. Pradene <knotty@cpan.org> All rights reserved.

This program is released under the following license: GNU General Public License, version 2

This program is free software; you can redistribute it and/or modify it under the terms
of the GNU General Public License version 2 as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program;
if not, write to the 

 Free Software Foundation,
 Inc., 51 Franklin St, Fifth Floor,
 Boston, MA  02110-1301 USA

See L<http://www.fsf.org/licensing/licenses/gpl.html>

=cut
