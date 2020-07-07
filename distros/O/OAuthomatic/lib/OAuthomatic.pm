# -*- coding: utf-8 -*-
package OAuthomatic;
# ABSTRACT: automate setup of access to OAuth-secured resources. Intended especially for use in console scripts, ad hoc applications etc.

# FIXME: option to hardcode client_cred


use Moose;
our $VERSION = '0.0202'; # VERSION
use namespace::sweep;
# FIXME: switch to Moo
use MooseX::AttributeShortcuts;
use Carp;
use Path::Tiny;
use Encode qw/encode decode/;
use Const::Fast 0.014;
use Try::Tiny;
use Scalar::Util qw/reftype/;

use OAuthomatic::Server;
use OAuthomatic::Config;
use OAuthomatic::Caller;
use OAuthomatic::SecretStorage;
use OAuthomatic::OAuthInteraction;
use OAuthomatic::UserInteraction;
use OAuthomatic::Internal::UsageGuard;
use OAuthomatic::Internal::Util qw/serialize_json parse_http_msg_json/;
use OAuthomatic::ServerDef qw/oauthomatic_predefined_for_name/;

###########################################################################
# Construction support, fixed attributes
###########################################################################

const my @_CONFIG_ATTRIBUTES => (
    'app_name', 'password_group', 'browser',
    'html_dir', 'debug',
   );


has 'config' => (
    is => 'ro', isa => 'OAuthomatic::Config', required => 1,
    handles => \@_CONFIG_ATTRIBUTES);


has 'server' => (
    is => 'ro', isa => 'OAuthomatic::Server', required => 1,
    handles => ['site_name']);


# Promoting params to config if necessary and remapping server
around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $objargs = $class->$orig(@_);
    unless(exists $objargs->{config}) {
        my @ctx_args;
        foreach my $attr (@_CONFIG_ATTRIBUTES) {
            if(exists $objargs->{$attr}) {
                push @ctx_args, ($attr => $objargs->{$attr});
                delete $objargs->{attr};
            }
        }
        $objargs->{config} = OAuthomatic::Config->new(@ctx_args);
    } else {
        foreach my $attr (@_CONFIG_ATTRIBUTES) {
            if(exists $objargs->{$attr}) {
                OAuthomatic::Error::Generic->throw(
                    ident => "Bad parameter",
                    extra => "You can not specify config and $attr at the same time");
            }
        }
    }

    if(exists($objargs->{server})) {
        my $server = $objargs->{server};
        unless( ref($server) ) {
            $objargs->{server} = oauthomatic_predefined_for_name($server);
        }
        elsif( reftype($server) eq 'HASH') {
            $objargs->{server} = OAuthomatic::Server->new(%{$objargs->{server}});
        }
    }

    return $objargs;
};

###########################################################################
# Pluggable behaviours
###########################################################################


has 'secret_storage' => (is => 'lazy', does => 'OAuthomatic::SecretStorage');

has 'oauth_interaction' => (is => 'lazy', does => 'OAuthomatic::OAuthInteraction');

has 'user_interaction' => (is => 'lazy', does => 'OAuthomatic::UserInteraction');

# Helper object used and shared by both default interactions
has '_micro_web' => (is => 'lazy');

sub _build_secret_storage {
    my ($self) = @_;
    require OAuthomatic::SecretStorage::Keyring;
    print "[OAuthomatic] Constructing default secret_storage\n" if $self->debug;
    return OAuthomatic::SecretStorage::Keyring->new(
        config => $self->config, server => $self->server);
}

sub _build_user_interaction {
    my ($self) = @_;
    require OAuthomatic::UserInteraction::ViaMicroWeb;
    print "[OAuthomatic] Constructing default user_interaction\n" if $self->debug;
    return OAuthomatic::UserInteraction::ViaMicroWeb->new(
        micro_web => $self->_micro_web);
}

sub _build_oauth_interaction {
    my ($self) = @_;
    require OAuthomatic::OAuthInteraction::ViaMicroWeb;
    print "[OAuthomatic] Constructing default oauth_interaction\n" if $self->debug;
    return OAuthomatic::OAuthInteraction::ViaMicroWeb->new(
        micro_web => $self->_micro_web);
}

sub _build__micro_web {
    my ($self) = @_;
    require OAuthomatic::Internal::MicroWeb;
    print "[OAuthomatic] Constructing MicroWeb object\n" if $self->debug;
    return OAuthomatic::Internal::MicroWeb->new(
        config => $self->config, server => $self->server);
}

###########################################################################
# Calling object and basic credentials management
###########################################################################


# This is communicating object. It may be in various states
# modelled by client_cred and token_cred (both set - it is authorized
# and ready for any use, only client_cred - it has defined app tokens
# but must be authorized, none set - it is useless)
has '_caller'  => (is => 'lazy', isa => 'OAuthomatic::Caller',
                   handles => [
                       'client_cred', 'token_cred',
                      ]);

sub _build__caller {
    my ($self) = @_;

    my $restored_client_cred = $self->secret_storage->get_client_cred();
    if($restored_client_cred) {
        print "[OAuthomatic] Loaded saved client (app) tokens. Key: ",
          $restored_client_cred->key, "\n" if $self->debug;
    }

    my $restored_token_cred = $self->secret_storage->get_token_cred();
    if($restored_token_cred) {
        print "[OAuthomatic] Loaded saved access tokens. Token: ",
          $restored_token_cred->token, "\n" if $self->debug;
    }

    my $caller = OAuthomatic::Caller->new(
        config => $self->config,
        server => $self->server,
        client_cred => $restored_client_cred,
        token_cred => $restored_token_cred);

    return $caller;
}

# Updates client_cred both in-memory and in storage
sub _update_client_cred {
    my ($self, $new_cred) = @_;
    return if OAuthomatic::Types::ClientCred->equal($new_cred, $self->client_cred);

    if($new_cred) {
        $self->secret_storage->save_client_cred($new_cred);
        print "[OAuthomatic] Saved client credentials for future. Key: ", $new_cred->key, "\n" if $self->debug;
    } else {
        $self->secret_storage->clear_client_cred;
        print "[OAuthomatic] Dropped saved client credentials\n" if $self->debug;
    }

    $self->client_cred($new_cred);

    # Changed client means access is no longer valid
    $self->_update_token_cred(undef);
    return;
}

# Updates token_cred both in-memory and in storage. $force param ignores identity check
# (to be used if we know we did incomplete update)
sub _update_token_cred {
    my ($self, $new_cred, $force) = @_;
    return if !$force && OAuthomatic::Types::TokenCred->equal($new_cred, $self->token_cred);

    if($new_cred) {
        $self->secret_storage->save_token_cred($new_cred);
        print "[OAuthomatic] Saved access credentials for future. Token: ", $new_cred->token, "\n" if $self->debug;
    } else {
        $self->secret_storage->clear_token_cred;
        print "[OAuthomatic] Dropped saved access credentials\n" if $self->debug;
    }

    $self->token_cred($new_cred);
    return;
}


sub erase_client_cred {
    my ($self) = @_;

    $self->_update_client_cred(undef);
    return;
}


sub erase_token_cred {
    my ($self) = @_;
    $self->_update_token_cred(undef);
    return;
}

###########################################################################
# Actual OAuth setup
###########################################################################

# Those are guards to keep track of supporting objects (mostly
# in-process web) activity (we may initiate supporting objects at
# various moments but close them after we know we are authorized)
has '_user_interaction_guard' => (
    is=>'lazy', builder => sub {
        return OAuthomatic::Internal::UsageGuard->new(obj => $_[0]->user_interaction);
    });
has '_oauth_interaction_guard' => (
    is=>'lazy', builder => sub {
        return OAuthomatic::Internal::UsageGuard->new(obj => $_[0]->oauth_interaction);
    });

# Ensures app tokens are known
sub _ensure_client_cred_known {
    my ($self) = @_;

    return if $self->_caller->client_cred;

    print "[OAuthomatic] Application tokens not available, prompting user\n" if $self->debug;

    $self->_user_interaction_guard->prepare;

    my $client_cred = $self->user_interaction->prompt_client_credentials()
      or OAuthomatic::Error::Generic->throw(
          ident => "Client credentials missing",
          extra => "Can't proceed without client credentials. Restart app and supply them.");

    # We save them straight away, in memory to use, in storage to keep them in case of crash
    # or Ctrl-C (later we will clear them if they turn out wrong).
    $self->_update_client_cred($client_cred);
    return;
}

# Ensures access tokens are known
sub _ensure_token_cred_known {
    my ($self) = @_;
    return if $self->_caller->token_cred;

    # To proceed we must have client credentials
    $self->_ensure_client_cred_known;

    my $site_name = $self->site_name;
    my $oauth_interaction = $self->oauth_interaction;
    my $user_interaction = $self->user_interaction;

    print "[OAuthomatic] Application is not authorized to $site_name, initiating access-granting sequence\n" if $self->debug;

    $self->_oauth_interaction_guard->prepare;
    $self->_user_interaction_guard->prepare;

    my $temporary_cred;
    # We loop to retry in case entered app tokens turn out wrong
    while(! $temporary_cred) {
        $self->_ensure_client_cred_known;   # Get new app keys if old were dropped
        print "[OAuthomatic] Constructing authorization url\n" if $self->debug;
        try {
            $temporary_cred = $self->_caller->create_authorization_url(
                $oauth_interaction->callback_url);
        } catch {
            my $error = $_;
            if($error->isa("OAuthomatic::Error::HTTPFailure")) {
                if($error->is_new_client_key_required) {
                    print STDERR $error, "\n";
                    print "\n\nReceived error suggests wrong client key.\nDropping it and retrying initialization.\n\n";
                    $self->erase_client_cred;
                } else {
                    $error->throw;
                }
            } elsif($error->isa("OAuthomatic::Error")) {
                $error->throw;
            } else {
                OAuthomatic::Error::Generic->throw(
                   ident => "Unknown error during authorization",
                   extra => $error);
            }
        };
    }

    print "[OAuthomatic] Leading user to authorization page\n" if $self->debug;
    $user_interaction->visit_oauth_authorize_page($temporary_cred->authorize_page);

    # Wait for post-auth redirect
    my $verifier_cred = $oauth_interaction->wait_for_oauth_grant;

    print "[OAuthomatic] Got authorization (verification for token: " . $verifier_cred->token . "), requesting access token\n" if $self->debug;

    my $token_cred  = $self->_caller->create_token_cred(
        $temporary_cred, $verifier_cred);

    print "[OAuthomatic] Got access token: " . $token_cred->token, "\n" if $self->debug;

    # Now save those values
    $self->_update_token_cred($token_cred, 'force');

    # Close supporting objects if they were started
    $self->_user_interaction_guard->finish;
    $self->_oauth_interaction_guard->finish;

    return;
}


sub ensure_authorized {
    my ($self) = @_;
    $self->_ensure_client_cred_known;
    $self->_ensure_token_cred_known;
    return;
}

######################################################################
# Making requests
######################################################################


sub execute_request {
    my ($self, @args) = @_;
    $self->ensure_authorized;
    my $reply;

    # Loop to retry on some failures
    while(1) {
        try {
            $reply = $self->_caller->execute_oauth_request(@args);
        } catch {
            my $error = $_;
            if($error->isa("OAuthomatic::Error::HTTPFailure")) {
                if($error->is_new_client_key_required) {
                    print STDERR $error, "\n";
                    print "\n\nReceived error suggests wrong client key.\nDropping it to enforce re-initialization.\n\n";
                    $self->erase_client_cred;
                    # Will redo loop
                } elsif($error->is_new_token_required) {
                    print STDERR $error, "\n";
                    print "\n\nReceived error suggests wrong token.\nDropping it to enforce re-initialization.\n\n";
                    $self->erase_token_cred;
                    # will redo loop
                } else {
                    $error->throw;
                }
            } elsif($error->isa("OAuthomatic::Error")) {
                $error->throw;
            } else {
                OAuthomatic::Error::Generic->throw(
                    ident => "Unknown error during execution",
                    extra => $error);
            }
        };
        last if $reply;
    };
    return $reply;
}


## no critic (RequireArgUnpacking)
sub build_request {
    my $self = shift;
    $self->ensure_authorized;
    return $self->_caller->build_oauth_request(@_);
}
## use critic


sub get {
    my ($self, $url, $url_args) = @_;
    my $r = $self->execute_request(
        method => "GET", url => $url, url_args => $url_args);
    return $r->decoded_content;
}


sub get_xml {
    my ($self, $url, $url_args) = @_;
    my $r = $self->execute_request(
        method => "GET", url => $url, url_args => $url_args,
        content_type => "application/xml; charset=utf-8");
    return $r->decoded_content;
}


sub get_json {
    my ($self, $url, $url_args) = @_;

    my $r = $self->execute_request(
        method => "GET", url => $url, url_args => $url_args);

    return parse_http_msg_json($r, 'force');  # FIXME: or error on content-type mismatch?
}


sub post {
    my $self = shift;
    my $url = shift;
    my @args = (method => "POST", url => $url);
    if(@_ > 1) {
        push @args, (url_args => shift);
    }
    my $body = shift;
    if(reftype($body) eq 'HASH') {
        push @args, (body_form => $body);
    } else {
        push @args, (body => $body);
    }

    my $r = $self->execute_request(@args);
    return $r->decoded_content;
}


sub post_xml {
    my $self = shift;
    my $url = shift;
    my @args = (method => "POST",
                url => $url,
                content_type => 'application/xml; charset=utf-8');
    if(@_ > 1) {
        push @args, (url_args => shift);
    }
    my $body = shift;
    push @args, (body => $body);

    my $r = $self->execute_request(@args);
    return $r->decoded_content;
}


sub post_json {
    my $self = shift;
    my $url = shift;
    my @args = (method => "POST", 
                url => $url, 
                content_type => 'application/json; charset=utf-8');
    if(@_ > 1) {
        push @args, (url_args => shift);
    }
    push @args, (body => serialize_json(shift));

    my $r = $self->execute_request(@args);

    return parse_http_msg_json($r);
}


sub put {
    my $self = shift;
    my $url = shift;
    my @args = (method => "PUT", url => $url);
    if(@_ > 1) {
        push @args, (url_args => shift);
    }
    my $body = shift;
    if(reftype($body) eq 'HASH') {
        push @args, (body_form => $body);
    } else {
        push @args, (body => $body);
    }

    my $r = $self->execute_request(@args);
    return $r->decoded_content;
}


sub put_xml {
    my $self = shift;
    my $url = shift;
    my @args = (method => "PUT", 
                url => $url,
                content_type => 'application/xml; charset=utf-8');
    if(@_ > 1) {
        push @args, (url_args => shift);
    }
    my $body = shift;
    push @args, (body => $body);

    my $r = $self->execute_request(@args);
    return $r->decoded_content;
}


sub put_json {
    my $self = shift;
    my $url = shift;
    my @args = (method => "PUT", 
                url => $url, 
                content_type => 'application/json; charset=utf-8');
    if(@_ > 1) {
        push @args, (url_args => shift);
    }
    push @args, (body => serialize_json(shift));

    my $r = $self->execute_request(@args);

    return parse_http_msg_json($r);
}


sub delete_ {
    my ($self, $url, $url_args) = @_;
    my $r = $self->execute_request(
        method => "DELETE", url => $url, url_args => $url_args);
    return $r->decoded_content;
}


# FIXME: base url prepended to urls not starting with http?

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OAuthomatic - automate setup of access to OAuth-secured resources. Intended especially for use in console scripts, ad hoc applications etc.

=head1 VERSION

version 0.0202

=head1 SYNOPSIS

Construct the object:

    my $oauthomatic = OAuthomatic->new(
         app_name => "News trend parser",
         password_group => "OAuth tokens (personal)",
         server => OAuthomatic::Server->new(
             # OAuth protocol URLs, formally used in the protocol
             oauth_temporary_url => 'https://some.site/api/oauth/request_token',
             oauth_authorize_page => 'https://some.site/api/oauth/authorize',
             oauth_token_url  => 'https://some.site/api/oauth/access_token',
             # Extra info about remote site, not required (but may make users happier)
             site_name => "SomeSite.com",
             site_client_creation_page => "https://some.site.com/settings/oauth_apps",
             site_client_creation_desc => "SomeSite applications page",
             site_client_creation_help =>
                 "Click Create App button and fill the form.\n"
                 . "Use AppToken as client key and AppSecret as client secret.\n"),
    );

and profit:

    my $info = $oauthomatic->get_json(
        'https://some.site.com/api/get_issues',
        { type => 'bug', page_len => 10, release => '7.3' });

On first run user (maybe just you) will be led through OAuth
initialization sequence, but the script need not care.

=head1 DESCRIPTION

B<WARNING:> I<This is early release. Things may change (although I won't
change crucial APIs without good reason).>

Main purpose of this module: make it easy to start scripting around
some OAuth-controlled site (at the moment, OAuth 1.0a is
supported). The user needs only to check site docs for appropriate
URLs, construct OAuthomatic object, and go.

I wrote this module as I always struggled with using OAuth-secured
APIs from perl. Modules I found on CPAN were mostly low-level,
not-too-well documented, and - worst of all - required my scripts to
handle whole „get keys, acquire permissions, save tokens” sequence.

OAuthomatic is very opinionated. It shows instructions in English. It
uses L<Passwd::Keyring::Auto> to save (and restore) sensitive data. It
assumes application keys are to be provided by the user on first run
(not distributed with the script). It spawns web browser (and
temporary in-process webserver to back it). It provides a few HTML
pages and they are black-on-white, 14pt font, without pictures.

Thanks to all those assumptions it usually just works, letting the
script author to think about job at hand instead of thinking about
authorization. And, once script grows to application, all those
opinionated parts can be tweaked or substituted where necessary.

=head1 PARAMETERS

=head2 server

Server-related parameters (in particular, all crucial URLs), usually
found in appropriate server developer docs.

There are three ways to specify this parameter

=over 4

=item *

by providing L<OAuthomatic::Server> object instance. For example:

    OAuthomatic->new(
        # ... other params
        server => OAuthomatic::Server->new(
            oauth_temporary_url => 'https://api.linkedin.com/uas/oauth/requestToken',
            oauth_authorize_page => 'https://api.linkedin.com/uas/oauth/authenticate',
            oauth_token_url  => 'https://api.linkedin.com/uas/oauth/accessToken',
            # ...
        ));

See L<OAuthomatic::Server> for detailed description of all parameters.

=item *

by providing hash reference of parameters. This is equivalent to
example above, but about 20 characters shorter:

    OAuthomatic->new(
        # ... other params
        server => {
            oauth_temporary_url => 'https://api.linkedin.com/uas/oauth/requestToken',
            oauth_authorize_page => 'https://api.linkedin.com/uas/oauth/authenticate',
            oauth_token_url  => 'https://api.linkedin.com/uas/oauth/accessToken',
            # ...
        });

=item *

by providing name of predefined server. As there exists L<OAuthomatic::ServerDef::LinkedIn> module:

    OAuthomatic->new(
        # ... other params
        server => 'LinkedIn',
    );

See L<OAuthomatic::ServerDef> for more details about predefined servers.

=back

=head2 app_name

Symbolic application name. Used in various prompts. Set to something
script users will recognize (script name, application window name etc).

Examples: C<build_publisher.pl>, C<XyZ sync scripts>.

=head2 password_group

Password group/folder used to distinguish saved tokens (a few
scripts/apps will share the same tokens if they refer to the same
password_group). Ignored if you provide your own L</secret_storage>.

Default value: C<OAuthomatic tokens> (remember to change if you have
scripts working on few different accounts of the same website).

=head2 browser

Command used to spawn the web browser.

Default value: best guess (using L<Browser::Open>).

Set to empty string to avoid spawning browser at all and show
instructions (I<Open web browser on https://....>) on the console
instead.

=head2 html_dir

Directory containing HTML templates and related resources for pages
generated by OAuthomatic (post-authorization page, application tokens
prompt and confirmation).

To modify their look and feel, copy C<oauthomatic_html> directory from
OAuthomatic distribution somewhere, edit to your taste and provide
resulting directory as C<html_dir>.

By default, files distributed with OAuthomatic are used.

=head2 debug

Make object print various info to STDERR. Useful while diagnosing
problems.

=head1 ADDITIONAL PARAMETERS

=head2 config

Object gathering all parameters except server. Usually constructed
under the hood, but may be useful if you need those params for sth else
(especially, if you customize object behaviour). For example:

    my $server = OAuthomatic::Server->new(...);
    my $config = OAuthomatic::Config->new(
        app_name => ...,
        password_group => ...,
        ... and the rest ...);
    my $oauthomatic = OAuthomatic->new(
        server => $server,
        config => $config,  # instead of normal params
        user_interaction => OAuthomatic::UserInteraction::ConsolePrompts->new(
            config => $config, server => $server));

=head2 secret_storage

Pluggable behaviour: modify the method used to persistently save and
restore various OAuth tokens. By default
L<OAuthomatic::SecretStorage::Keyring> (which uses
L<Passwd::Keyring::Auto> storage) is used, but any object implementing
L<OAuthomatic::SecretStorage> role can be substituted instead.

=head2 oauth_interaction

Pluggable behaviour: modify the way application uses to capture return
redirect after OAuth access is granted. By default temporary web
server is started on local address (it suffices to handle redirect to
localhost) and used to capture traffic, but any object implementing
L<OAuthomatic::OAuthInteraction> role can be substituted instead.

In case default is used, look and feel of the final page can be
modified using L</html_dir>.

=head2 user_interaction

Pluggable behaviour: modify the way application uses to prompt user
for application keys. By default form is shown in the browser, but any object
implementing L<OAuthomatic::UserInteraction> role can be substituted instead.

Note: you can use L<OAuthomatic::UserInteraction::ConsolePrompts>
to be prompted in the console.

In case default is used, look and feel of the pages can be
modified using L</html_dir>.

=head1 METHODS

=head2 erase_client_cred

    $oa->erase_client_cred();

Drops current client (app) credentials both from the object and, possibly, from storage.

Use if you detect error which prove they are wrong, or if you want to forget them for privacy/security reasons.

=head2 erase_token_cred

    $oa->erase_token_cred();

Drops access (app) credentials both from the object and, possibly, from storage.

Use if you detect error which prove they are wrong.

=head2 ensure_authorized

    $oa->ensure_authorized();

Ensure object is ready to make calls.

If initialization sequence happened in the past and appropriate tokens
are available, this method restores them.

If not, it performs all the work required to setup OAuth access to
given website: asks user for application keys (or loads them if
already known), leads the user through application authorization
sequence, preserve acquired tokens for future runs.

Having done all that, it leaves object ready to make OAuth-signed
calls (actual signatures are calculated using L<Net::OAuth>.

Calling this method is not necessary - it will be called automatically
before first request is executed, if not done earlier.

=head2 execute_request

    $oa->execute_request(
        method => $method, url => $url, url_args => $args,
        body => $body,
        content_type => $content_type)

    $oa->execute_request(
        method => $method, url => $url, url_args => $args,
        body_form => $body_form,
        content_type => $content_type)

Make OAuth-signed request to given url. Lowest level method, see below
for methods which add additional glue or require less typing.

Parameters:

=over 4

=item method

One of C<'GET'>, C<'POST'>, C<'PUT'>, C<'DELETE'>.

=item url

Actual URL to call (C<'http://some.site.com/api/...'>)

=item url_args (optional)

Additional arguments to escape and add to the URL. This is simply shortcut,
three calls below are equivalent:

    $c->execute_oauth_request(method => "GET",
        url => "http://some.where/api?x=1&y=2&z=a+b");

    $c->execute_oauth_request(method => "GET",
        url => "http://some.where/api",
        url_args => {x => 1, y => 2, z => 'a b'});

    $c->execute_oauth_request(method => "GET",
        url => "http://some.where/api?x=1",
        url_args => {y => 2, z => 'a b'});

=item body_form OR body

Exactly one of those must be specified for POST and PUT (none for GET or DELETE).

Specifying C<body_form> means, that we are creating www-urlencoded
form. Specified values will be rendered appropriately and whole message
will get proper content type. Example:

    $c->execute_oauth_request(method => "POST",
        url => "http://some.where/api",
        body_form => {par1 => 'abc', par2 => 'd f'});

Note that this is not just a shortcut for setting body to already
serialized form.  Case of urlencoded form is treated in a special way
by OAuth (those values impact OAuth signature). To avoid signature
verification errors, OAuthomatic will reject such attempts:

    # WRONG AND WILL FAIL. Use body_form if you post form.
    $c->execute_oauth_request(method => "POST",
        url => "http://some.where/api",
        body => 'par1=abc&par2=d+f',
        content_type => 'application/x-www-form-urlencoded');

Specifying C<body> means, that we post non-form body (for example
JSON, XML or even binary data). Example:

    $c->execute_oauth_request(method => "POST",
        url => "http://some.where/api",
        body => "<product><item-no>3434</item-no><price>334.22</price></product>",
        content_type => "application/xml; charset=utf-8");

Value of body can be either binary string (which will be posted as-is), or
perl unicode string (which will be encoded according to the content type, what by
default means utf-8).

Such content is not covered by OAuth signature, so less secure (at
least if it is posted over non-SSL connection).

For longer bodies, references are supported:

    $c->execute_oauth_request(method => "POST",
        url => "http://some.where/api",
        body => \$body_string,
        content_type => "application/xml; charset=utf-8");

=item content_type

Used to set content type of the request. If missing, it is set to
C<text/plain; charset=utf-8> if C<body> param is specified and to
C<application/x-www-form-urlencoded; charset=utf-8> if C<body_form>
param is specified.

Note that module author does not test behaviour on encodings different
than utf-8 (although they may work).

=back

Returns L<HTTP::Response> object.

Throws structural exception on HTTP (40x, 5xx) and technical (like
network) failures.

Example:

    my $result = $oauthomatic->make_request(
        method => "GET", url => "https://some.api/get/things",
        url_args => {name => "Thingy", count => 4});
    # $result is HTTP::Response object and we know request succeeded
    # on HTTP level

=head2 build_request

    $oa->build_request(method => $method, url => $url, url_args => $args,
                       body_form => $body_form, body => $body,
                       content_type => $content_type)

Build appropriate HTTP::Request, ready to be executed, with proper
headers and signature, but do not execute it. Useful if you prefer
to use your own HTTP client.

See L<OAuthomatic::Caller/build_oauth_request> for the meaning of
parameters.

Note: if you are executing requests yourself, consider detecting cases
of wrong client credentials, obsolete token credentials etc, and
calling or L</erase_client_cred> or L</erase_token_cred>. 
The L<OAuthomatic::Error::HTTPFailure> may be of help.

=head2 get

    my $reply = $ua->get($url, { url => 'args', ...);

Shortcut. Make OAuth-signed GET request, ensure request succeeded and
return it's body without parsing it (but decoding it from transport encoding).

=head2 get_xml

    my $reply = $ua->get($url, { url => 'args', ...);

Shortcut. Make OAuth-signed GET request, ensure request succeeded and
return it's body. Body is not parsed, it remains to be done in the outer program (there are
so many XML parsers I did not want to vote for one).

This is almost equivalent to L</get> (except it sets request content
type to C<application/xml>), mainly used to clearly signal intent.

=head2 get_json

    my $reply = $oa->get_json($url, {url=>args, ...});
    # $reply is hash or array ref

Shortcut. Make OAuth-signed GET request, ensure it succeeded, parse result as JSON,
return resulting structure.

Example:

    my $result = $oauthomatic->get_json(
        "https://some.api/things", {filter => "Thingy", count => 4});
    # Grabs https://some.api/things?filter=Thingy&count=4 and parses as JSON
    # $result is hash or array ref

=head2 post

    my $reply = $ua->post($url, { body=>args, ... });
    my $reply = $ua->post($url, { url=>args, ...}, { body=>args, ... });
    my $reply = $ua->post($url, "body content");
    my $reply = $ua->post($url, { url=>args, ...}, "body content");
    my $reply = $ua->post($url, $ref_to_body_content);
    my $reply = $ua->post($url, { url=>args, ...}, $ref_to_body_content);

Shortcut. Make OAuth-signed POST request, ensure request succeeded and
return reply body without parsing it.

May take two or three parameters. In two-parameter form it takes URL
to POST and body. In three-parameter, it takes URL, additional URL
params (to be added to URI), and body.

Body may be specified as:

=over 4

=item *

Hash reference, in which case contents of this hash are treated as
form fields, urlencoded and whole request is executed as urlencoded
POST.

=item *

Scalar or reference to scalar, in which case it is pasted verbatim as post body.

=back

Note: use use L</execute_request> for more control on parameters (in
particular, content type).

=head2 post_xml

    my $reply = $ua->post($url, "<xml>content</xml>");
    my $reply = $ua->post($url, { url=>args, ...}, "<xml>content</xml>");
    my $reply = $ua->post($url, $ref_to_xml_content);
    my $reply = $ua->post($url, { url=>args, ...}, $ref_to_xml_content);

Shortcut. Make OAuth-signed POST request, ensure request succeeded and
return reply body without parsing it.

May take two or three parameters. In two-parameter form it takes URL
to POST and body. In three-parameter, it takes URL, additional URL
params (to be added to URI), and body.

This is very close to L</post> (XML is neither rendered, nor parsed here),
used mostly to set proper content-type and to clearly signal intent in the code.

=head2 post_json

    my $reply = $oa->post_json($url, { json=>args, ... });
    my $reply = $oa->post_json($url, { url=>args, ...}, { json=>args, ... });
    my $reply = $oa->post_json($url, "json content");
    my $reply = $oa->post_json($url, { url=>args, ...}, "json content");
    # $reply is hash or arrayref constructed by parsing output

Make OAuth-signed POST request. Parameter is formatted as JSON, result
also i parsed as JSON.

May take two or three parameters. In two-parameter form it takes URL
and JSON body. In three-parameter, it takes URL, additional URL params
(to be added to URI), and JSON body.

JSON body may be specified as:

=over 4

=item *

Hash or array reference, in which case contents of this reference are serialized to JSON
and then used as request body.

=item *

Scalar or reference to scalar, in which case it is treated as already serialized JSON
and posted verbatim as post body.

=back

Example:

    my $result = $oauthomatic->post_json(
        "https://some.api/things/prettything", {
           mode => 'simple',
        }, {
            name => "Pretty Thingy",
            description => "This is very pretty",
            tags => ['secret', 'pretty', 'most-important'],
        }, count => 4);
    # Posts to https://some.api/things/prettything?mode=simple
    # the following body (formatting and ordering may be different):
    #     {
    #         "name": "Pretty Thingy",
    #         "description": "This is very pretty",
    #         "tags": ['secret', 'pretty', 'most-important'],
    #     }

=head2 put

    my $reply = $ua->put($url, { body=>args, ... });
    my $reply = $ua->put($url, { url=>args, ...}, { body=>args, ... });
    my $reply = $ua->put($url, "body content");
    my $reply = $ua->put($url, { url=>args, ...}, "body content");
    my $reply = $ua->put($url, $ref_to_body_content);
    my $reply = $ua->put($url, { url=>args, ...}, $ref_to_body_content);

Shortcut. Make OAuth-signed PUT request, ensure request succeeded and
return reply body without parsing it.

May take two or three parameters. In two-parameter form it takes URL
to PUT and body. In three-parameter, it takes URL, additional URL
params (to be added to URI), and body.

Body may be specified in the same way as in L</post>: as scalar, scalar
reference, or as hash reference which would be urlencoded.

=head2 put_xml

    my $reply = $ua->put($url, "<xml>content</xml>");
    my $reply = $ua->put($url, { url=>args, ...}, "<xml>content</xml>");
    my $reply = $ua->put($url, $ref_to_xml_content);
    my $reply = $ua->put($url, { url=>args, ...}, $ref_to_xml_content);

Shortcut. Make OAuth-signed PUT request, ensure request succeeded and
return reply body without parsing it.

May take two or three parameters. In two-parameter form it takes URL
to PUT and body. In three-parameter, it takes URL, additional URL
params (to be added to URI), and body.

This is very close to L</put> (XML is neither rendered, nor parsed here),
used mostly to set proper content-type and to clearly signal intent in the code.

=head2 put_json

    my $reply = $oa->put_json($url, { json=>args, ... });
    my $reply = $oa->put_json($url, { url=>args, ...}, { json=>args, ... });
    my $reply = $oa->put_json($url, "json content");
    my $reply = $oa->put_json($url, { url=>args, ...}, "json content");
    # $reply is hash or arrayref constructed by parsing output

Make OAuth-signed PUT request. Parameter is formatted as JSON, result
also i parsed as JSON.

May take two or three parameters. In two-parameter form it takes URL
and JSON body. In three-parameter, it takes URL, additional URL params
(to be added to URI), and JSON body.

JSON body may be specified just as in L</post_json>: as hash or array
reference (to be serialized) or as scalar or scalar reference
(treated as already serialized).

Example:

    my $result = $oauthomatic->put_json(
        "https://some.api/things/prettything", {
           mode => 'simple',
        }, {
            name => "Pretty Thingy",
            description => "This is very pretty",
            tags => ['secret', 'pretty', 'most-important'],
        }, count => 4);
    # PUTs to https://some.api/things/prettything?mode=simple
    # the following body (formatting and ordering may be different):
    #     {
    #         "name": "Pretty Thingy",
    #         "description": "This is very pretty",
    #         "tags": ['secret', 'pretty', 'most-important'],
    #     }

=head2 delete_

    $oa->delete_($url);
    $oa->delete_($url, {url => args, ...});

Shortcut. Executes C<DELETE> on given URL. Note trailing underscore in the name
(to avoid naming conflict with core perl function).

Returns reply body content, if any.

=head1 ATTRIBUTES

=head2 client_cred

OAuth application identifiers - client_key and client_secret.
As L<OAuthomatic::Types::ClientCred> object.

Mostly used internally but can be of use if you need (or prefer) to
use OAuthomatic only for initialization, but make actual calls using
some other means.

Note that you must call L</ensure_authorized> to bo be sure this object is set.

=head2 token_cred

OAuth application identifiers - access_token and access_token_secret.
As L<OAuthomatic::Types::TokenCred> object.

Mostly used internally but can be of use if you need (or prefer) to
use OAuthomatic only for initialization, but make actual calls using
some other means.

Note that you must call L</ensure_authorized> to bo be sure this object is set.

=head1 THANKS

Keith Grennan, for writing L<Net::OAuth>, which this module uses to
calculate and verify OAuth signatures.

Simon Wistow, for writing L<Net::OAuth::Simple>, which inspired some
parts of my module.

E. Hammer-Lahav for well written and understandable RFC 5849.

=head1 SOURCE REPOSITORY

Source code is maintained in L<Mercurial|http://www.mercurial-scm.org>
repository at L<helixteamhub.cloud/mekk/projects/perl/repositories/oauthomatic|https://helixteamhub.cloud/mekk/projects/perl/repositories/oauthomatic>

See C<README-development.pod> in source distribution for info how to
build module from source.

=head1 ISSUE TRACKER

Issues can be reported at:

=over

=item *

L<repository issue tracker|https://helixteamhub.cloud/mekk/projects/perl/issues>

=item *

L<CPAN bug tracker|https://rt.cpan.org/Dist/Display.html?Queue=OAuthomatic>

=back

The former is slightly preferred but feel free using CPAN tracker if you find it more usable.

=head1 AUTHOR

Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Marcin Kasperski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
