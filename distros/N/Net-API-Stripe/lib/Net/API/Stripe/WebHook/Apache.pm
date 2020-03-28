##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/WebHook/Apache.pm
## Version 0.1
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2019/11/02
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::WebHook::Apache;
BEGIN
{
	use strict;
	use parent qw( Net::API::REST );
	use Net::API::Stripe::Event;
	use TryCatch;
	use Devel::Confess;
	## use Apache2::Const -compile => qw( :common :http DECLINED );
	eval
	{
		require Apache2::Const;
		Apache2::Const->import( 'compile', qw( :common :http DECLINED ) );
	};
	die( $@ ) if( $@ );
    use constant MAX_PAYLOAD_SIZE => 524288;
};

sub handler
{
	## https://perl.apache.org/docs/2.0/user/handlers/http.html#HTTP_Request_Handler_Skeleton
	my( $class, $r ) = @_;
	$r->log_error( "Net::API::Stripe::WebHook::Apache(): Got here with Apache object '$r'." );
	return( DECLINED ) if( !$r );
    my $req = Net::API::REST::Request->new( $r );
	$r->log_error( "Got here after getting a Net::API::REST::Request object." );
    ## An error has occurred
    if( !defined( $req ) )
    {
    	return( 500 );
    }
	my $resp = Net::API::REST::Response->new( request => $req );
	my $self = $class->new;
	$self->request( $req );
	$self->response( $resp );
    my $sig = $self->request->headers( 'Stripe-Signature' );
	my $q = $self->request->params;
	my $payload = {};
	if( $self->request->content_type =~ /^application\/json/i )
	{
		$self->message( 3, "Receiving Stripe data as application/json" );
		if( $self->request->content_length > MAX_PAYLOAD_SIZE )
		{
			return( $self->reply( Apache2::Const::HTTP_REQUEST_ENTITY_TOO_LARGE, { message => sprintf( "Payload of %d bytes exceeds our limit", $self->request->content_length ) } ) );
		}
		my $buff = '';
		$self->request->read( $buff, $self->request->content_length );
		$self->message( 2, "Payload read from server is: '$buff'. Decoding it" );
		my $payload = $self->decode_json( $buff );
		if( !length( $payload ) )
		{
			return( $self->reply( Apache2::Const::HTTP_BAD_REQUEST, { message => "Malformed json error" }) );
		}
	}
	else
	{
		return( $self->reply( Apache2::Const::HTTP_BAD_REQUEST, { message => sprintf( "I was expecting http request type of application/json, but received %s", $self->request->content_type ) }) );
	}
	## Don't wait, reply ok back to Stripe so our request does not time out
	$self->response->code( Apache2::Const::HTTP_OK );
	my $json = $self->json->utf8->encode({ code => 200, success => \1 });
	$self->response->print( $json );
	$self->response->rflush;
	$self->request->socket->close;
	
	## Net::API::Stripe object
	my $stripe = $self->stripe || return( $self->error( "No Stripe object set up. You need to properly initiate a Net::API::Stripe object in your $class module." ) );
	
	my $stripe_event;
	try
	{
		$stripe_event = Net::API::Stripe::Event->new({
			'_parent' => $stripe,
			'_debug' => $stripe->{debug},
			'_dbh' => $stripe->{_dbh},
		}, $payload );
	}
	catch( $e )
	{
		return( $self->error( "Unable to initiate a Net::API::Stripe::Event object: $e" ) );
	}
	return( $self->pass_error( Net::API::Stripe::Event->error ) ) if( !defined( $stripe_event ) );
	my $stripe_handler = $self->event_handler( $stripe_event->type );
	return( $self->reply( Apache2::Const::HTTP_NOT_IMPLEMENTED, { message => "No function implemented to handle event of type \"", $stripe_event->type, "\"." }) );
	my $rc = $stripe_handler->( $stripe_event );
	if( !defined( $rc ) )
	{
		return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
	}
	elsif( $rc == 1 || $rc == Apache2::Const::HTTP_OK )
	{
		return( Apache2::Const::OK );
	}
	else
	{
		return( $rc );
	}
}

sub event_handler
{
	my $self = shift( @_ );
	## e.g. invoice.created or charge.refunded
	## See the list of all events here: https://stripe.com/docs/api/events/types
	my $type = shift( @_ );
	my $routes = $self->event_handlers || return( $self->error( "No event handlers map is set up. You need to set up a hash \"event_handlers\" pointing to each sub routine that handle Stripe events like { account => { updated => \&account_updated } }" ) );
	return( $self->error( "Event handlers set in this object is not an hash reference." ) ) if( ref( $routes ) ne 'HASH' );
	return( $self->error( "Event handlers hash found, but no event hadnlers set up. It's empty!" ) ) if( !scalar( keys( %$routes ) ) );
	my $parts = split( /\./, $type );
	local $check = sub
	{
		my( $pos, $subroutes ) = @_;
		my $part = $parts->[ $pos ];
		if( exists( $subroutes->{ lc( $part ) } ) )
		{
			$part = lc( $part );
			## Code reference
			if( ref( $subroutes->{ $part } ) eq 'CODE' )
			{
				return( $subroutes->{ $part } );
			}
			## path part has sub component, so we look for a key _handler in the sub hash
			elsif( ref( $subroutes->{ $part } ) eq 'HASH' )
			{
				my $ref = $subroutes->{ $part };
				return( $self->error( "I was expecting a code reference to handle this event \"$part\", but instead found a hash reference. It seems there is a misconfiguration." ) ) if( $pos == $#$parts );
				return( $check->( $pos + 1, $ref ) );
			}
			## Not a code or a hash reference, so it has got to be a package name
			elsif( $subroutes->{ $part } =~ /^([^\-]+)\-\>(\S+)$/ )
			{
				my( $cl, $meth ) = ( $1, $2 );
				try
				{
					## https://stackoverflow.com/questions/32608504/how-to-check-if-perl-module-is-available#comment53081298_32608860
					require $cl unless( defined( *{"${cl}::"} ) );
					my $o = $cl->new( request => $req, response => $resp ) || return( $self->pass_error( $cl->error ) );
					my $code = $o->can( $meth );
					return( $self->error({ code => 500, message => "Class \"$cl\" does not have a method \"$meth\"." }) ) if( !$code );
					return( sub{ $code->( $o, api => $self, @_ ) } );
				}
				catch( $e ) 
				{
					return( $self->error({ code => 500, message => $e }) );
				}
			}
			else
			{
				return( $self->error({ code => 500, message => "Found an entry for path part \"$part\" ($subroutes->{ $part }), but I do not know what to do with it. If this was supposed to be a package, the syntax needs to be My::Package->my_sub" }) );
			}
		}
		## Empty means not found
		else
		{
			return( $self->error( "No event handler found for \"$part\"." ) );
		}
	};
	my $sub = $check->( 0, $routes ) || return( undef() );
	return( $sub );
}

sub event_handlers { return( shift->_set_get_hash( 'event_handlers', @_ ) ); }

sub stripe { return( shift->_set_get_object( 'stripe', 'Net::API::Stripe', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::WebHook::Apache - An Apache handler for Stripe Web Hook

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

This is the module to handle Stripe Web Hooks using Apache/mod_perl configuration

=head1 CONFIGURATION

Your Apache VirtualHost configuration would look something like this:

    <VirtualHost *:443>
    	ServerName example.com:443
        ServerAdmin www@example.com
        DocumentRoot /home/john/example.com
        DirectoryIndex "index.html" "index.php"
        CustomLog "${APACHE_LOG_DIR}/example.com-access.log" combined
        ErrorLog "${APACHE_LOG_DIR}/example.com-error.log"
        LogLevel warn
        <Directory "/home/john/example.com">
            Options All +MultiViews -ExecCGI -Indexes +Includes +FollowSymLinks
            AllowOverride All
        </Directory>
        ScriptAlias "/cgi-bin/"     "/home/john/example.com/cgi-bin/"
        <Directory "/home/john/example.com/cgi-bin/">
            Options All +Includes +ExecCGI -Indexes -MultiViews
            AllowOverride All
            SetHandler cgi-script
            AcceptPathInfo On
	        Require all granted
        </Directory>
        <IfModule mod_perl.c>
			PerlOptions		+GlobalRequest
			PerlPassEnv		MOD_PERL
			PerlPassEnv		PATH_INFO
			PerlModule		Apache2::Request
			<Perl>
			unshift( @INC, "/home/john/lib" );
			</Perl>
			<Location /hook>
				SetHandler		perl-script
				## Switch it back to modperl once the soft is stable
				# SetHandler		modperl
				PerlSendHeader		On
				PerlSetupEnv		On
				PerlOptions			+GlobalRequest
				PerlResponseHandler	Net::API::Stripe::WebHook::Apache
				Options 			+ExecCGI
				Order allow,deny
				Allow from all
			</Location>
        </IfModule>

        SSLCertificateFile /etc/letsencrypt/live/example.com/cert.pem
        SSLCertificateKeyFile /etc/letsencrypt/live/example.com/privkey.pem
        Include /etc/letsencrypt/options-ssl-apache.conf
        SSLCertificateChainFile /etc/letsencrypt/live/example.com/chain.pem
    </Virtualhost>

The key part is the line with C<PerlResponseHandler> and value Net::API::Stripe::WebHook::Apache. This will tell Apache/mod_perl that our module will handle all http request for this particular location.

So, if we get an incoming event from Stripe at https://example.com/hook/d18bbab7-e537-4dba-9a1f-dd6cc70ea6c1, we receive C<d18bbab7-e537-4dba-9a1f-dd6cc70ea6c1> as part of the path info, and we call B<validate_webhook>() to validate it before processing the event incoming packet.

Apache will call our special method B<handler>(), which will invoque B<validate_webhook>() that should be overriden by your module, and which must return either true or false. Upon successful return from B<validate_webhook>(), B<handler> will create a new constructor such as $class->new()

What you want to do is inherit C<Net::API::Stripe::WebHook::Apache> and set your own module in Apache configuration, like so: 

    PerlResponseHandler My::WebHookHandler

The inherited handler will be called by Apache with the class My::WebHookHandler and the apache Apache2::RequestRec object. As we wrote above, once validated, B<handler> will initiate an object from your module by calling C<My::WebHookHandler->new( object => Net::API::Stripe::Event, request => Net::API::REST::Request, response => Net::API::REST::Response )> where each package name are an object. C<object> represents the event packet received from Stripe. C<request> is an object to access great number of method to access the Apache API, and C<response> is an object to access Apache API to provide a reply. See the manual page for each of those package.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %args )

Creates a new C<Net::API::Stripe::WebHook::Apache> objects. This should be overriden by your own package.

=over 4

=item I<object> Net::API::Stripe::Event object

=item I<request> Net::API::REST::Request

=item I<request> Net::API::REST::Response

=back

=item B<handler>( $class, $r )

This is called by Apache/mod_perl upon incoming http request

=over 8

=item I<verbose>

Toggles verbose mode on/off

=item I<debug>

Toggles debug mode on/off

=back

=head1 METHODS

=over 4

=item

=back

=head1 API SAMPLE

	{
	  "object": "balance",
	  "available": [
		{
		  "amount": 0,
		  "currency": "jpy",
		  "source_types": {
			"card": 0
		  }
		}
	  ],
	  "connect_reserved": [
		{
		  "amount": 0,
		  "currency": "jpy"
		}
	  ],
	  "livemode": false,
	  "pending": [
		{
		  "amount": 7712,
		  "currency": "jpy",
		  "source_types": {
			"card": 7712
		  }
		}
	  ]
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
