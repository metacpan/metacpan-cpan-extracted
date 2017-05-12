use strict;
use warnings;

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

##
## Problems we are currently aware of (Linux and OSX):
## - Data::Alias isn't installing for Template::Caribou
## - Test failures in Dancer2::Session::Sereal
## - Test failures in Dancer2::Plugin::Auth::YARBAC
## - Test failures in Dancer2::Plugin::Queue
## - Unmet dependency (String::UnicodeUTF8.pm) in ::Locale, other failures
## - Test failures in HTTP::Auth::Extensible
## - Test failures in ElasticSearch
## - Dependency issues/missing in Text::Xslate
##

my %features = (
    templating => {
        namespace       => 'Template',

        #Caribou         => { name => 'Template::Caribou wrapper for Dancer2' },
        Haml            => { name => 'Text::Haml engine for Dancer2' },
        HTCompiled      => { name => 'HTML::Template::Compiled template engine for Dancer2' },
        Mason2          => { name => 'Mason 2.x engine for Dancer2' },
        MojoTemplate    => { name => 'Mojo::Template wrapper for Dancer2',
                             minperl => '5.010001' },
        TemplateFlute   => { name => 'Template flute engine for Dancer2' },
        TextTemplate    => { name => 'Text::Template engine for Dancer2' },
        #Xslate          => { name => 'Text::Xslate template engine for Dancer2 ' },
    },

    logging => {
        namespace  => 'Logger',

        'Console::Colored' => { name => 'Dancer2 colored console logger' },
        'File::RotateLogs' => { name => 'An automated logrotate' },
        Syslog             => { name => 'Logging engine for Sys::Syslog' },
    },

    serialization => {
        namespace => 'Serializer',

        CBOR     => { name => 'CBOR serializer for Dancer2 ' },
    },

    session => {
        namespace => 'Session',

        CGISession      => { name => 'Share Dancer2 sessions with CGI::Session' },
        Cookie          => { name => 'Session storage in secure cookies' },
        DBIC            => { name => 'DBIx::Class session engine for Dancer2' },
        JSON            => { name => 'Session storage in JSON files' },
        Memcached       => { name => 'Session storage with Cache::Memcached' },
        MongoDB         => { name => 'Session storage with MongoDB' },
        PSGI            => { name => 'Session storage via Plack::Middleware::Session' },
        Redis           => { name => 'Session storage in Redis' },
        #Sereal          => { name => 'Session storage in files via Sereal' },
    },

    plugin => {
        namespace    => 'Plugin',

        Adapter         => { name => 'Wrap any simple class as a service for Dancer2' },
        Ajax            => { name => 'Add AJAX route handlers' },
        'AppRole::Helper' => { name => 'Helper functions for creating Dancer2 AppRole plugins' },
        Articulate      => { name => 'Use Articulate in your Dancer2 App' },
        'Auth::Extensible' => { name => 'Extensible authentication framework for Dancer2 apps' },
        'Auth::Extensible::Provider::DBIC' => { name => 'Authenticate via the Dancer2::Plugin::DBIC plugin' },
        'Auth::Extensible::Provider::Usergroup' => { name => 'Authenticate as a member of a group' },
        'Auth::HTTP::Basic::DWIW' => { name => 'HTTP Basic authentication plugin for Dancer2 that does what I want' },
        'Auth::OAuth'   => { name => 'OAuth for your Dancer2 app' },
        'Auth::Tiny'    => { name => 'Simple plugin for handling user auth' },
        #'Auth::YARBAC'  => { name => 'Yet Another Role Based Access Control Framework' },
        BrowserDetect   => { name => 'Easily detect browser information' },
        'Cache::CHI'    => { name => 'Plugin to cache response content (and anything else)' },
        Captcha         => { name => 'Dancer2 add-on for CAPTCHA' },
        Chain           => { name => 'Add-on for route chaining' },
        ConditionalCaching => { name => 'RFC7234 Caching' },
        Database        => { name => 'Easy database connections for Dancer2 applications' },
        DataTransposeValidator => { name => 'Data::Transpose::Validator plugin for Dancer2' },
        DBIC            => { name => 'DBIx::Class interface for Dancer2 applications' },
        Deferred        => { name => 'Defer messages or data across redirections' },
        #ElasticSearch   => { name => 'Dancer2 plugin for obtaining Search::Elasticsearch handles' },
        Email           => { name => 'Simple email sending for Dancer2 applications' },
        Emailesque      => { name => 'Simple Emailesque support for Dancer2' },
        Feed            => { name => 'Easy to generate feed rss or atom for Dancer2 applications' },
        GoogleAnalytics => { name => 'Dancer2 plugin to easily add Google Analytics code' },
        Growler         => { name => 'Growl multiple messages of varying types to the user on their next hit' },
        #'HTTP::Auth::Extensible' => { name => 'User authen/authz plugin for Dancer2' },
        JWT             => { name => 'JSON Web Token made simple for Dancer2' },
        #Locale          => { name => 'Localize your Dancer2 application' },
        #'Locale::Wolowitz' => { name => 'Plugin for Locale::Wolowitz' },
        LogContextual   => { name => 'Wrap a Dancer2 plack app in the configured Log::Contextual logger' },
        LogReport       => { name => 'Logging and exceptions via Log::Report' },
        Model           => { name => 'Hang a model layer on Dancer2 applications' },
        Multilang       => { name => 'Plugin to create multi-language sites' },
        Negotiate       => { name => 'Content negotiation plugin for Dancer 2' },
        ParamKeywords   => { name => 'Sugar for the params() keyword' },
        Passphrase      => { name => 'Passphrases and passwords as objects' },
        'Path::Class'   => { name => 'List a directory using Path::Class' },
        ProgressStatus  => { name => 'Keeps track of progress status' },
        Queue           => { name => 'Message queue abstractions' },
        'Queue::MongoDB' => { name => 'Dancer2::Plugin::Queue backend using MongoDB' },
        reCAPTCHA       => { name => 'Integrate reCAPTCHA into Dancer2 applications' },
        Redis           => { name => 'Plugin for interaction with key-value-store Redis' },
        Res             => { name => 'Add on for setting status/response' },
        REST            => { name => 'Write RESTful apps with Dancer2' },
        RootURIFor      => { name => 'Mountpoint-agnostic URI builder' },
        RoutePodCoverage => { name => 'Verify route Pod coverage in Dancer2 apps' },
        Sixpack         => { name => 'Plugin for WWW::Sixpack' },
        'Syntax::GetPost' => { name => 'Syntactic sugar for GET+POST handlers' },
        UnicodeNormalize => { name => 'Normalize incoming Unicode parameters' },
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

