use strict;
use warnings;

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

my %features = (
    templating => {
        namespace       => 'Template',

        Tiny            => { name => 'Template::Tiny',
                             min  => '0.02'                },
        HtmlTemplate    => { name => 'HTML::Template',
                             min  => '0.02'                },

        Alloy           => { name => 'Alloy'               },
        Tenjin          => { name => 'Tenjin'              },
        Haml            => { name => 'Text::Haml'          },
        Mason           => { name => 'HTML::Mason'         },
        Mason2          => { name => 'HTML::Mason2',
                             min  => '0.02'                },
        MicroTemplate   => { name => 'Text::MicroTemplate' },
        MojoTemplate    => { name => 'Mojo::Template wrapper for Dancer',
                             minperl => '5.010001' },
        TemplateFlute   => { name => 'Template::Flute wrapper for Dancer'    },
        TemplateSandbox => { name => 'Template::Sandbox'                     },
        Xslate          => { name => 'Text::Xslate wrapper for Dancer'       },
    },

    logging => {
        namespace  => 'Logger',

        ColorConsole => { name => 'A colorful console logger'                },
        Log4perl   => { name => 'Log4Perl'                                   },
        Pipe       => { name => 'Pipe-based logging engine for Dancer'       },
        PSGI       => { name => 'PSGI'                                       },
        Spinner    => { name => 'Show a spinner in the console log messages' },
        Syslog     => { name => 'Sys::Syslog'                                },
    },

    serialization => {
        namespace => 'Serializer',

        UUEncode => { name => 'UU Encoding serializer' },
    },

    session => {
        namespace => 'Session',

        Cookie    => { name => 'Encrypted cookie-based'             },
        KiokuDB   => { name => 'KiokuDB Dancer session backend',
                       min  => '0.04'                               },
        Memcached => { name => 'Cache::Memcached'                   },
        MongoDB   => { name => 'MongoDB session backend for Dancer' },
        PSGI      => { name => 'Plack::Middleware::Session'         },
        Storable  => { name => 'Storable file-based'                },
        CHI       => { name => 'CHI-based session engine',
                       min => 0.001001  },
    },

    plugin => {
        namespace    => 'Plugin',

        Async           => { name => 'write async request handlers with Twiggy' },
        'Auth::Basic'   => { name => 'Basic HTTP authentication',
                             min => 0.011 },
        'Auth::Htpasswd'=> { name => 'Basic HTTP authentication with htpasswd files',
                             min => 0.011 },
        'Auth::Extensible'    => { name => 'Extensible authentication framework' },
        'Auth::Tiny'    => { name => 'Require logged-in user for specified routes' },
        'Auth::Twitter' => { name => 'Authenticate with Twitter'                },
        Bcrypt          => { name => 'Bcrypt interface for Dancer'              },
        Browser         => { name => 'Browser detection'                        },
        'Cache::CHI'    => { name => 'Plugin to cache response content'         },
        'Captcha::SecurityImage' => {
                             name    => 'Generate and verify GD::SecurityImage captchas',
                             default => 0                          },
        Database        => { name => 'Database'                    },
        DBIC            => { name => 'DBIx::Class interface'       },
        DebugDump       => { name => 'dump objects to debug log'   },
        DebugToolbar    => { name => 'debugging toolbar'           },
        DirectoryView   => { name => 'allow directory browsing'    },
        Email           => { name => 'Email::Stuff integration'    },
        EncodeID        => { name => 'obfuscate IDs in UCLs'       },
        EscapeHTML      => { name => 'Escape HTML entities to avoid XSS vulnerabilities' },
        Feed            => { name => 'Generate feed rss or atom'   },
        FlashMessage    => { name => 'Display temporary messages'  },
        FlashNote       => { name => 'Notification messages'       },
        FormattedOutput => { name => 'Provide output in a variety of formats' },
        FormValidator   => { name => 'Easy input validator'        },
        Hosts           => { name => 'Config trigger for virtual sites' },
        LibraryThing    => { name => 'Plugin for LibraryThing APIs' },
        Memcached       => { name => 'Cache response content'      },
        MemcachedFast   => { name => 'Cache things using Cache::Memcached::Fast' },
        MobileDevice    => { name => 'Dancer app mobile-aware',
                             min  => '0.03'                        },
        Mongo           => { name => 'MongoDB'                     },
        Nitesi          => { name => 'Nitesi Shop Machine support' },
        NYTProf         => { name => 'Devel::NYTProf profiling',
                             min => '0.04'                         },
        Passphrase      => { name => 'Passphrases and Passwords as objects' },
        'Params::Normalization' => { name => 'query param normalization' },
        'Preprocess::Sass' => { name => 'Generate CSS files from Sass/SCSS files'},
        Progress        => { name => 'display a progress bar during long-running requests' },
        ProxyPath       => { name => 'Provides user-perspective paths' },
        Redis           => { name => 'Redis database connections'  },
        REST            => { name => 'RESTful apps',
                             min  => '0.05'                        },
        # Scoped        => { name => 'parameter variables scoping' }, => failing 0.01
        SimpleCRUD      => { name => 'very simple CRUD',
                             min  => '0.02'                        },
        SiteMap         => { name => 'Site map creation'           },
        SMS             => { name => 'Easy SMS sending'            },
        ## SporeDefinitionControl => { name => 'Validite route from a Spore' }, 0.09 is failing
        Stomp           => { name => 'Interact with Stomp message broker' },
        TimeRequests    => { name => 'Log how long each request took to process' },
        Thumbnail       => { name => 'Easy thumbnail creation',
                             default => 0      },
        ValidateTiny    => { name => 'Validate::Tiny Dancer plugin' },
        'XML::RSS'      => { name => 'XML::RSS to parse or create RSS feeds' },
    },

    # for now it's middlewares
    middleware => {
        namespace => 'Middleware',
        Rebase    => { name => 'Plack middleware for Dancer' },
    },

    other => {
        Debug => { name => 'Plack::Middleware::Debug' },
    },
);

name     'Task-Dancer';
all_from 'lib/Task/Dancer.pm';
license  'perl';
include  'Module::AutoInstall';
requires 'Dancer' => 0;

foreach my $type ( keys %features ) {
    my $namespace = delete $features{$type}{'namespace'};

    foreach my $semi_namespace ( keys %{ $features{$type} } ) {
        my $full_namespace = $namespace                               ?
                            "Dancer::${namespace}::${semi_namespace}" :
                            "Dancer::${semi_namespace}";

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

