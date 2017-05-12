#
# Copyright 2005, Karl Y. Pradene <knotty@cpan.org> All rights reserved.
#

package Net::IRC2::Event        ;

use strict;      use warnings   ;
use Exporter                    ;

our @ISA       = qw( Exporter ) ;
our @EXPORT_OK = qw( new      ) ;
our @Export    = qw( new      ) ;

use vars qw( $VERSION )         ;
$VERSION =                       '0.27' ;

sub new        { shift and return bless { @_, 'timestamp'=>time }                    }

sub dump       {
    my $self = shift                                                                 ;
    print "------------\n"                                                           .
                                    ' Time     : ' . $self->time       . "\n"        .
                                    ' Orig     : ' . $self->orig                     .
          ( ( $self->prefix     ) ? ' Prefix   : ' . $self->prefix     . "\n" : '' ) .
                                    ' Command  : ' . $self->command    . "\n"        .
          ( ( $self->middle     ) ? ' Middle   : ' . $self->middle     . "\n" : '' ) . 
          ( ( $self->trailing   ) ? ' Trailing : ' . $self->trailing   . "\n" : '' ) .
          ( ( $self->servername ) ? ' Server   : ' . $self->servername . "\n" : '' ) . 
          ( ( $self->nick       ) ? ' Nick     : ' . $self->nick       . "\n" : '' ) . 
          ( ( $self->user       ) ? ' User     : ' . $self->user       . "\n" : '' ) . 
          ( ( $self->host       ) ? ' Host     : ' . $self->host       . "\n" : '' ) .
          ( ( $self->com_str    ) ? ' Com_str  : ' . $self->com_str    . "\n" : '' ) .
#          ( ( $self->to         ) ? ' To       : ' . $self->to         . "\n" : '' ) ; 
                                    ' To       : ' . $self->to         . "\n"        ; 
                                                                                     }
 ##########
# Accessor #
 ##########
sub time { $_[0]->{'timestamp'} }
sub orig { $_[0]->{'orig'}      }

{   my ( $code, $name ) = q{ sub { return $_[0]->{NAME} = $_[1] || $_[0]->{NAME} } }      ;
    no strict 'refs'                                                                      ;
    foreach $name qw( prefix from servername nick user host to command com_str userhost ) {
	$_ = $code ; s/NAME/$name/g ; *{$name} = eval                                   } }

sub middle     {
    $_[0]->{ 'middle'  } = $_[1] || $_[0]->{ 'middle' }                        ;
    return ( wantarray ) ? $_[0]->{ 'middle' }   : "@{$_[0]->{'middle'}}"      }
sub trailing   {
    $_[0]->{'trailing' } = $_[1] || $_[0]->{'trailing'}                        ;
    return ( wantarray ) ? $_[0]->{'trailing'} : "@{$_[0]->{'trailing'}}"      }


sub polish_up  {
    if ( $_[0]->command eq 'JOIN' ) {
	$_[0]->to( $_[0]->trailing ) ;    
    }else{
	$_[0]->to( $_[0]->middle ) ;    
    }
}

*parent = \&Net::IRC2::Connection::parent;

sub convert {
    my %hash = (
401 => 'NOSUCHNICK'      ,402 => 'NOSUCHSERVER',
403 => 'NOSUCHCHANNEL'   ,404 => 'CANNOTSENDTOCHAN',
405 => 'TOOMANYCHANNELS' ,406 => 'WASNOSUCHNICK',
407 => 'TOOMANYTARGETS'  ,409 => 'NOORIGIN',
411 => 'NORECIPIENT'     ,412 => 'NOTEXTTOSEND',
413 => 'NOTOPLEVEL'      ,414 => 'WILDTOPLEVEL',
421 => 'UNKNOWNCOMMAND'  ,422 => 'NOMOTD',
423 => 'NOADMININFO'     ,424 => 'FILEERROR',
431 => 'NONICKNAMEGIVEN' ,432 => 'ERRONEUSNICKNAME',
433 => 'NICKNAMEINUSE'   ,436 => 'NICKCOLLISION',
441 => 'USERNOTINCHANNEL',442 => 'NOTONCHANNEL',
443 => 'USERONCHANNEL'   ,444 => 'NOLOGIN',
445 => 'SUMMONDISABLED'  ,446 => 'USERSDISABLED',
451 => 'NOTREGISTERED'   ,461 => 'NEEDMOREPARAMS',
462 => 'ALREADYREGISTRED',463 => 'NOPERMFORHOST',
464 => 'PASSWDMISMATCH'  ,465 => 'YOUREBANNEDCREEP',
467 => 'KEYSET'          ,471 => 'CHANNELISFULL',
472 => 'UNKNOWNMODE'     ,473 => 'INVITEONLYCHAN',
474 => 'BANNEDFROMCHAN'  ,475 => 'BADCHANNELKEY',
481 => 'NOPRIVILEGES'    ,482 => 'CHANOPRIVSNEEDED',
483 => 'CANTKILLSERVER'  ,491 => 'NOOPERHOST',
501 => 'UMODEUNKNOWNFLAG',502 => 'USERSDONTMATCH',
300 => 'NONE'            ,302 => 'USERHOST',
303 => 'ISON'            ,301 => 'AWAY',
305 => 'UNAWAY'          ,306 => 'NOWAWAY',
311 => 'WHOISUSER'       ,312 => 'WHOISSERVER',
313 => 'WHOISOPERATOR'   ,317 => 'WHOISIDLE',
318 => 'ENDOFWHOIS'      ,319 => 'WHOISCHANNELS',
314 => 'WHOWASUSER'      ,369 => 'ENDOFWHOWAS',
321 => 'LISTSTART'       ,322 => 'LIST',
323 => 'LISTEND'         ,324 => 'CHANNELMODEIS',
331 => 'NOTOPIC'         ,332 => 'TOPIC',
341 => 'INVITING'        ,342 => 'SUMMONING',
351 => 'VERSION'         ,352 => 'WHOREPLY',
315 => 'ENDOFWHO'        ,353 => 'NAMREPLY',
366 => 'ENDOFNAMES'      ,364 => 'LINKS',
365 => 'ENDOFLINKS'      ,367 => 'BANLIST',
368 => 'ENDOFBANLIST'    ,371 => 'INFO',
374 => 'ENDOFINFO'       ,375 => 'MOTDSTART',
372 => 'MOTD'            ,376 => 'ENDOFMOTD',
381 => 'YOUREOPER'       ,382 => 'REHASHING',
391 => 'TIME'            ,392 => 'USERSSTART',
393 => 'USERS'           ,394 => 'ENDOFUSERS',
395 => 'NOUSERS'         ,200 => 'TRACELINK',
201 => 'TRACECONNECTING' ,202 => 'TRACEHANDSHAKE',
203 => 'TRACEUNKNOWN'    ,204 => 'TRACEOPERATOR',
205 => 'TRACEUSER'       ,206 => 'TRACESERVER',
208 => 'TRACENEWTYPE'    ,261 => 'TRACELOG',
211 => 'STATSLINKINFO'   ,212 => 'STATSCOMMANDS',
213 => 'STATSCLINE'      ,214 => 'STATSNLINE',
215 => 'STATSILINE'      ,216 => 'STATSKLINE',
218 => 'STATSYLINE'      ,219 => 'ENDOFSTATS',
241 => 'STATSLLINE'      ,242 => 'STATSUPTIME',
243 => 'STATSOLINE'      ,244 => 'STATSHLINE',
221 => 'UMODEIS'         ,251 => 'LUSERCLIENT',
252 => 'LUSEROP'         ,253 => 'LUSERUNKNOWN',
254 => 'LUSERCHANNELS'   ,255 => 'LUSERME',
256 => 'ADMINME'         ,257 => 'ADMINLOC1',
258 => 'ADMINLOC2'       ,259 => 'ADMINEMAIL',
209 => 'TRACECLASS'      ,217 => 'STATSQLINE',
231 => 'SERVICEINFO'     ,232 => 'ENDOFSERVICES',
233 => 'SERVICE'         ,234 => 'SERVLIST',
235 => 'SERVLISTEND'     ,316 => 'WHOISCHANOP',
361 => 'KILLDONE'        ,362 => 'CLOSING',
363 => 'CLOSEEND'        ,373 => 'INFOSTART',
384 => 'MYPORTIS'        ,466 => 'YOUWILLBEBANNED',
476 => 'BADCHANMASK'     ,492 => 'NOSERVICEHOST',
);
    foreach ( keys %hash ) {
	$hash{$hash{$_}} = $_;
    }
    return $hash{$_[0]} ;
}

1;

__END__

=head1 NAME

Net::IRC2::Event - A parsed IRC message.

=head1 FUNCTIONS

=over

=item parent()

return the Net::IRC2::Connection parent object

=item dump()

Print a nice formated dump of the Event

=item time()

A timestamp

=item orig()

The original IRC message

=item prefix()

Return the prefix field in IRC message

=item command()

Return the command field in IRC message

=item middle()

Return the midlle field in IRC message

=item trailing()

Return the Trailing field in IRC message

=item com_str()

Should return the command in ALPHA if exist

=item from()

=item servername()

=item nick()

Nickname of sender

=item user()

Username of sender

=item host()

Host of sender

=item userhost()

=item to()

The message destination, could be a chan, you nick ...

the Event's destination

=back

=head1 INTERNALS FUNCTIONS

=over

=item new()

=item convert()

=item polish_up()

=back

=head1 SEE ALSO

Net::IRC2, Net::IRC2::Connection

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
