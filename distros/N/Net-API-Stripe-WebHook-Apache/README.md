# NAME

Net::API::Stripe::WebHook::Apache - An Apache handler for Stripe Web Hook

# SYNOPSIS

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
        # etc..
        # See here for a list of Stripe events:
        # https://stripe.com/docs/api/events/types
        };
    }

# VERSION

    v0.100.1

# DESCRIPTION

This is the module to handle Stripe Web Hooks using Apache/mod\_perl configuration

The way this works is you create your own module which inherits from this one. You override the init method in which you create the object property _event\_handler_ with an hash value with keys corresponding to the types of Stripe events. A dot in the Stripe event type corresponds to a sub hash in our _event\_handler_ definition.

When an http query is made by Stripe on your webhook, Apache will trigger the method **handler**, which will check and create the object environment, and call the method **event\_handler** provided by this package to find out the sub in charge of this Stripe event type, as defined in your map _event\_handlers_. You own method is then called and you can do whatever you want with Stripe data.

It is also worth mentioning that Stripe requires ssl to be enabled to perform webhook queries.

# CONFIGURATION

Your Apache VirtualHost configuration would look something like this, assuming your module package is `My::Module::WebHook`

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
                        PerlOptions             +GlobalRequest
                        PerlPassEnv             MOD_PERL
                        PerlPassEnv             PATH_INFO
                        PerlModule              Apache2::Request
                        <Perl>
                        unshift( @INC, "/home/john/lib" );
                        </Perl>
                        <Location /hook>
                                SetHandler              perl-script
                                ## Switch it back to modperl once the soft is stable
                                # SetHandler            modperl
                                PerlSendHeader          On
                                PerlSetupEnv            On
                                PerlOptions                     +GlobalRequest
                                # PerlResponseHandler   Net::API::Stripe::WebHook::Apache
                                PerlResponseHandler My::Module::WebHook
                                Options                         +ExecCGI
                                Order allow,deny
                                Allow from all
                        </Location>
        </IfModule>

        SSLCertificateFile /etc/letsencrypt/live/example.com/cert.pem
        SSLCertificateKeyFile /etc/letsencrypt/live/example.com/privkey.pem
        Include /etc/letsencrypt/options-ssl-apache.conf
        SSLCertificateChainFile /etc/letsencrypt/live/example.com/chain.pem
    </Virtualhost>

The key part is the line with `PerlResponseHandler` and value [Net::API::Stripe::WebHook::Apache](https://metacpan.org/pod/Net%3A%3AAPI%3A%3AStripe%3A%3AWebHook%3A%3AApache). This will tell Apache/mod\_perl that our module will handle all http request for this particular location.

So, if we get an incoming event from Stripe at https://example.com/hook/d18bbab7-e537-4dba-9a1f-dd6cc70ea6c1, we receive `d18bbab7-e537-4dba-9a1f-dd6cc70ea6c1` as part of the path info, and we call **validate\_webhook**() to validate it before processing the event incoming packet.

Apache will call our special method **handler**(), which will invoque **validate\_webhook**() that should be overriden by your module, and which must return either true or false. Upon successful return from **validate\_webhook**(), **handler** will create a new constructor such as $class->new()

What you want to do is inherit [Net::API::Stripe::WebHook::Apache](https://metacpan.org/pod/Net%3A%3AAPI%3A%3AStripe%3A%3AWebHook%3A%3AApache) and set your own module in Apache configuration, like so: 

    PerlResponseHandler My::WebHookHandler

The inherited handler will be called by Apache with the class My::WebHookHandler and the apache Apache2::RequestRec object. As we wrote above, once validated, **handler** will initiate an object from your module by calling `My::WebHookHandler-`new( object => [Net::API::Stripe::Event](https://metacpan.org/pod/Net%3A%3AAPI%3A%3AStripe%3A%3AEvent), request => [Net::API::REST::Request](https://metacpan.org/pod/Net%3A%3AAPI%3A%3AREST%3A%3ARequest), response => [Net::API::REST::Response](https://metacpan.org/pod/Net%3A%3AAPI%3A%3AREST%3A%3AResponse) )> where each package name are an object. `object` represents the event packet received from Stripe. `request` is an object to access great number of method to access the Apache API, and `response` is an object to access Apache API to provide a reply. See the manual page for each of those package.

# CONSTRUCTOR

- **new**( %args )

    Creates a new [Net::API::Stripe::WebHook::Apache](https://metacpan.org/pod/Net%3A%3AAPI%3A%3AStripe%3A%3AWebHook%3A%3AApache) object. This should be overriden by your own package.

    - _object_ Net::API::Stripe::Event object
    - _request_ Net::API::REST::Request
    - _request_ Net::API::REST::Response

- **handler**( $class, $r )

    This is called by Apache/mod\_perl upon incoming http request

# METHODS

- handler( $r )

    This is called by Apache with an [Apache2::Request](https://metacpan.org/pod/Apache2%3A%3ARequest) object and returns an [Apache2::Constant](https://metacpan.org/pod/Apache2%3A%3AConstant) code such as 200

- **event\_handler**( Stripe event type )

    Provided with a Stripe event type, this checks for a suitable handler (set up in your **init** method), then return the handler code reference.

    ~item **event\_handlers**

    Set/get an hash reference of Stripe event type to handling methods.

    Returns an hash reference.

- **stripe**

    Set/get a [Net::API::Stripe](https://metacpan.org/pod/Net%3A%3AAPI%3A%3AStripe) object. It returns the current value.

# HISTORY

## v0.1

Initial version

# AUTHOR

Jacques Deguest <`jack@deguest.jp`>

# SEE ALSO

Stripe API documentation: [https://stripe.com/docs/api/events/types](https://stripe.com/docs/api/events/types)

[Net::API::REST](https://metacpan.org/pod/Net%3A%3AAPI%3A%3AREST), [Apache2](https://metacpan.org/pod/Apache2)

[ModPerl::Registry](https://metacpan.org/pod/ModPerl%3A%3ARegistry), [ModPerl::PerlRun](https://metacpan.org/pod/ModPerl%3A%3APerlRun), [http://perl.apache.org/](http://perl.apache.org/)

# COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.
