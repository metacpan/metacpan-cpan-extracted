#!perl


use strict;
use Mojolicious::Command::generate::routes_restsful_just_routes;
use Cwd 'getcwd';
use File::Spec::Functions 'catdir';
use File::Temp 'tempdir';
use Mojolicious::Commands;
#
    
use Data::Dumper;

my $commands = Mojolicious::Commands->new;

my $o = Mojolicious::Command::generate::routes_restsful_just_routes->new;

$o->run('RoutesRestfulCode',{ 
            CONFIG => { Namespaces => ['RouteRestfulApp::Controller'] },
            PARENT => {
                project => {
                    #DEBUG => 1,
                    API   => {
                        #DEBUG => 1,
                        VERBS => {
                            CREATE   => 1,
                            UPDATE   => 1,
                            RETREIVE => 1,
                            REPLACE  => 1,
                            DELETE   => 1
                        },
                    },
                    INLINE => {
                        detail => {
                            #DEBUG => 1,
                            API   => { VERBS => { UPDATE   => 1,
                                                  RETREIVE => 1 } }
                        },
                        planning => {
                            #DEBUG => 1,
                            API => {
                               #DEBUG => 1,
                                RESOURCE => 'planning',
                                VERBS    => { UPDATE   => 1,
                                              RETREIVE => 1 }
                            }
                        },
                        longdetail => {
                            #DEBUG => 1,
                            API   => {
                               #DEBUG => 1,
                                VERBS => { UPDATE => 1 }
                            }
                        }
                    },
                    CHILD => {
                        user => {
                                                            #DEBUG => 1,
                            API => {
                                #DEBUG => 1,
                                VERBS => {
                                    CREATE   => 1,
                                    RETREIVE => 1,
                                    REPLACE  => 1,
                                    UPDATE   => 1,
                                    DELETE   => 1
                                }
                            }
                        },
                        contact => {
                                                            #DEBUG => 1,
                            API => {
                                #DEBUG => 1,
                                VERBS => {
                                    CREATE   => 1,
                                    REPLACE  => 1,
                                    RETREIVE => 1,
                                    UPDATE   => 1,
                                    DELETE   => 1
                                }
                            }
                        },
                    },
                },
            }
        });
        
        

  $o->run('RoutesRestfulAdvancedCode',{ 
            CONFIG => {
                API => {
                    VERSION    => 'V_1',
                    RESOURCE_PREFIX => 'myapp',
                    PRIFIX          => 'ipa'
                },
            },
            PARENT => {
                
                lab => {
                    NO_ID => 1,

                    #DEBUG => 1,

                },
                office => {
                    NO_ROOT => 1,
                    #DEBUG   => 1,
                },
                papers => {
                    API_ONLY => 1,

                    #DEBUG => 1,
                    API => 
                    {RESOURCE=>'paper',
                        CONTROLLER     => 'papers',
                        #DEBUG => 1,
                        VERBS => { RETREIVE => 1, },
                    },

                },
                project => {
                    ACTION     => 'process',
                    CONTROLLER => 'my-project',
                    VIA        => [ 'get', 'post' ],

                    #DEBUG => 1,
                    INLINE => {
                        detail => {

                            #DEBUG => 1,
                            ACTION     => 'project',
                            CONTROLLER => 'detail',
                            VIA        => [ 'get', 'post' ],
                            API        => {
                                #DEBUG => 1,
                                ACTION     => 'mydeatails',
                                RESOURCE  => 'my_details',
                                VERBS => {
                                    RETREIVE => 1
                                }
                            }
                        },
                        planning => {
                            #DEBUG    => 1,
                            API_ONLY => 1,
                            API      => {

                                #DEBUG => 1,
                                RESOURCE => 'planning',
                                VERBS    => {
                                      
                                     RETREIVE => 1
                                }
                            }
                        },
                    },
                    CHILD => {
                        user => {
                            ACTION     => 'my_projects',
                            CONTROLLER => 'my-user',
                            VIA        => [ 'delete', 'patch', 'put' ],

                            #DEBUG => 1,

                            API => {
                                CONTROLLER => 'projects-user',
                                RESOURCE   => 'view_users',
                               #DEBUG => 1,
                                VERBS => {
                                    RETREIVE => 1,
                                }
                            }
                        },
                        contact => {

                            #DEBUG => 1,
                            API_ONLY => 1,
                            API      => {

                                #DEBUG => 1,
                                VERBS => {
                                    CREATE   => 1,
                                    REPLACE  => 1,
                                    RETREIVE => 1,
                                    UPDATE   => 1,
                                    DELETE   => 1
                                }
                            }
                        },
                    },
                },
            }
        }
    );