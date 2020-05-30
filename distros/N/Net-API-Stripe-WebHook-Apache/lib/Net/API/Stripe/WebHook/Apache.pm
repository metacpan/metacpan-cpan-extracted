##----------------------------------------------------------------------------
## A Stripe WebHook Implementation using Apache - ~/lib/Net/API/Stripe/WebHook/Apache.pm
## Version v0.100.2
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/28
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::WebHook::Apache;
BEGIN
{
    use strict;
    use parent qw( Net::API::REST );
    use Net::API::Stripe::Event;
    use Nice::Try;
    use Devel::Confess;
    ## use Apache2::Const -compile => qw( :common :http DECLINED );
    eval
    {
        require Apache2::Const;
        Apache2::Const->import( 'compile', qw( :common :http DECLINED ) );
    };
    die( $@ ) if( $@ );
    use constant MAX_PAYLOAD_SIZE => 524288;
    our $VERSION = 'v0.100.2';
};

sub handler
{
    ## https://perl.apache.org/docs/2.0/user/handlers/http.html#HTTP_Request_Handler_Skeleton
    my( $class, $r ) = @_;
    ## $r->log_error( "Net::API::Stripe::WebHook::Apache(): Got here with Apache object '$r'." );
    return( DECLINED ) if( !$r );
    my $req = Net::API::REST::Request->new( $r );
    ## $r->log_error( "Got here after getting a Net::API::REST::Request object." );
    ## An error has occurred
    if( !defined( $req ) )
    {
        return( 500 );
    }
    my $resp = Net::API::REST::Response->new( request => $req );
    my $self = $class->new;
    $self->request( $req );
    $self->response( $resp );
    ## Returning an hash reference with properties: payload, headers, remote_addr, remote_host
    my $q = $self->request->params;
    my $check_ref = $self->validate_webhook || 
    return( $self->reply({ code => $self->error->code, message => $self->error->message }) );
    return( $self->reply({ code => Apache2::Const::HTTP_INTERNAL_SERVER_ERROR, message => "I was expecting an hash reference from validate_webhook() but got \"$check_ref\" instead." }) ) if( !$self->_is_hash( $check_ref ) );
    ## This is the json decoded payload
    my $payload = $check_ref->{payload} || return( $self->reply({ code => Apache2::Const::HTTP_INTERNAL_SERVER_ERROR, message => "No payload property found in hash reference returned frm validate_webhook()" }) );
    return( $self->reply({ code => Apache2::Const::HTTP_INTERNAL_SERVER_ERROR, message => "I as expecting payload to be an hash reference, but instead got \"$payload\"" }) ) if( !$self->_is_hash( $payload ) );
    
    if( !scalar( keys( %$payload ) ) )
    {
        return( $self->reply({ code => Apache2::Const::HTTP_BAD_REQUEST, message => "Malformed json error" }) );
    }
    ## Don't wait, reply ok back to Stripe so our request does not time out
    $self->response->code( Apache2::Const::HTTP_OK );
    ## the \1 is for JSON encoder to transform a perl true value into a JSON 'true' one
    my $json = $self->json->utf8->encode({ code => 200, success => \1 });
    $self->response->print( $json );
    $self->response->rflush;
    $self->request->socket->close;
    
    ## Net::API::Stripe object
    my $stripe = $self->stripe || return( $self->reply({ code => Apache2::Const::HTTP_INTERNAL_SERVER_ERROR, message => "No Stripe object set up. You need to properly initiate a Net::API::Stripe object in your $class module." }) );
    
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
        return( $self->reply({ code => Apache2::Const::HTTP_INTERNAL_SERVER_ERROR, message => "Unable to initiate a Net::API::Stripe::Event object: $e" }) );
    }
    return( $self->reply({ code => Apache2::Const::HTTP_INTERNAL_SERVER_ERROR, message => Net::API::Stripe::Event->error }) ) if( !defined( $stripe_event ) );
    my $handlers = $self->event_handlers;
    my $stripe_handler;
    $stripe_handler = $self->event_handler( $stripe_event->type ) || do
    {
        if( CORE::exists( $handlers->{fallback} ) )
        {
            if( CORE::ref( $handlers->{fallback} ) eq 'CODE' )
            {
                $stripe_handler = $handlers->{fallback};
            }
            else
            {
                return( $self->reply({ code => Apache2::Const::HTTP_INTERNAL_SERVER_ERROR, message => "Fallback method provided is not a subroutine reference." }) );
            }
        }
        else
        {
            return( $self->reply({ code => Apache2::Const::HTTP_NOT_IMPLEMENTED, message => "No function implemented to handle event of type \"", $stripe_event->type, "\"." }) );
        }
    };
    
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
                    my $o = $cl->new( request => $self->request, response => $self->response ) || return( $self->pass_error( $cl->error ) );
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

sub ignore_ip { return( shift->_set_get_boolean( 'ignore_ip', @_ ) ); }

sub stripe { return( shift->_set_get_object( 'stripe', 'Net::API::Stripe', @_ ) ); }

sub validate_webhook
{
    my $self = shift( @_ );
    return( $self->error({ code => Apache2::Const::HTTP_INTERNAL_SERVER_ERROR, message => 'validate_webhook must be called with a class object' }) ) if( !ref( $self ) );
    my $class = ref( $self );
	my $signing_secret = $self->{signing_secret} || 
	return( $self->error({ code => Apache2::Const::HTTP_INTERNAL_SERVER_ERROR, message => "No signing secret key was specified to verify webhook incoming queries." }) );
	my $max_time_spread = ( 5 * 60 );
	my $remote_ip = $self->request->remote_ip;
	my $sig = $self->request->headers( 'Stripe-Signature' );
	return( $self->error({ code => Apache2::Const::HTTP_BAD_REQUEST, message => "No signature found" }) ) if( !CORE::length( $sig ) );
	
    if( $self->request->content_type =~ /^application\/json/i )
    {
        $self->message( 3, "Receiving Stripe data as application/json" );
        if( $self->request->content_length > MAX_PAYLOAD_SIZE )
        {
            return( $self->error({ code => Apache2::Const::HTTP_REQUEST_ENTITY_TOO_LARGE, message => sprintf( "Payload of %d bytes exceeds our limit", $self->request->content_length ) } ) );
        }
    }
    else
    {
        return( $self->error({ code => Apache2::Const::HTTP_BAD_REQUEST, message => sprintf( "I was expecting http request type of application/json, but received %s", $self->request->content_type ) }) );
    }
	
	my $payload = $self->request->data || return( $self->error({ code => Apache2::Const::HTTP_BAD_REQUEST, message => "No payload data received from the client." }) );
	
    my $stripe = $self->stripe || return( $self->error({ code => Apache2::Const::HTTP_INTERNAL_SERVER_ERROR, message => "No Stripe object set up. You need to properly initiate a Net::API::Stripe object in your $class module." }) );
	## Do an IP source check to be sure this is Stripe talking to us
	if( !defined( my $ip_check = $stripe->webhook_validate_caller_ip({ ip => $remote_ip, ignore_ip => $self->ignore_ip }) ) )
	{
		return( $self->error({ code => $stripe->error->code, message => $stripe->error->message }) );
	}
	## Now, we make sure this is Stripe sending this by checking the signature of the payload
	my $check = $stripe->webhook_validate_signature({
		secret => $signing_secret,
		signature => $sig,
		payload => $payload,
		time_tolerance => $max_time_spread,
	});
	if( !defined( $check ) )
	{
		return( $self->error({ code => Apache2::Const::HTTP_BAD_REQUEST, message => "Check failed: " . $stripe->error }) );
	}
	
	my $payload_ref = {};
    try
    {
        $payload_ref = $self->json->relaxed->decode( $payload );
    }
    catch( $e )
    {
        $self->message( 3, "Error decoding event json data. Error was: $e" );
        return( $self->error({ code => Apache2::Const::HTTP_BAD_REQUEST, message => "Malformed json error" }) );
    }
    
	my $headers = $self->request->headers_as_hashref;
	my $hash = 
	{
	payload => $payload_ref,
	headers => $headers,
	remote_addr => $remote_ip,
	remote_host => $self->request->remote_host,
	};
	return( $hash );
}

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::WebHook::Apache - An Apache handler for Stripe Web Hook

=head1 SYNOPSIS

    package My::Module::WebHook;
    BEGIN
    {
        use strict;
        use curry;
        use parent qw( Net::API::Stripe::WebHook::Apache );
    };
    
    sub init
    {
        my $self = shift( @_ );
        $self->{event_handlers} =
        {
        account => { updated => $self->curry::account_updated,
        # A fallback method for all other event types not purposely defined here
        fallback => $self->curry::fallback,
        # etc..
        # See here for a list of Stripe events:
        # https://stripe.com/docs/api/events/types
        };
        # See https://stripe.com/docs/webhooks#signatures
        # For example:
        $self->{signing_secret} = 'whsec_fake1234567890mnbvcxz';
        # Set up Net::API::Stripe object
        my $stripe = Net::API::Stripe->new( $hash_ref_of_params ) || 
            return( $self->error( "Unable to create a Net::API::Stripe object: ", Net::API::Stripe->error ) );
        # Set the Stripe object that is needed later in the handler and validate_webhook methods
        $self->stripe( $stripe );
        # Set this to true if you want to test your application and not check the webhook caller's IP, 
        # which should normally be Stripe's ip
        $self->{ignore_ip} = 0;
        return( $self );
    }

=head1 VERSION

    v0.100.2

=head1 DESCRIPTION

This is the module to handle Stripe Web Hooks using Apache/mod_perl configuration

The way this works is you create your own module which inherits from this one. You override the init method in which you create the object property I<event_handler> with an hash value with keys corresponding to the types of Stripe events. A dot in the Stripe event type corresponds to a sub hash in our I<event_handler> definition.

You can set up your endpoint on Stripe dashboard at: L<https://dashboard.stripe.com/webhooks> or do it via the api with L<Net::API::Stripe/"webhook">.

See also the list of all possible L<Stripe endpoints|https://stripe.com/docs/api/events/types>

For example:

    sub init
    {
        my $self = shift( @_ );
        $self->SUPER::init( @_ );
        $self->{event_handler} = 
        {
        account =>
            {
                updated => $self->curry::account_updated,
                application => 
                {
                    authorized => $self->curry:account_application_authorised,
                },
            },
        charge => 
            {
                captured => $self->curry::charge_captured,
                dispute =>
                {
                    created => $self->curry::charge_dispute_created,
                }
            },
        customer =>
            {
                created => $self->curry::customer_created,
            },
        # A fallback method for all other event types not purposely defined here
        fallback => $self->curry::fallback,
        ## And so on....
        };
    }

Nota bene: here in this example above, I use L<curry> which is a very handy module.

In a nutshell: when an http query is made by Stripe on your webhook, Apache will trigger the method B<handler>, which will check and create the object environment, and call the method B<event_handler> provided by this package to find out the sub in charge of this Stripe event type, as defined in your map I<event_handlers>. Your own method is then called and you can do whatever you want with Stripe data.

It is also worth mentioning that Stripe requires ssl to be enabled to perform webhook queries.

=head1 CONFIGURATION

Your Apache VirtualHost configuration would look something like this, assuming your module package is C<My::Module::WebHook>

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
            PerlOptions     +GlobalRequest
            PerlPassEnv     MOD_PERL
            PerlPassEnv     PATH_INFO
            PerlModule      Apache2::Request
            <Perl>
            unshift( @INC, "/home/john/lib" );
            </Perl>
            <Location /hook>
                SetHandler      perl-script
                ## Switch it back to modperl once the soft is stable
                # SetHandler        modperl
                PerlSendHeader      On
                PerlSetupEnv        On
                PerlOptions         +GlobalRequest
                # PerlResponseHandler   Net::API::Stripe::WebHook::Apache
                PerlResponseHandler My::Module::WebHook
                Options             +ExecCGI
                Order allow,deny
                Allow from all
            </Location>
        </IfModule>

        SSLCertificateFile /etc/letsencrypt/live/example.com/cert.pem
        SSLCertificateKeyFile /etc/letsencrypt/live/example.com/privkey.pem
        Include /etc/letsencrypt/options-ssl-apache.conf
        SSLCertificateChainFile /etc/letsencrypt/live/example.com/chain.pem
    </Virtualhost>

The key part is the line with C<PerlResponseHandler> and value L<Net::API::Stripe::WebHook::Apache>. This will tell Apache/mod_perl that our module will handle all http request for this particular location.

So, if we get an incoming event from Stripe at https://example.com/hook/d18bbab7-e537-4dba-9a1f-dd6cc70ea6c1, we receive C<d18bbab7-e537-4dba-9a1f-dd6cc70ea6c1> as part of the path info, and we call B<validate_webhook>() to validate it before processing the event incoming packet.

Apache will call our special method B<handler>(), which will invoque B<validate_webhook>() that should be implemented in your module if you want to do further checks, and which must return either a hash reference containing the payload or false. For example:

    sub validate_webhook
    {
        my $self = shift( @_ );
        # Receive the hash reference containing the properties: payload (hash ref), headers (hash ref), remote_addr and remote_host
        my $hash = $self->SUPER::validate_webhook || return;
        # Do further check and make sure to return an Exception object that has the code and message method
        # Example:
        my $payload = $hash->{payload};
        return( $self->error({ code => Apache2::Const::HTTP_BAD_REQUEST, "Something is off with the payload received" }) ) if( !$payload->{object} );
        # Make sure to return the hash reference
        return( $hash );
    }

Upon successful return from B<validate_webhook>(), B<handler> will create a new object from your class such as $class->new()

It will then call methods B<request> providing it with the L<Net::API::REST::Request> object and call the method B<response> providing it with the L<Net::API::REST::Response> object.

It will then collect the Stripe event data and create a L<Net::API::Stripe::Event> object with it.

It will then call L</"event_handler"> with the Stripe event type as the sole argument (See L<https://stripe.com/docs/api/events/types> for a list of all possible Stripe events), and will get in return either a code reference to the handler for this event type, or an empty string if no event handler was set for this event type or C<undef()> in scalar context or an empty list in list context if there was an error.

Finally it will call the referenced subroutine returned by L</"event_handler"> passing it the L<Net::API::Stripe::Event> object.

If your event handler returns undef, L<Net::API::Stripe::WebHook::Apache> will return a server error. If your event handler returns either 1 or C<Apache2::Const::HTTP_OK>, L<Net::API::Stripe::WebHook::Apache> will return an C<OK> code, and for anything else, L<Net::API::Stripe::WebHook::Apache> will return the code as returned by your handler.

This means you can use L<Apache2::Const> values as return code of your event handler.

=head1 CONSTRUCTOR

=head2 B<new>

Takes an hash or hash reference.

Creates a new L<Net::API::Stripe::WebHook::Apache> object. This should be overriden by your own package.

Here are the object properties recognised and used in this module:

=over 4

=item I<debug>

Integer. When set to a true value, this will produce debugging output on STDERR or http server log.

=item I<event_handlers>

An hash reference of event type to subroutine reference. See example above

=item I<ignore_ip>

When set to true, L<Net::API::Stripe/"webhook_validate_caller_ip"> will not check fo the validity of the webhook caller's ip.

=item I<signing_secret>

String. This is the secret key used by Stripe to sign the webhook payload and used by us to check the payload received is authentic. See your L<Stripe dashboard|https://dashboard.stripe.com/webhooks/>

=item I<stripe>

The L<Net::API::Stripe> object instantiated. This is used in L</"handler"> and L</"validate_webhook"> methods

=back

=head2 B<handler>

This is called by Apache/mod_perl upon incoming http request.

It takes your module class and the L<Apache2::Request> object as arguments

Your module class is the one defined in the Apache Virtual Hsot configuration with L<PerlResponseHandler|https://perl.apache.org/docs/2.0/user/handlers/http.html>

=head1 METHODS

=head2 handler

This is called by Apache with an L<Apache2::Request> object and returns an L<Apache2::Constant> code such as 200

=head2 event_handler

Provided with a Stripe event type such as C<customer.subscription.updated>, this checks for a suitable handler (set up in your B<init> method), then return the handler code reference.

=head2 event_handlers

Set/get an hash reference of Stripe event type to handling methods.

Returns an hash reference.

=head2 stripe

Set/get a L<Net::API::Stripe> object. It returns the current value.

=head2 validate_webhook

This checks the webhook call is valid and returns true upon success or false upon failure.

You want to override this like this:

    sub validate_webhook
    {
        my $self = shift( @_ );
        ## Get the basic checks done by our default validate_webhook method
        $self->SUPER::validate_webhook || return;
        # Add checks of your own
        # And if all is ok, return true, or false otherwise
        return( 1 );
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation: L<https://stripe.com/docs/api/events/types>

L<Net::API::REST>, L<Apache2>

L<ModPerl::Registry>, L<ModPerl::PerlRun>, L<http://perl.apache.org/>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
