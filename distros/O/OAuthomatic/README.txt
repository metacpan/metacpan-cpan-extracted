NAME

    OAuthomatic - automate setup of access to OAuth-secured resources.
    Intended especially for use in console scripts, ad hoc applications
    etc.

VERSION

    version 0.0201

SYNOPSIS

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

DESCRIPTION

    WARNING: This is early release. Things may change (although I won't
    change crucial APIs without good reason).

    Main purpose of this module: make it easy to start scripting around
    some OAuth-controlled site (at the moment, OAuth 1.0a is supported).
    The user needs only to check site docs for appropriate URLs, construct
    OAuthomatic object, and go.

    I wrote this module as I always struggled with using OAuth-secured APIs
    from perl. Modules I found on CPAN were mostly low-level, not-too-well
    documented, and - worst of all - required my scripts to handle whole
    „get keys, acquire permissions, save tokens” sequence.

    OAuthomatic is very opinionated. It shows instructions in English. It
    uses Passwd::Keyring::Auto to save (and restore) sensitive data. It
    assumes application keys are to be provided by the user on first run
    (not distributed with the script). It spawns web browser (and temporary
    in-process webserver to back it). It provides a few HTML pages and they
    are black-on-white, 14pt font, without pictures.

    Thanks to all those assumptions it usually just works, letting the
    script author to think about job at hand instead of thinking about
    authorization. And, once script grows to application, all those
    opinionated parts can be tweaked or substituted where necessary.

PARAMETERS

 server

    Server-related parameters (in particular, all crucial URLs), usually
    found in appropriate server developer docs.

    There are three ways to specify this parameter

      * by providing OAuthomatic::Server object instance. For example:

          OAuthomatic->new(
              # ... other params
              server => OAuthomatic::Server->new(
                  oauth_temporary_url => 'https://api.linkedin.com/uas/oauth/requestToken',
                  oauth_authorize_page => 'https://api.linkedin.com/uas/oauth/authenticate',
                  oauth_token_url  => 'https://api.linkedin.com/uas/oauth/accessToken',
                  # ...
              ));

      See OAuthomatic::Server for detailed description of all parameters.

      * by providing hash reference of parameters. This is equivalent to
      example above, but about 20 characters shorter:

          OAuthomatic->new(
              # ... other params
              server => {
                  oauth_temporary_url => 'https://api.linkedin.com/uas/oauth/requestToken',
                  oauth_authorize_page => 'https://api.linkedin.com/uas/oauth/authenticate',
                  oauth_token_url  => 'https://api.linkedin.com/uas/oauth/accessToken',
                  # ...
              });

      * by providing name of predefined server. As there exists
      OAuthomatic::ServerDef::LinkedIn module:

          OAuthomatic->new(
              # ... other params
              server => 'LinkedIn',
          );

      See OAuthomatic::ServerDef for more details about predefined servers.

 app_name

    Symbolic application name. Used in various prompts. Set to something
    script users will recognize (script name, application window name etc).

    Examples: build_publisher.pl, XyZ sync scripts.

 password_group

    Password group/folder used to distinguish saved tokens (a few
    scripts/apps will share the same tokens if they refer to the same
    password_group). Ignored if you provide your own "secret_storage".

    Default value: OAuthomatic tokens (remember to change if you have
    scripts working on few different accounts of the same website).

 browser

    Command used to spawn the web browser.

    Default value: best guess (using Browser::Open).

    Set to empty string to avoid spawning browser at all and show
    instructions (Open web browser on https://....) on the console instead.

 html_dir

    Directory containing HTML templates and related resources for pages
    generated by OAuthomatic (post-authorization page, application tokens
    prompt and confirmation).

    To modify their look and feel, copy oauthomatic_html directory from
    OAuthomatic distribution somewhere, edit to your taste and provide
    resulting directory as html_dir.

    By default, files distributed with OAuthomatic are used.

 debug

    Make object print various info to STDERR. Useful while diagnosing
    problems.

ADDITIONAL PARAMETERS

 config

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

 secret_storage

    Pluggable behaviour: modify the method used to persistently save and
    restore various OAuth tokens. By default
    OAuthomatic::SecretStorage::Keyring (which uses Passwd::Keyring::Auto
    storage) is used, but any object implementing
    OAuthomatic::SecretStorage role can be substituted instead.

 oauth_interaction

    Pluggable behaviour: modify the way application uses to capture return
    redirect after OAuth access is granted. By default temporary web server
    is started on local address (it suffices to handle redirect to
    localhost) and used to capture traffic, but any object implementing
    OAuthomatic::OAuthInteraction role can be substituted instead.

    In case default is used, look and feel of the final page can be
    modified using "html_dir".

 user_interaction

    Pluggable behaviour: modify the way application uses to prompt user for
    application keys. By default form is shown in the browser, but any
    object implementing OAuthomatic::UserInteraction role can be
    substituted instead.

    Note: you can use OAuthomatic::UserInteraction::ConsolePrompts to be
    prompted in the console.

    In case default is used, look and feel of the pages can be modified
    using "html_dir".

METHODS

 erase_client_cred

        $oa->erase_client_cred();

    Drops current client (app) credentials both from the object and,
    possibly, from storage.

    Use if you detect error which prove they are wrong, or if you want to
    forget them for privacy/security reasons.

 erase_token_cred

        $oa->erase_token_cred();

    Drops access (app) credentials both from the object and, possibly, from
    storage.

    Use if you detect error which prove they are wrong.

 ensure_authorized

        $oa->ensure_authorized();

    Ensure object is ready to make calls.

    If initialization sequence happened in the past and appropriate tokens
    are available, this method restores them.

    If not, it performs all the work required to setup OAuth access to
    given website: asks user for application keys (or loads them if already
    known), leads the user through application authorization sequence,
    preserve acquired tokens for future runs.

    Having done all that, it leaves object ready to make OAuth-signed calls
    (actual signatures are calculated using Net::OAuth.

    Calling this method is not necessary - it will be called automatically
    before first request is executed, if not done earlier.

 execute_request

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

    method

      One of 'GET', 'POST', 'PUT', 'DELETE'.

    url

      Actual URL to call ('http://some.site.com/api/...')

    url_args (optional)

      Additional arguments to escape and add to the URL. This is simply
      shortcut, three calls below are equivalent:

          $c->execute_oauth_request(method => "GET",
              url => "http://some.where/api?x=1&y=2&z=a+b");
      
          $c->execute_oauth_request(method => "GET",
              url => "http://some.where/api",
              url_args => {x => 1, y => 2, z => 'a b'});
      
          $c->execute_oauth_request(method => "GET",
              url => "http://some.where/api?x=1",
              url_args => {y => 2, z => 'a b'});

    body_form OR body

      Exactly one of those must be specified for POST and PUT (none for GET
      or DELETE).

      Specifying body_form means, that we are creating www-urlencoded form.
      Specified values will be rendered appropriately and whole message
      will get proper content type. Example:

          $c->execute_oauth_request(method => "POST",
              url => "http://some.where/api",
              body_form => {par1 => 'abc', par2 => 'd f'});

      Note that this is not just a shortcut for setting body to already
      serialized form. Case of urlencoded form is treated in a special way
      by OAuth (those values impact OAuth signature). To avoid signature
      verification errors, OAuthomatic will reject such attempts:

          # WRONG AND WILL FAIL. Use body_form if you post form.
          $c->execute_oauth_request(method => "POST",
              url => "http://some.where/api",
              body => 'par1=abc&par2=d+f',
              content_type => 'application/x-www-form-urlencoded');

      Specifying body means, that we post non-form body (for example JSON,
      XML or even binary data). Example:

          $c->execute_oauth_request(method => "POST",
              url => "http://some.where/api",
              body => "<product><item-no>3434</item-no><price>334.22</price></product>",
              content_type => "application/xml; charset=utf-8");

      Value of body can be either binary string (which will be posted
      as-is), or perl unicode string (which will be encoded according to
      the content type, what by default means utf-8).

      Such content is not covered by OAuth signature, so less secure (at
      least if it is posted over non-SSL connection).

      For longer bodies, references are supported:

          $c->execute_oauth_request(method => "POST",
              url => "http://some.where/api",
              body => \$body_string,
              content_type => "application/xml; charset=utf-8");

    content_type

      Used to set content type of the request. If missing, it is set to
      text/plain; charset=utf-8 if body param is specified and to
      application/x-www-form-urlencoded; charset=utf-8 if body_form param
      is specified.

      Note that module author does not test behaviour on encodings
      different than utf-8 (although they may work).

    Returns HTTP::Response object.

    Throws structural exception on HTTP (40x, 5xx) and technical (like
    network) failures.

    Example:

        my $result = $oauthomatic->make_request(
            method => "GET", url => "https://some.api/get/things",
            url_args => {name => "Thingy", count => 4});
        # $result is HTTP::Response object and we know request succeeded
        # on HTTP level

 build_request

        $oa->build_request(method => $method, url => $url, url_args => $args,
                           body_form => $body_form, body => $body,
                           content_type => $content_type)

    Build appropriate HTTP::Request, ready to be executed, with proper
    headers and signature, but do not execute it. Useful if you prefer to
    use your own HTTP client.

    See "build_oauth_request" in OAuthomatic::Caller for the meaning of
    parameters.

    Note: if you are executing requests yourself, consider detecting cases
    of wrong client credentials, obsolete token credentials etc, and
    calling or "erase_client_cred" or "erase_token_cred". The
    OAuthomatic::Error::HTTPFailure may be of help.

 get

        my $reply = $ua->get($url, { url => 'args', ...);

    Shortcut. Make OAuth-signed GET request, ensure request succeeded and
    return it's body without parsing it (but decoding it from transport
    encoding).

 get_xml

        my $reply = $ua->get($url, { url => 'args', ...);

    Shortcut. Make OAuth-signed GET request, ensure request succeeded and
    return it's body. Body is not parsed, it remains to be done in the
    outer program (there are so many XML parsers I did not want to vote for
    one).

    This is almost equivalent to "get" (except it sets request content type
    to application/xml), mainly used to clearly signal intent.

 get_json

        my $reply = $oa->get_json($url, {url=>args, ...});
        # $reply is hash or array ref

    Shortcut. Make OAuth-signed GET request, ensure it succeeded, parse
    result as JSON, return resulting structure.

    Example:

        my $result = $oauthomatic->get_json(
            "https://some.api/things", {filter => "Thingy", count => 4});
        # Grabs https://some.api/things?filter=Thingy&count=4 and parses as JSON
        # $result is hash or array ref

 post

        my $reply = $ua->post($url, { body=>args, ... });
        my $reply = $ua->post($url, { url=>args, ...}, { body=>args, ... });
        my $reply = $ua->post($url, "body content");
        my $reply = $ua->post($url, { url=>args, ...}, "body content");
        my $reply = $ua->post($url, $ref_to_body_content);
        my $reply = $ua->post($url, { url=>args, ...}, $ref_to_body_content);

    Shortcut. Make OAuth-signed POST request, ensure request succeeded and
    return reply body without parsing it.

    May take two or three parameters. In two-parameter form it takes URL to
    POST and body. In three-parameter, it takes URL, additional URL params
    (to be added to URI), and body.

    Body may be specified as:

      * Hash reference, in which case contents of this hash are treated as
      form fields, urlencoded and whole request is executed as urlencoded
      POST.

      * Scalar or reference to scalar, in which case it is pasted verbatim
      as post body.

    Note: use use "execute_request" for more control on parameters (in
    particular, content type).

 post_xml

        my $reply = $ua->post($url, "<xml>content</xml>");
        my $reply = $ua->post($url, { url=>args, ...}, "<xml>content</xml>");
        my $reply = $ua->post($url, $ref_to_xml_content);
        my $reply = $ua->post($url, { url=>args, ...}, $ref_to_xml_content);

    Shortcut. Make OAuth-signed POST request, ensure request succeeded and
    return reply body without parsing it.

    May take two or three parameters. In two-parameter form it takes URL to
    POST and body. In three-parameter, it takes URL, additional URL params
    (to be added to URI), and body.

    This is very close to "post" (XML is neither rendered, nor parsed
    here), used mostly to set proper content-type and to clearly signal
    intent in the code.

 post_json

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

      * Hash or array reference, in which case contents of this reference
      are serialized to JSON and then used as request body.

      * Scalar or reference to scalar, in which case it is treated as
      already serialized JSON and posted verbatim as post body.

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

 put

        my $reply = $ua->put($url, { body=>args, ... });
        my $reply = $ua->put($url, { url=>args, ...}, { body=>args, ... });
        my $reply = $ua->put($url, "body content");
        my $reply = $ua->put($url, { url=>args, ...}, "body content");
        my $reply = $ua->put($url, $ref_to_body_content);
        my $reply = $ua->put($url, { url=>args, ...}, $ref_to_body_content);

    Shortcut. Make OAuth-signed PUT request, ensure request succeeded and
    return reply body without parsing it.

    May take two or three parameters. In two-parameter form it takes URL to
    PUT and body. In three-parameter, it takes URL, additional URL params
    (to be added to URI), and body.

    Body may be specified in the same way as in "post": as scalar, scalar
    reference, or as hash reference which would be urlencoded.

 put_xml

        my $reply = $ua->put($url, "<xml>content</xml>");
        my $reply = $ua->put($url, { url=>args, ...}, "<xml>content</xml>");
        my $reply = $ua->put($url, $ref_to_xml_content);
        my $reply = $ua->put($url, { url=>args, ...}, $ref_to_xml_content);

    Shortcut. Make OAuth-signed PUT request, ensure request succeeded and
    return reply body without parsing it.

    May take two or three parameters. In two-parameter form it takes URL to
    PUT and body. In three-parameter, it takes URL, additional URL params
    (to be added to URI), and body.

    This is very close to "put" (XML is neither rendered, nor parsed here),
    used mostly to set proper content-type and to clearly signal intent in
    the code.

 put_json

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

    JSON body may be specified just as in "post_json": as hash or array
    reference (to be serialized) or as scalar or scalar reference (treated
    as already serialized).

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

 delete_

        $oa->delete_($url);
        $oa->delete_($url, {url => args, ...});

    Shortcut. Executes DELETE on given URL. Note trailing underscore in the
    name (to avoid naming conflict with core perl function).

    Returns reply body content, if any.

ATTRIBUTES

 client_cred

    OAuth application identifiers - client_key and client_secret. As
    OAuthomatic::Types::ClientCred object.

    Mostly used internally but can be of use if you need (or prefer) to use
    OAuthomatic only for initialization, but make actual calls using some
    other means.

    Note that you must call "ensure_authorized" to bo be sure this object
    is set.

 token_cred

    OAuth application identifiers - access_token and access_token_secret.
    As OAuthomatic::Types::TokenCred object.

    Mostly used internally but can be of use if you need (or prefer) to use
    OAuthomatic only for initialization, but make actual calls using some
    other means.

    Note that you must call "ensure_authorized" to bo be sure this object
    is set.

THANKS

    Keith Grennan, for writing Net::OAuth, which this module uses to
    calculate and verify OAuth signatures.

    Simon Wistow, for writing Net::OAuth::Simple, which inspired some parts
    of my module.

    E. Hammer-Lahav for well written and understandable RFC 5849.

SOURCE REPOSITORY

    Source code is maintained in Mercurial <http://mercurial.selenic.com>
    repository at bitbucket.org/Mekk/perl-oauthomatic
    <https://bitbucket.org/Mekk/perl-oauthomatic>:

        hg clone https://bitbucket.org/Mekk/perl-oauthomatic

    See README-development.pod in source distribution for info how to build
    module from source.

ISSUE TRACKER

    Issues can be reported at:

      * Bitbucket issue tracker
      <https://bitbucket.org/Mekk/perl-oauthomatic/issues>

      * CPAN bug tracker
      <https://rt.cpan.org/Dist/Display.html?Queue=OAuthomatic>

    The former is slightly preferred but feel free using CPAN tracker if
    you find it more usable.

AUTHOR

    Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>

COPYRIGHT AND LICENSE

    This software is copyright (c) 2015 by Marcin Kasperski.

    This is free software; you can redistribute it and/or modify it under
    the same terms as the Perl 5 programming language system itself.

