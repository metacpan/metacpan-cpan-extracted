package OpenPluginTests;

require Exporter;

@OpenPluginTests::ISA       = qw( Exporter );
@OpenPluginTests::EXPORT_OK = qw( get_config );

# This all takes the place of having individual config files.  There's less
# files cluttering things up, and it's easy to reuse.
my $CONFIG_DATA = {
    cache_file => {
        cache => {
            load    => "Startup",
            expires => "+3h",

            driver => {
                File => {},
            },
        },
    },
    session_apachesession => {
        session => {
            load    => "Startup",
            expires => "+3h",

            driver => {
                ApacheSession => {
                    Store         => "File",
                    Directory     => "/tmp",
                    LockDirectory => "/tmp",
                },
            },
        },
    },
    log_log4perl => {
        log => {
            load   => "Startup",
            driver => {
                Log4perl => {
                   "rootLogger"      => "WARN, stderr",
                   "appender.stderr" => "Log::Dispatch::Screen",
                   "appender.stderr.layout" => "org.apache.log4j.PatternLayout",
                   "appender.stderr.layout.ConversionPattern" => "%F (%L) %m%n",
                }
            }
        },
    },
    exception => {
        exception => {
            load   => "Startup",
            driver => {
                "built-in" => {},
            },
        },
    },
    request_apache2 => {
        request => {
            load   => "Startup",
            driver => {
                Apache2 => {},
            },

            plugin => {
                param => {
                    load => "Startup",
                    driver => {
                        Apache2 => {},
                    }
                },
                httpheader => {
                    load => "Startup",
                    driver => {
                        Apache2 => {},
                    }
                },
                cookie => {
                    load => "Auto",
                    driver => {
                        Apache2 => {},
                    }
                },
                upload => {
                    load => "Startup",
                    driver => {
                        Apache2 => {},
                    }
                },
            },
        },
    },
    request_apache => {
        request => {
            load   => "Startup",
            driver => {
                Apache => {},
            },

            plugin => {
                param => {
                    load => "Startup",
                    driver => {
                        Apache => {},
                    }
                },
                httpheader => {
                    load => "Startup",
                    driver => {
                        Apache => {},
                    }
                },
                cookie => {
                    load => "Startup",
                    driver => {
                        Apache => {},
                    }
                },
                upload => {
                    load => "Startup",
                    driver => {
                        Apache => {},
                    }
                },
            },
        },
    },
    request_cgi => {
        request => {
            load   => "Startup",
            driver => {
                CGI => {},
            },

            plugin => {
                param => {
                    load => "Startup",
                    driver => {
                        CGI => {},
                    }
                },
                httpheader => {
                    load => "Startup",
                    driver => {
                        CGI => {},
                    }
                },
                cookie => {
                    load => "Startup",
                    driver => {
                        CGI => {},
                    }
                },
                upload => {
                    load => "Startup",
                    driver => {
                        CGI => {},
                    }
                },
            },
        },
    },
};

sub get_config {
    my @args = @_;
    my $config;
    $config->{include}{src} = "./conf/OpenPlugin-drivermap.conf";

    foreach my $arg ( @args ) {
        foreach my $key ( keys %{ $CONFIG_DATA->{ $arg } } ) {
            $config->{'plugin'}{ $key } = $CONFIG_DATA->{ $arg }{ $key };
        }
    }

    return $config;
}

1;
