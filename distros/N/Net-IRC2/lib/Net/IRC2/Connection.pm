#
# Copyright 2005, Karl Y. Pradene <knotty@cpan.org> All rights reserved.
#
#

package Net::IRC2::Connection   ;

use strict;      use warnings   ;
use Exporter                    ;
use IO::Socket::INET ()         ;
use Net::IRC2::Parser           ;

our @ISA       = qw( Exporter ) ;
our @EXPORT_OK = qw( new      ) ;
our @Export    = qw( new      ) ;

use vars qw( $VERSION $DEBUG )  ;
$VERSION    =                    '0.23' ;
$DEBUG      =                         0 ;


sub new {
    my $class = shift                                                          ;
    my $self = bless { @_ }                                                    ;

    $self->split_uri if exists $self->{'uri'}                                  ;
    my $sock = $self->socket( IO::Socket::INET->new( PeerAddr => $self->server ,
						     PeerPort => $self->port   ,
						     Proto    => 'tcp'         )
			    ) or ( warn "Can't bind : $@\n" and return undef ) ;
    $sock->send( 'PASS ' . $self->pass . "\n"                    .
                 'NICK ' . $self->nick . "\n"                    .
                 'USER ' . $self->user . ' foo.bar.quux '        .
		 $self->server . ' :' . $self->realname . "\n" ) ;
    $self->parser( new Net::IRC2::Parser )                       ;
    return $self                                                 }

sub start { 
    my $self = shift           ;
    1 while $self->do_one_loop }

sub do_one_loop {
    my $self = shift;
    my ( $sock, $parser ) = ( $self->socket, $self->parser );
    my $line = <$sock>;
    my $event = $parser->message( $line ) or warn "\nParse error\n$line|\n" and return 1 ;
    $self->pong( $event->trailing ) if $event->command eq 'PING'                    ;
    $event->polish_up;
    $event->{'_parent'} = $self                                                     ;
    $self->chans( scalar $event->trailing ) if $event->command eq 'JOIN'            ;
    if (      defined $self->{ 'callback' }{ $event->command } ) {
	           &{ $self->{ 'callback' }{ $event->command } } ( $self, $event )  ;
    } elsif ( defined $self->{ 'callback' }{   'WaterGate'   } ) {
	           &{ $self->{ 'callback' }{   'WaterGate'   } } ( $self, $event )  }
    no strict 'refs'                                                                ;
    &{'cb'.$event->command}($self, $event) if defined &{'cb'.$event->command}       ;
    return $event                                                                   }

sub split_uri {
    # http://www.w3.org/Addressing/draft-mirashi-url-irc-01.txt
    # http://www.mozilla.org/projects/rt-messaging/chatzilla/irc-urls.html
    # irc:[<connect-to>[(/<target>[<modifiers>][<query-string>]|<modifiers>)]]
    # http://www.gbiv.com/protocols/uri/rfc/rfc3986.html
    # irc://nick!user@server:port/
    my $self = shift                                                             ;
    if ( exists $self->{'uri'} ) {
	$self->{'uri'} =~ m|^irc://(.+?)!(.+?)@(.+?):(\d+)/|                     ;
	$self->nick($1); $self->user($2); $self->server($3); $self->port($4)     }
                                                                                 }
sub sl        {
    shift->socket->send(    "@_\n" )                                             }


 ##############
# Commands IRC #
 ##############

{   my ( $code, $name ) = q{ sub { shift->sl( 'COMMAND' . " @_" ) } } ;
    no strict 'refs'                                                ;
    foreach $name qw( mode privmsg notice part whois join pong ) {
	$_ = $code ; s/COMMAND/$name/ ; *{$name} = eval      } }

############
# Accessor #
############
sub nick     { return   $_[0]->{  'nick'  } = $_[1] || $_[0]->{  'nick'  }
	                                            || $ENV{'USER'}        || 'nonick'         }
sub pass     { return   $_[0]->{'password'} = $_[1] || $_[0]->{'password'} || '2 young 2 die'  }
sub port     { return   $_[0]->{  'port'  } = $_[1] || $_[0]->{  'port'  } || 6667             }
sub user     { return   $_[0]->{  'user'  } = $_[1] || $_[0]->{  'user'  } || 'void'           }
sub realname { return   $_[0]->{'realname'} = $_[1] || $_[0]->{'realname'} || 'use Net::IRC2'  }
sub server   { return   $_[0]->{ 'server' } = $_[1] || $_[0]->{ 'server' } || 'localhost'      }
sub socket   { return   $_[0]->{ 'socket' } = $_[1] || $_[0]->{ 'socket' }                     }
sub parser   { return   $_[0]->{ 'parser' } = $_[1] || $_[0]->{ 'parser' }                     }
sub grammar  { return   $_[0]->{'grammar' } = $_[1] || $_[0]->{'grammar' }                     }
sub callback { return   $_[0]->{'callback'} = $_[1]   if ref $_[1] eq 'CODE'                   ;
               return &{$_[0]->{'callback'}}( $_[1] ) if ref $_[1] eq 'Net::IRC2::Events'      }

sub parent   { return   $_[0]->{'_parent' }                                                    }
sub chans    { return push ( @{shift->{'chans'}}, shift )                                      }

sub last_sl  { return   $_[0]->{'last_sl' } = $_[1] || $_[0]->{'last_sl' }                     }

sub add_default_handler { $_[0]->add_handler( [ 'WaterGate' ], $_[1] ) }

sub add_handler { 
    my ( $self, $commands, $callback ) = @_                        ;
    $commands = [ $commands ] unless ref $commands eq 'ARRAY'      ;
    ( map { $self->{'callback'}{$_} = $callback } @$commands )     }

*add_global_handler = \&Net::IRC2::add_handler;

# sub dispatch { }

1;


__END__

=head1 NAME

Net::IRC2::Connection - One connection to an IRC server.

=head1 VERSION

!!! UNDER PROGRAMMING !!! Wait a moment, please hold the line ...

Documentation in progress ...

=head1 FUNCTIONS

=over

=item new()

Make a Connection object. You don't need to make a NET::IRC2 object if
you just want one connection. You should specify nick, server.

 Net::IRC2::Connection::new( nick=>'MyNick', server=>'host.domain.tld' )

=item add_handler()

Add a callback

 $conn->add_handler( 'PRIVMSG', \&callback )
 $conn->add_handler( [ 'PRIVMSG' , 'JOIN' ], \&callback )

=item add_default_handler()

=item start()

Start the client loop

=item do_one_loop()

Process only the next IRC message

=item nick()

Your Nickname

=item user()

=item pass()

The password

=item realname()

=item parent()

return the Net::IRC2 parent object

=item server()

The server like it was specified on creation

=item port()

=item socket()

Return the socket assigned to the connection

=item chans()

=back 

=head2 IRC Commands

=over

=item mode()

=item join()

Take one argument: a chan name
 $conn->join('#chan');

=item part()

Take one argument: a chan name
 $conn->part('#chan');

=item privmsg()

=item notice()

=item whois()

=item pong()

=back

=head1 INTERNALS FUNCTIONS

=over

=item split_uri()

=item grammar()

=item parser()

=item dispatch()

=item callback()

=item sl()

=item last_sl()

=back

=head1 SEE ALSO

Net::IRC2, Net::IRC2::Event

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

__END__

