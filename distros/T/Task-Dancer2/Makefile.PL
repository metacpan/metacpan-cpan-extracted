use strict;
use warnings;
use lib '.';

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

my %features = (
    templating => {
        namespace       => 'Template',

        Caribou         => { name => 'Template::Caribou wrapper for Dancer2' },
        Haml            => { name => 'Text::Haml engine for Dancer2' },
        Handlebars      => { name => 'Dancer2 wrapper for Handlebars templating engine' },
        HTCompiled      => { name => 'HTML::Template::Compiled template engine for Dancer2' },
        Mason2          => { name => 'Mason 2.x engine for Dancer2' },
        MojoTemplate    => { name => 'Mojo::Template wrapper for Dancer2',
                             minperl => '5.016000' },
        Mustache        => { name => 'Wrapper for the Mustache template system' },
        Obj2HTML        => { name => 'Templating system based on HTML::Obj2HTML' },
        TemplateFlute   => { name => 'Template flute engine for Dancer2' },
        TextTemplate    => { name => 'Text::Template engine for Dancer2' },
        Xslate          => { name => 'Text::Xslate template engine for Dancer2 ' },
    },

    logging => {
        namespace  => 'Logger',

        'Console::Colored' => { name => 'Dancer2 colored console logger' },
        'File::RotateLogs' => { name => 'An automated logrotate' },
        Fluent             => { name => 'Dancer2 logger engine for Fluent::Logger' },
        Log4perl           => { name => 'Dancer2 logger interface for Log4perl' },
        LogAny             => { name => 'Use Log::Any to log from your Dancer2 app' },
        LogReport          => { name => 'Reroute Dancer2 logs into Log::Report' },
        Multiplex          => { name => 'Log to multiple Dancer2::Logger engines' },
        Radis              => { name => 'Dancer2 logging engine for Log::Radis' },
        Syslog             => { name => 'Logging engine for Sys::Syslog' },
    },

    serialization => {
        namespace => 'Serializer',

        CBOR     => { name => 'CBOR serializer for Dancer2' },
        XML      => { name => 'Serializer for handling XML data' },
    },

    session => {
        namespace => 'Session',

        CGISession      => { name => 'Share Dancer2 sessions with CGI::Session' },
        CHI             => { name => 'Dancer2 session storage with CHI backend' },
        Cookie          => { name => 'Session storage in secure cookies' },
        DBIC            => { name => 'DBIx::Class session engine for Dancer2' },
        DatabasePlugin  => { name => 'Dancer2::Session implementation for databases' },
        JSON            => { name => 'Session storage in JSON files' },
        Memcached       => { name => 'Session storage with Cache::Memcached' },
        MongoDB         => { name => 'Session storage with MongoDB' },
        PSGI            => { name => 'Session storage via Plack::Middleware::Session' },
        Redis           => { name => 'Session storage in Redis' },
        Sereal          => { name => 'Session storage in files via Sereal' },
    },

    plugin => {
        namespace    => 'Plugin',

        Adapter         => { name => 'Wrap any simple class as a service for Dancer2' },
        Ajax            => { name => 'Add AJAX route handlers' },
        'AppRole::Helper' => { name => 'Helper functions for creating Dancer2 AppRole plugins' },
        Articulate      => { name => 'Use Articulate in your Dancer2 App' },
        'Auth::ActiveDirectory' => { name => 'Dancer2 plugin for MS ActiveDirectory' },
        'Auth::CAS'     => { name => 'CAS sso authentication for Dancer2' },
        'Auth::Extensible' => { name => 'Extensible authentication framework for Dancer2 apps' },
        'Auth::Extensible::Provider::ActiveDirectory' => { name => 'ActiveDirectory authentication provider for Dancer2::Plugin::Auth::Extensible' },
        'Auth::Extensible::Provider::Database' => { name => 'Authenticate via a database' },
        'Auth::Extensible::Provider::DBIC' => { name => 'Authenticate via the Dancer2::Plugin::DBIC plugin' },
        'Auth::Extensible::Provider::DBIx::Class' => { name => 'Authenticate via the Dancer2::Plugin::DBIx:Class plugin' },
        'Auth::Extensible::Provider::IMAP' => { name => 'IMAP authentication provider for Dancer2::Plugin::Auth::Extensible' },
        'Auth::Extensible::Provider::LDAP' => { name => 'LDAP authentication provider for Dancer2::Plugin::Auth::Extensible' },
        'Auth::Extensible::Provider::Usergroup' => { name => 'Authenticate as a member of a group' },
        'Auth::Extensible::Rights' => { name => 'A rights mapper for Dancer2::Plugin::Auth::Extensible roles' },
        'Auth::HTTP::Basic::DWIW' => { name => 'HTTP Basic authentication plugin for Dancer2 that does what I want' },
        'Auth::OAuth'   => { name => 'OAuth for your Dancer2 app' },
        'Auth::SAFE'    => { name => 'Thomson Reuters SAFE SSO authentication plugin for Dancer2' },
        'Auth::Tiny'    => { name => 'Simple plugin for handling user auth' },
        'Auth::YARBAC'  => { name => 'Yet Another Role Based Access Control Framework' },
        Argon2          => { name => 'Handling Argon2 passwords in Dancer2' },
        BrowserDetect   => { name => 'Easily detect browser information' },
        'Cache::CHI'    => { name => 'Plugin to cache response content (and anything else)' },
        Captcha         => { name => 'Dancer2 add-on for CAPTCHA' },
        Cart            => { name => 'Cart interface for Dancer2 applications' },
        Chain           => { name => 'Add-on for route chaining' },
        ConditionalCaching => { name => 'RFC7234 Caching' },
        ControllerAutoload => { name => 'RFC7234 Caching' },
        CryptPassphrase => { name => 'Use Crypt::Passphrase with Dancer2' },
        CSRF            => { name => 'CSRF tokens generation and validation' },
        CSRFI           => { name => 'Improved CSRF token generation and validation' },
        Database        => { name => 'Easy database connections for Dancer2 applications' },
        DataTransposeValidator => { name => 'Data::Transpose::Validator plugin for Dancer2' },
        DBIC            => { name => 'DBIx::Class interface for Dancer2 applications' },
        'DBIx::Class'   => { name => 'Syntactic sugar for DBIx::Class in Dancer2, optionally with DBIx::Class::Schema::ResultSetNames' },
        Debugger        => { name => 'Debugger plugin for Dancer2 for Plack::Debugger' },
        DebugDump       => { name => "Modified debug behavior to create multi-line output that's easier for mere mortals to parse" },
        Deferred        => { name => 'Defer messages or data across redirections' },
        DoFile          => { name => 'A file based MVC style plugin for Dancer2' },
        EditFile        => { name => 'Dancer2 plugin for obtaining Search::Elasticsearch handles' },
        ElasticSearch   => { name => 'Dancer2 plugin for obtaining Search::Elasticsearch handles' },
        Email           => { name => 'Simple email sending for Dancer2 applications' },
        Emailesque      => { name => 'Simple Emailesque support for Dancer2' },
        EncryptID       => { name => 'Obfuscate IDs/string in URLs' },
        Etcd            => { name => 'Connect to Etcd via v3 API' },
        Feed            => { name => 'Easy to generate feed rss or atom for Dancer2 applications' },
        Flash           => { name => 'Flash message for Dancer2' },
        FlashNote       => { name => 'Support notifications in your Dancer2 web application' },
        FontSubset      => { name => 'Generate font subsets on-the-fly' },
        FormValidator   => { name => 'Neat and easy to start form validation plugin for Dancer2' },
        'FormValidator::Extension::DBIC' => { name => 'Dancer2 FormValidator extension for checking fields existence in table rows' },
        'FormValidator::Extension::Password' => { name => 'Dancer2 FormValidator extension for validating passwords' },
        'Github::Webhook' => { name => 'Check Github Webhook secret' },
        GoogleAnalytics => { name => 'A Dancer2 plugin to easily add Google Analytics code' },
        GraphQL         => { name => 'A plugin for adding GraphQL route handlers' },
        GoogleAnalytics => { name => 'Dancer2 plugin to easily add Google Analytics code' },
        Growler         => { name => 'Growl multiple messages of varying types to the user on their next hit' },
        'HTTP::Auth::Extensible' => { name => 'User authen/authz plugin for Dancer2' },
        'HTTP::Bundle'  => { name => 'The missing HTTP bits of Dancer2 Bundled' },
        'HTTP::Caching' => { name => 'RFC 7234 compliant HTTP caching' },
        'HTTP::ConditionalRequest' => { name => 'RFC 7232 compliant' },
        'HTTP::ContentNegotiation' => { name => 'Server-driven negotiation' },
        Interchange6    => { name => 'Interchange6 Shop Plugin for Dancer2' },
        JSManager       => { name => 'Manage website javascript files with the Dancer2 configuration file' },
        JWT             => { name => 'JSON Web Token made simple for Dancer2' },
        Locale          => { name => 'Localize your Dancer2 application' },
        'Locale::Meta'  => { name => 'Plugin for Locale::Meta' },
        'Locale::Wolowitz' => { name => 'Plugin for Locale::Wolowitz' },
        LogContextual   => { name => 'Wrap a Dancer2 plack app in the configured Log::Contextual logger' },
        LogReport       => { name => 'Logging and exceptions via Log::Report' },
        'Map::Tube'     => { name => 'Dancer2 add-on for Map::Tube' },
        MarkdownFilesToHTML => { name => 'Easy conversion of markdown documents to HTML for display in your Dancer2 website' },
        Menu            => { name => 'Automatically generate an HTML menu for your Dancer2 app' },
        Minify          => { name => 'Minify HTML, JavaScript and CSS' },
        Minion          => { name => 'Easy access to Minion job queue in your Dancer2 applications' },
        MobileDevice    => { name => 'Make a Dancer2 app mobile-aware' },
        Model           => { name => 'Hang a model layer on Dancer2 applications' },
        Multilang       => { name => 'Plugin to create multi-language sites' },
        Negotiate       => { name => 'Content negotiation plugin for Dancer 2' },
        OpenAPIRoutes   => { name => 'Automatic routes creation from Swagger specification file' },
        'OAuth2::Server' => { name => 'Implementation of an OAuth2 Authorization Server' },
        PageHistory     => { name => 'Store recent page history for user into session' },
        Paginator       => { name => 'Dancer2 plugin for Paginator::Lite' },
        ParamTypes      => { name => 'Parameter type checking plugin for Dancer2' },
        Passphrase      => { name => 'Passphrases and passwords as objects' },
        'Path::Class'   => { name => 'List a directory using Path::Class' },
        Pg              => { name => 'PostgreSQL connection for Dancer2' },
        ProbabilityRoute => { name => 'Plugin to define behavior with probability matching rules' },
        ProgressStatus  => { name => 'Keeps track of progress status' },
        PrometheusTiny  => { name => 'Use Prometheus::Tiny with Dancer2' },
        Queue           => { name => 'Message queue abstractions' },
        'Queue::IronMQ' => { name => 'Dancer2::Plugin::Queue backend for IronMQ' },
        'Queue::MongoDB' => { name => 'Dancer2::Plugin::Queue backend using MongoDB' },
        reCAPTCHA       => { name => 'Integrate reCAPTCHA into Dancer2 applications' },
        Redis           => { name => 'Plugin for interaction with key-value-store Redis' },
        Res             => { name => 'Add on for setting status/response' },
        REST            => { name => 'Write RESTful apps with Dancer2' },
        RPC             => { name => 'Namespace for XMLRPC, JSONRPC2 and RESTRPC plugins' },
        'RPC::RESTISH'  => { name => 'Simple plugin to implement a restish interface' },
        RootURIFor      => { name => 'Mountpoint-agnostic URI builder' },
        RoutePodCoverage => { name => 'Verify route Pod coverage in Dancer2 apps' },
        Routing         => { name => 'A dancer2 plugin for configurable routing' },
        SessionDatabase => { name => 'Hook Loader For Dancer2::Session::DatabasePlugin' },
        Shutdown        => { name => 'Graceful shutdown of your Dancer2 application' },
        'Shutdown::Redis' => { name => 'Graceful shutdown of your Dancer2 application with Redis propagation' },
        Sixpack         => { name => 'Plugin for WWW::Sixpack' },
        SPID            => { name => 'SPID authentication for Dancer2 web applications' },
        'Syntax::GetPost' => { name => 'Syntactic sugar for GET+POST handlers' },
        'Syntax::ParamKeywords' => { name => 'Parameter keywords for the lazy' },
        'SyntaxHighlight::Perl' => { name => 'Generate pretty HTML from Perl code in a Dancer2 app' },
        Tail            => { name => 'Tail a file from Dancer2' },
        TemplateFlute   => { name => 'Dancer2 form handler for Template::Flute template engine' },
        UnicodeNormalize => { name => 'Normalize incoming Unicode parameters' },
        ViewCache       => { name => 'Normalize incoming Unicode parameters' },
        WebService      => { name => 'RESTful Web Services with login, persistent data, multiple in/out formats, IP security, role based access' },
        WebSocket       => { name => 'Add a websocket interface to your Dancer2 app' },
    },
);

name     'Task-Dancer2';
all_from 'lib/Task/Dancer2.pm';
license  'perl';
include  'Module::AutoInstall';
requires 'Dancer2' => 0;

foreach my $type ( keys %features ) {
    my $namespace = delete $features{$type}{'namespace'};

    foreach my $semi_namespace ( keys %{ $features{$type} } ) {
        my $full_namespace = $namespace                               ?
                            "Dancer2::${namespace}::${semi_namespace}" :
                            "Dancer2::${semi_namespace}";

        if (exists($features{$type}{$semi_namespace}{minperl}) &&
            $features{$type}{$semi_namespace}{minperl} > $] ) {
            my $v = $features{$type}{$semi_namespace}{minperl};
            warn "**[ Skipping $full_namespace (requires Perl $v) ]**\n";
            next;
        }

        my ( $name, $default, $min ) =
            @{ $features{$type}{$semi_namespace} }{qw/ name default min /};

        # install by default unless otherwise specified
        $default = defined($default) ? 0 : 1;

        # no minimum version by default
        $min ||= 0;

        feature "$name $type support",
            -default => $default, $full_namespace => $min;
    }
}

auto_install;
WriteAll;

