# Service::Engine Config File
# This is a perl reference to a HASH

{   
    # general engine settings
    'engine'    =>  {
        # this is required; one word, no spaces or special characters
        # the directory enclosing this file must also be named this
        'name'  => 'sampleLogging',
        'instance' => '1', # unique identifier for this instance of the engine
        # performance options
        'sleep' => 60,  # seconds between selector passes; default is 0
        'select_limit' => 1,  # number or records to select per pass; default is number of threads;
        'threads' => 1, # the number of threads to run, default is 5
    },
    # set logging options
    'logging'   =>  {
        'log_level' => 3, # -1 = disabled, 0 = critical, 1 = warnings, 2 = info, 3 = debug
        'types' => {   
            'to_file' => '/var/log/service_engine.log', # specify a relative or absolute file path; leave blank to disable; /var/log/service_engine.log
            'to_console' => 1, # enable or disable console logging
            'to_data' => {
                handle => 'crate_local',
                data_log_level => 3
            }  # enable logging to a data handle {handle=>'prod_rw', data_log_level=>0} - optional custom log level
        }
    },
    # set data connections  
    # NOTE: handle names must be unique!  
    # you are going to use them like this: my $dbh = $Data->dev_rw          
    'data' => {
        'Mysql' => {
            # handle - must be one word, no special characters
            'prod_mysql' => {   
                # connection parameters
                'database' => 'sample',
                'hostname' => 'mysql',
                'username' => 'sample',
                'password' => 'samplepassword',
                'port' => 3306, # optional default is 3306
                'raise_error' => 0 # optional default is 0
            },
        },
        # 'Memcached' => {
        #     # handle - must be one word, no special characters
        #     'prod_mc' => {
        #         # connection parameters
        #         'ip' => '127.0.0.1',
        #         'port' => '11211'
        #     }
        # },
        'Crate'   =>  {
            'crate_local' => {
                'hostname' => 'cratedb',
                'port' => '5432',
                'username' => 'hmgadmin',
                'password' => 'sample',
                'table' => 'logs',
                'dbname' => 'dev'
            }
        },
    },
    # set alerting methods
    'alerting' => {    
        'enabled' => 1,
        'modules' => {
            # standard modules - corresponds to Service::Engine::Alerting::* modules
            'Twilio' => {
                # handle - must be one word, no special characters
                'sms' => {    
                    'enabled' => 1,
                    # connection parameters
                    'AccountSid' => '',
                    'AuthToken'  => '',
                    'from'       => '',
                    'method'     => 'sendSMS',
                },
            },
            # 'Email' => {
            #     # handle - must be one word, no special characters
            #     'localhost' => {
            #         'enabled' => 1,
            #         'method' => 'sendEmail',
            #         'from' => '', # make sure you are allowed to send from this address
            #         'smtp_ip' => '127.0.0.1', # defaults to 127.0.0.1
            #         'smtp_port' => '25', # defaults to 25    
            #     },
            # },
            'Log' => {
                'to_file'   =>  {
                    'enabled' => 1,
                    'method'  => 'to_file',
                },
                'to_console' => {
                    'enabled' => 1,
                    'method'  => 'to_console',
                },
                'to_data'=>  {
                    'enabled' => 1,
                    'method' => 'to_data',
                }                                                     
            },
            # custom modules
            # 'mySMS' => {
            #     # handle - must be one word, no special characters
            #     'mySMS' => {
            #         'module_name' => 'mySMS', # myEngine::Modules::{name}
            #         # connection parameters
            #         'apikey' => ''
            #     },
            # },
        },
    },
    # set admin server options
    'admin'  => {    
        'enabled' => 1, # on or off
        'host_ip' => '127.0.0.1', # defaults to 127.0.0.1
        'host_port' => 42142, # defaults to 42142,
        'password' => '', # default is no password
        'timeout' => 3600, # how long to wait for keyboard entry, default is 3600
        'modules' => {
            # standard modules - corresponds to Service::Engine::Admin::* modules
            # 'Overview' => {
            #     'enabled' => 1,
            #     'options' => {'key'=>'value'}
            # },
            # custom modules
            # 'myModule' => {
            #     'module_name'=>'myModule', # myEngine::Modules::{name}
            # },
        },
    },
    # set api server options
    'api' => {
        'enabled' => 1, # on or off
        'host_ip' => '127.0.0.1', # defaults to 127.0.0.1
        'password' => '', # default is no password
        'host_port' => [8000], # [8080, "8443/ssl"], defaults to [8080, "8443/ssl"],
        'ssl' => {
            'SSL_key_file' => './ssl/ssl.key',
            'SSL_cert_file' => './ssl/ssl.cert'
        },                
        'allowed_resources' => {
            'Health'  => {'api_overview'=>1}, # module => allowed methods
            # 'Threads' => {'add_thread'=>1},
        },
        'modules' => {
            # standard modules - corresponds to Service::Engine::API::* modules
            'Overview' => {
                'enabled' => 1,
                'options' => {'key'=>'value'}
            },
            # custom modules
            'myModule' => {
                'module_name'=>'myModule', # myEngine::Modules::{name}
            },
        },
    },
    # health alerting and monitoring
    'health' => {
        'enabled' => 1,
        'frequency' => 60, # default is to check every 60 seconds
        'memcached' => {    
            # store msg ids in memcached
            # if no, they are stored in local memory
            # this is how we manage not sending duplicates
            'enabled' => 1,
            'handle'  =>'prod_mc',    
        },
        'modules' => {
            # standard check module - corresponds to Service::Engine::Health::* modules
            'Threads' => {
                'enabled' => 1,
                'options' => {
                    'critical' => 2, # <= number of threads is critical
                    'warning' => 3, # < number of threads is warning
                }, 
            },
            'Backlog' => {
                'enabled' => 1,
                'options' => {
                    'critical' => 10, # backlog per thread
                    'warning' => 5,
                }, 
            },
            'Memory' => {
                'enabled' => 1,
                'options' => {
                    'critical' => 10, # # need to figure these out
                    'warning' => 5,
                }, 
            },
            'Throughput' => {  
                'enabled' => 1,
                'options' => {'critical'=>60},
            },
            # custom modules
            # 'myModule' => {
            #    'module_name'=>'myModule', # myEngine::Modules::{name}
            #},
            #},
        },
        'health_alerts_enabled' => 1,
        'alerting' => {
            'critical' => {
                'modules' => {
                    'Twilio' => {
                        'sms' => {
                            'enabled' => 0,
                            'contacts' => [],
                            'groups' => ['admins'],
                            'every' => 10, # once per 10 alerts
                        },
                    },
                    'Email' => {
                        'localhost' => {
                            'enabled' => 0,
                            'contacts' => [],
                            'groups' => ['admins'],
                            'every' => 0, # 0 = every time,
                        },
                    },
                    'Log' => {
                        'to_file' => {
                            'enabled' => 1,
                            'every' => 0, # 0 = every time
                        },
                        'to_console' => {
                            'enabled' => 1,
                            'every' => 0, # 0 = every time
                        },
                        'to_data' => {
                            'enabled' => 1,
                            'handle'  => 'crate_local',
                            'every' => 0, # 0 = every time
                        }
                    },
                },
            },
            'warning' => {
                'modules' => {
                    'Twilio' => {
                        'sms' => {
                            'enabled' => 0,
                            'contacts' => [],
                            'groups' => ['admins'],
                            'every' => 10, # once per 10 alerts
                        }
                    },
                    'Email' => {
                        'localhost' => {
                            'enabled' => 0,
                            'contacts' => [],
                            'groups' => ['admins'],
                            'every' => 0, # 0 = every time,
                        }
                    },
                    'Log' => {
                        'to_file' => {
                            'enabled' => 1,
                        },
                        'to_console' => {
                            'enabled' => 1,
                        },
                        'to_data' => {
                            'enabled' => 1,
                        }
                    },
                },
            },
            'info' => {
                'modules' => {
                    'Log' => {
                        'to_file' => {
                            'enabled' => 1,
                        },
                        'to_console' => {
                            'enabled' => 1,
                        },
                        'to_data' => {
                            'enabled' => 1,
                        }
                    },
                },
            },
        },
    },
    # myEngine specific config
    # change this to the engine->{name} you entered above
    'sampleLogging' => {
        # some config values specific to the myEngine Modules
        'required_modules' => {
            'worker' => { # module to process enqued items
                'name'=>'Worker', # myEngine::Modules::{name}
                'method'=>'process', # method to use to process enqueued items
                'config'=>{} # config values are passed into the new constructor
            },  
            'selector' => { # module for selecting items to be enqueued
                'name'=>'Selector', # myEngine::Modules::{name}
                'method'=>'get', # method to use to gather items to enqueue
                'config'=>{} # config values are passed into the new constructor
            }
        },
        'something_custom' => {
            'ourcustom_var' => 'somevalue'
        }
    },
    # contacts
    'contacts' => {
        'rbush' => { # shortname - a-zA-Z0-9
            'name' => '',
            'email' => '',
            'mobile_number' => '', # for twilio we need +1
        }
    },
    # groups
    'groups' => {
        'admins' => ['rbush'],
    },             
}
