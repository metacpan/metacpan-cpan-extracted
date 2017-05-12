package Net::XMPP::Client::GTalk ;

use 5.006                        ;
use strict                       ;
use warnings FATAL => 'all'      ;

use Carp                         ;

use Net::XMPP                    ;
use XML::Smart                   ;

=head1 NAME

Net::XMPP::Client::GTalk - This module provides an easy to use wrapper around the Net::XMPP class of modules for specific access to GTalk ( Both on Gmail and Google Apps ). 

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 GLOBAL VARIABLES

our $COMMUNICATION    ;

our $RECEIVE_CALLBACK ;

=cut

our $COMMUNICATION    ;
our $RECEIVE_CALLBACK ;

=head1 SYNOPSIS

This module provides an easy to use wrapper around the Net::XMPP class of modules for specific access to GTalk ( Both on Gmail and Google Apps ). 

Example:

This example connects to GTalk and waits for a chat message from someone. It replies to that person with the chat message that it received. 
Additionally it will dump online buddies at regular intervals along with the contents of the message it receives.

You can quit this program by sending it the chat message 'exit'.


    use Net::XMPP::Client::GTalk    ;
    use Data::Dump qw( dump )       ;

    my $username ; # = '' ; Set GTalk username here [ WITHOUT '@gmail.com' ]. 
    my $password ; # = '' ; Set GTalk password here.


    unless( defined( $username ) and defined( $password ) ) { 
	die( "SET YOUR GTALK USERNAME AND PASSWORD ABOVE!\n" ) ;
    }

    # See options for domain below in documentation for new.
    my $ob = new Net::XMPP::Client::GTalk( 
	USERNAME   =>  $username         ,
	PASSWORD   =>  $password         ,
	);


    my $require_run = 1 ;
    my $iteration   = 1 ;
    while( $require_run ) { 

	my $message = $ob->wait_for_message( 60 ) ;

	unless( $message ) { 
	    print "GOT NO MESSAGE - waiting longer\n" ;
	}

	if( $message->{ error } ) { 
	    print "ERROR \n" ;
	    next             ;
	} else { 
	    dump( $message ) ;
	}

	if( $message->{ message } eq 'exit' ) { 
	    print "Asked to exit by " . $message->{ from } . "\n" ;
	    $message->{ message } = 'Exiting ... ' ;
	    $require_run = 0 ;
	}

	$ob->send_message( $message->{ from }, $message->{ message } ) ;

	if( int( $iteration / 3 ) == ( $iteration / 3 ) ) { 
	    my @online_buddies = @{ $ob->get_online_buddies() } ;
	    dump( \@online_buddies ) ;
	}

	$iteration++ ;

    }


    exit() ;


=head1 USAGE NOTES

The NET::XMPP connection object is available through $object_of_Net_XMPP_Client_GTalk->{ RAW_CONNECTION } and can be used to call 
all functions of the NET::XMPP class of modules ( listed below ). 

It should be noted, however, that calling the SetCallBacks function on the NET::XMPP object will cause wait_for_message to fail. 
SetCallBacks can be called indirectly through new as follows: 

    my $ob = new Net::XMPP::Client::GTalk( 
	USERNAME     =>  $username         ,
	PASSWORD     =>  $password         ,
	DOMAIN       => 'gmail.com'        ,           # [ OPTIONAL ] [ DEFAULT gmail.com - set if other such as google apps domain ]
        SetCallBacks =>  { 
                 message     =>  \&function ,
                 presence    =>  \&function ,
                 iq          =>  \&function ,
                 send        =>  \&function ,
                 receive     =>  \&function ,
                 update      =>  \&function ,
          }                                ,
	RESOURCE     => 'My Chat Prog'     ,
    ) ;

Other than USERNAME and PASSWORD the other two parameters above are optional. 

The presence_send function does NOT update the chat status. This is because the corresponding NET::XMPP functions do not work. 

Additionally the following does NOT work and this module provides get_online_buddies as a work around. 

    my $roster = $NET_XMPP_Connection->Roster();
    my $user   = $roster->online( 'somebuddy@gmail.com' );

The value of resource can be changed as shown above. 

The connection to GTalk does not have to be explicitly disconnected as it is automatically done when this module object goes out of
scope or when the program terminates. It is a B<BAD> idea to do: $object_of_Net_XMPP_Client_GTalk->{ RAW_CONNECTION }->Disconnect();

Modules from which you can use functions include: 

    Net::XMPP             
    Net::XMPP::Client
    Net::XMPP::Connection
    Net::XMPP::Debug
    Net::XMPP::IQ
    Net::XMPP::JID
    Net::XMPP::Message
    Net::XMPP::Namespaces
    Net::XMPP::Presence
    Net::XMPP::PrivacyLists
    Net::XMPP::Protocol
    Net::XMPP::Roster
    Net::XMPP::Stanza


THREADS: This module is B<NOT thread safe>. To use it within a thread you need to require this module from within the thread. 

B<WARNING:> If the person you are sending a chat message to is not online then they will not receive an offline chat message, 
however, if they come online before the program terminates they will receive the chat. 

=head1 EXPORT

This is a purely object-oriented module and does not export anything. 

=head1 SUBROUTINES/METHODS

=head2 new                                                                   

  Usage:                                                                                      

    my $ob = new Net::XMPP::Client::GTalk( 
	USERNAME     =>  $username         ,
	PASSWORD     =>  $password         ,
	DOMAIN       => 'gmail.com'        ,           # [ OPTIONAL ] [ DEFAULT gmail.com - set if other such as google apps domain ]
        SetCallBacks =>  {                             # [ OPTIONAL ]
                 message     =>  \&function ,
                 presence    =>  \&function ,
                 iq          =>  \&function ,
                 send        =>  \&function ,
                 receive     =>  \&function ,
                 update      =>  \&function ,
          }                                ,
	RESOURCE     => 'My Chat Prog'     ,           # [ OPTIONAL ]
    ) ;

=cut

sub new {
    
    my $class = shift;
    
    my %parameter_hash;

    my $count = @_;

    my $useage_howto = "

Usage:

    my \$ob = new Net::XMPP::Client::GTalk( 
	USERNAME     =>  \$username         ,
	PASSWORD     =>  \$password         ,
	DOMAIN       => 'gmail.com'        ,           # [ OPTIONAL ] [ DEFAULT gmail.com - set if other such as google apps domain ]
        SetCallBacks =>  {                             # [ OPTIONAL ]
                 message     =>  \&function ,
                 presence    =>  \&function ,
                 iq          =>  \&function ,
                 send        =>  \&function ,
                 receive     =>  \&function ,
                 update      =>  \&function ,
          }                                ,
	RESOURCE     => 'My Chat Prog'     ,           # [ OPTIONAL ]
    ) ;

";

    %parameter_hash = @_ ;

    croak( $useage_howto )           unless( $parameter_hash{ USERNAME    }   ) ;
    croak( $useage_howto )           unless( $parameter_hash{ PASSWORD    }   ) ;

    $parameter_hash{ DEBUG     } = 0 unless( $parameter_hash{ DEBUG       }   ) ;

    $parameter_hash{ RESOURCE  } = 'Net::XMPP::Client::GTalk-V:' . $VERSION 
	unless( $parameter_hash{ RESOURCE } ) ;

    $parameter_hash{ DOMAIN    } = 'gmail.com' unless( $parameter_hash{ DOMAIN } ) ;

    my %call_backs ;
    if( defined( $parameter_hash{ SetCallBacks } ) ) { 

	$RECEIVE_CALLBACK = $parameter_hash{ receive } ;

	$call_backs{ receive } = \&_receive_callback  ;

	if( defined( $parameter_hash{ SetCallBacks }{ message } ) ) { 
	    $call_backs{ message  } = $parameter_hash{ SetCallBacks }{ message  } ;
	}

	if( defined( $parameter_hash{ SetCallBacks }{ send    } ) ) { 
	    $call_backs{ send     } = $parameter_hash{ SetCallBacks }{ send     } ;
	}

	if( defined( $parameter_hash{ SetCallBacks }{ iq      } ) ) { 
	    $call_backs{ iq       } = $parameter_hash{ SetCallBacks }{ iq       } ;
	}

	if( defined( $parameter_hash{ SetCallBacks }{ presence     } ) ) { 
	    $call_backs{ presence } = $parameter_hash{ SetCallBacks }{ presence } ;
	}

	if( defined( $parameter_hash{ SetCallBacks }{ update       } ) ) { 
	    $call_backs{ update   } = $parameter_hash{ SetCallBacks }{ update   } ;
	}
	
    } else { 
	$call_backs{ receive } = \&_receive_callback  ;
    }	


    my $username = $parameter_hash{ USERNAME } ;
    my $password = $parameter_hash{ PASSWORD } ;
    
    my $resource          = $parameter_hash{ RESOURCE }              ;
    my $componentname     = $parameter_hash{ DOMAIN   }              ;
    my $hostname          = 'talk.google.com'                        ;
    my $connectiontype    = 'tcpip'                                  ;
    my $port              = 5222                                     ;
    my $tls               = 1                                        ;


    my $connection = new Net::XMPP::Client()      ;
    my %params = ( 
	tls               => $tls                ,
	port              => $port               ,
	hostname          => $hostname           ,
	componentname     => $componentname      ,
	connectiontype    => $connectiontype     ,
	);

    my $res = _connect( 
	$connection                              ,
	$username                                ,
	$password                                ,
	$resource                                ,
	\%params                                 ,
	\%call_backs                             ,
	) ;


    my @online_buddies ;

    my $self = {

	RAW_CONNECTION      => $connection                   ,
	ONLINE_BUDDIES      => \@online_buddies              ,

	LAST_PRESENCE_SEND  => 0                             ,

	DEBUG               => $parameter_hash{ DEBUG     }  ,

	_USERNAME           => $username                     ,
	_PASSWORD           => $password                     ,
	_RESOURCE           => $resource                     ,
	_PARAMS             => \%params                      ,

	_CALLBACKS          => \%call_backs                  ,

    };
    
    ## Private and class data here. 

    bless( $self, $class );

    return $self;

}


=head2 send_message

This function sends a message to a contact. ( eg: $ob->send_message( $to, $message ) )

=cut 

sub send_message { 

    my $self    = shift ;
    my $to      = shift ;
    my $message = shift ;

    unless( UNIVERSAL::isa( $self, 'Net::XMPP::Client::GTalk' )  ) { 
	croak( 'Function needs to be called on the Net::XMPP::Client::GTalk object, please see documentation for details.' . "\n" ) ;
    }


    return 0 unless( $to )             ;

    $self->{ RAW_CONNECTION }->MessageSend(
	to         => $to                                   ,
	body       => $message                              ,
        resource   => $self->{ _RESOURCE }                  ,
        subject    => 'Message via ' . $self->{ _RESOURCE } ,
        type       => 'chat'                                ,

	# thread     =>"id"            ,
	);

    return 1;

}


=head2 wait_for_message

This function waits for a message for a maximum of 10 sec ( or for the duration set by parameter ), 
returns the parsed message in a hash if there is one or undef it there is none. 

The difference between this and wait_for_communication is that this will only return a chat message
recieved and not other communications such as pings. 

Pings recieved for presence of a buddy online are used to update the 'online_buddy' list ( see get_buddies below ). 

=cut

sub wait_for_message { 

    my $self        = shift ;
    my $wait_time   = shift ;

    my $start_time  = time  ;
    my $got_message         ; 

    unless( UNIVERSAL::isa( $self, 'Net::XMPP::Client::GTalk' )  ) { 
	croak( 'Function needs to be called on the Net::XMPP::Client::GTalk object, please see documentation for details.' . "\n" ) ;
    }

    while( $wait_time ) { 
	if( $self->wait_for_communication( $wait_time ) ) {
	    my $communication = $COMMUNICATION ;
	    $COMMUNICATION    = ''             ;
    
	    my $parsed_communication = $self->_parse_communication( $communication ) ;

	    if( $parsed_communication->{ message } ) { 
		return    $self->_process_message_communication(     $parsed_communication ) ;
	    } else { 
		my $val = $self->_process_non_message_communication( $parsed_communication ) ;

		if( defined( $val ) ) { 
		    if( defined( $got_message ) ) { 
			if( $got_message == 1 ) { 
			    $got_message = $got_message ;
			} else { 
			    $got_message = $val         ;
			} 
		    } else { 
			$got_message = $val ;
		    } 
		} else { 
		    $got_message = $got_message ;
		}


	    }

	}

	$wait_time = $wait_time - ( time() - $start_time ) ;
    }

    return $got_message ;

}

=head2 wait_for_communication 

This function waits for any kind of communication from GTalk for a maximum of 10 sec ( or for the duration set by parameter ), 
returns the raw xml of the message or undef if there is none. 

=cut

sub wait_for_communication { 

    my $self      = shift ;
    my $wait_time = shift ;

    unless( UNIVERSAL::isa( $self, 'Net::XMPP::Client::GTalk' )  ) { 
	croak( 'Function needs to be called on the Net::XMPP::Client::GTalk object, please see documentation for details.' . "\n" ) ;
    }

    $wait_time = defined( $wait_time ) ? $wait_time : 10 ;

    $self->presence_send()                                             ;
    my $got_message = $self->{ RAW_CONNECTION }->Process( $wait_time ) ; 
    $self->presence_send()                                             ;
    
    return $got_message ;

}

=head2 presence_send

This function sends out a presence based on the last presence send timestamp. The presence ping sent to GTalk will show 
the authenticated user as 'online'. 

It should be noted that wait_for_message, wait_for_communication and send_message all call this function and 
so calling it is explicitly not required unless those functions are not called for a significantly long time ( i.e. over 300 sec ). 

This function takes no parameters by default but if called with any non zero value [ ex: $object->presence_send( 1 ) ] 
it will force send a presence request regardless of when the last one was sent. 

=cut

sub presence_send { 

    my $self       = shift ;
    my $force_send = shift ;

    unless( UNIVERSAL::isa( $self, 'Net::XMPP::Client::GTalk' )  ) { 
	croak( 'Function needs to be called on the Net::XMPP::Client::GTalk object, please see documentation for details.' . "\n" ) ;
    }

    $force_send = 0 unless( $force_send ) ;
    
    if( ( ( time() - $self->{ LAST_PRESENCE_SEND } ) > 100 ) or $force_send )  { 
	$self->{ RAW_CONNECTION }->PresenceSend() ;
	$self->{ LAST_PRESENCE_SEND } = time()    ;
    }

    return 1 ;

}
	

=head2 get_buddies

This function gets a list of all chat contacts. The returned list is NOT a list of online buddies but that of all contacts. 

=cut

sub get_buddies {
    
    my $self = shift ;
    
    unless( UNIVERSAL::isa( $self, 'Net::XMPP::Client::GTalk' )  ) { 
	croak( 'Function needs to be called on the Net::XMPP::Client::GTalk object, please see documentation for details.' . "\n" ) ;
    }

    my @buddies = $self->{ RAW_CONNECTION }->RosterGet() ;

    my @clean_buddy_list ;
    foreach my $buddy ( @buddies ) { 
	next if( ref( $buddy ) eq 'HASH' ) ;
	push @clean_buddy_list, $buddy     ;
    }

    return \@clean_buddy_list ;

}

=head2 get_online_buddies

This function returns a list of buddies for which we have presence information. This function does not use the inbuilt functions
provided by NET::XMPP because, for some reason, they do not work. 

This means that the longer you wait the better this list. 

=cut

sub get_online_buddies { 

    my $self = shift ;

    unless( UNIVERSAL::isa( $self, 'Net::XMPP::Client::GTalk' )  ) { 
	croak( 'Function needs to be called on the Net::XMPP::Client::GTalk object, please see documentation for details.' . "\n" ) ;
    }

    return $self->{ ONLINE_BUDDIES } ;

}

=head1 INTERNAL SUBROUTINES/METHODS

These functions are used by the module. They are not meant to be called directly using the Net::XMPP::Client::GTalk object although 
there is nothing stoping you from doing that. 

=head2 _connect

This is an internal function and should not be used externally. 

Used to connect to GTalk.

=cut

sub _connect { 

    my $connection = shift ;
    my $username   = shift ;
    my $password   = shift ;
    my $resource   = shift ;
    my $params     = shift ;
    my $call_backs = shift ;

    my %params     = %{ $params     } ;
    my %call_backs = %{ $call_backs } ;

    $connection->SetCallBacks( %call_backs ) ;

    my $stat = $connection->Connect( %params ) or croak "Failed to connect to GTalk:$!\n" ;

    my @res = $connection->AuthSend(  
	username => $username,
	password => $password,
	resource => $resource 
	) or croak "Failed to Authenticate :$!\n" ;

    return \@res ;

}


=head2 _receive_callback

This is an internal function and is not to be used externally.

This function is used to receive the contents of a message from GTalk. 

=cut

sub _receive_callback { 

    my $id      = shift ;
    my $message = shift ;

    $COMMUNICATION = $message ;

    if( defined( $RECEIVE_CALLBACK ) ) { 
	$RECEIVE_CALLBACK->( $id, $message ) ;
    }

    return 1;

}


=head2 _parse_communication

This is an internal function and is not to be used externally. 

This function parses the XML recieved from GTalk. 

=cut

sub _parse_communication { 

    my $self          = shift ;
    my $communication = shift ;

    unless( UNIVERSAL::isa( $self, 'Net::XMPP::Client::GTalk' )  ) { 
	croak( 'Function needs to be called on the Net::XMPP::Client::GTalk object, please see documentation for details.' . "\n" ) ;
    }

    return XML::Smart->new( $communication )->tree() ;

}


=head2 _process_message_communication

This is an internal function and is not to be called externally. 

It parses the message XML to return a hash while also updating the online buddy list. 

=cut

sub _process_message_communication { 

    my $self    = shift ;
    my $message = shift ;

    unless( UNIVERSAL::isa( $self, 'Net::XMPP::Client::GTalk' )  ) { 
	croak( 'Function needs to be called on the Net::XMPP::Client::GTalk object, please see documentation for details.' . "\n" ) ;
    }

    my $from_expression = $message->{ message }{ from } ;
    if( $message->{ message }{ error } ) { 
	$message->{ error } = 1 ;
	return $message         ;
    }

    my ( $success, $from, $client ) = $self->_parse_from_expression( $from_expression ) ;
    unless( $success ) { 
	croak( "Unable to find message source!\n" ) ;
    }

    my $message_text = $message->{ message }{ body }{ CONTENT } ;
    my $id           = $message->{ message }{ id   }            ;
    my $type         = $message->{ message }{ type }            ;


    my %presence = ( 
	from        => $from        ,
	# photo       => $photo       , # -- Do not have this info here. 
	# status      => $status      , # -- Do not have this info here. 
	from_client => $client      ,
	);
	
    $self->_process_presence( \%presence ) ;

    my %message = ( 
	id      => $id           ,
	type    => $type         ,
	from    => $from         , 
	message => $message_text ,
	);

    return \%message ;

}

=head2 _process_non_message_communication 

This is an internal function and is not to be used externally. 

It processes non-chat messages from GTalk. 

=cut

sub _process_non_message_communication { 

    my $self          = shift ;
    my $communication = shift ;

    unless( UNIVERSAL::isa( $self, 'Net::XMPP::Client::GTalk' )  ) { 
	croak( 'Function needs to be called on the Net::XMPP::Client::GTalk object, please see documentation for details.' . "\n" ) ;
    }
    
    if( $communication->{ presence } ) { 
	my $from_expression = $communication->{ presence }{ from } ;

	my ( $success, $from, $from_client ) = $self->_parse_from_expression( $from_expression ) ;
	unless( $success ) { 
	    carp( "WARNING ( Mostly Harmless ): Unable to process presence\n" ) ;
	    return 0                                                            ;
	} 

	my $status = $communication->{ presence }{ status }{ CONTENT }     ;
	my $photo  ; 

	my $photo_location = $communication->{ presence }{ x } ;
	if( $photo_location ) { 
	    if( ref $photo_location eq 'ARRAY' ) { 
		foreach my $loc ( @{ $photo_location } ) { 
		    if( $loc->{ photo } ) { 
			$photo = $loc->{ photo }{ CONTENT } 
		    }
		}
	    } else { 
		if( $photo_location->{ photo } ) { 
		    $photo = $photo_location->{ photo }{ CONTENT } 
		}
	    }		
	}
	
	my %presence = ( 
	    from        => $from        ,
	    photo       => $photo       ,
	    status      => $status      ,
	    from_client => $from_client ,
	    );

	$self->_process_presence( \%presence ) ;

	return 1 ;

    }

    if( $self->{ DEBUG } ) { 
	carp( "VERBOSE WARNING: Unknown Communication type\n" ) ;
    }

    return 0 ;
}

=head2 _parse_from_expression 

This is an internal function and should not be used externally. 

It breaks the from field of a communication down into from and client. 

=cut 

sub _parse_from_expression { 

    my $self            = shift ;
    my $from_expression = shift ;

    unless( UNIVERSAL::isa( $self, 'Net::XMPP::Client::GTalk' )  ) { 
	croak( 'Function needs to be called on the Net::XMPP::Client::GTalk object, please see documentation for details.' . "\n" ) ;
    }

    my $from    ;
    my $client  ;
    if( $from_expression =~ /^([^\/]*)\/(.*)$/ ) { 
	$from        = $1 ;
	$client      = $2 ;
    } else { 
	return 0          ;                                                  ;
    }

    return ( 1, $from, $client ) ;

}

=head2 _process_presence

This is an internal function and is not to be used externally. 

This function adds a buddy to the online buddy list and removes buddies based on a timeout of 700 sec ( i.e. If there has been no 
presence from a particular buddy for over 700 sec )

=cut

sub _process_presence { 

    my $self     = shift ;
    my $presence = shift ;

    unless( UNIVERSAL::isa( $self, 'Net::XMPP::Client::GTalk' )  ) { 
	croak( 'Function needs to be called on the Net::XMPP::Client::GTalk object, please see documentation for details.' . "\n" ) ;
    }

    my @online_buddies = @{ $self->{ ONLINE_BUDDIES } } ;

    my $this_presence_processed = 0 ;
    my @now_online_buddies          ;
    foreach my $buddy ( @online_buddies ) {
	if( time() - $buddy->{ presence_time } < 700 ) { 
	    if( $buddy->{ from } eq $presence->{ from } ) { 
		$buddy->{ presence_time } = time() ;
		$this_presence_processed  = 1      ;
	    }
	    push @now_online_buddies, $buddy ;
	}
    }

    unless( $this_presence_processed ) { 
	$presence->{ presence_time } = time() ;
	push @now_online_buddies, $presence   ;
    }

    $self->{ ONLINE_BUDDIES } = \@now_online_buddies ;

    return 1 ;

}

     
=head2 DESTROY

Global Destructor. 

This function closes the connection to Gtalk if Disconnect has not already been called.

=cut

sub DESTROY {

    my $self = shift;
    
    $self->{ RAW_CONNECTION }->Disconnect() ;

    return 1 ;

}

=head1 AUTHOR

Harish Madabushi, C<< <harish.tmh at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-xmpp-client-gtalk at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-XMPP-Client-GTalk>.  
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::XMPP::Client::GTalk

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-XMPP-Client-GTalk>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-XMPP-Client-GTalk>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-XMPP-Client-GTalk>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-XMPP-Client-GTalk/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Harish Madabushi.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

# TO ADD: 

#     change     my $componentname     = 'gmail.com'   to see if it works for apps. 

1; # End of Net::XMPP::Client::GTalk
