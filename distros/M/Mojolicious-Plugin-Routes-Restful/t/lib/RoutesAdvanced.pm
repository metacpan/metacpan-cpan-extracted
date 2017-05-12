package RoutesAdvanced;
use Mojo::Base 'Mojolicious';

sub startup {
    my $self = shift;

    $self->plugin(
        "Routes::Restful",
        {
            CONFIG => {
                API => {
                    VERSION    => 'V_1',
                    RESOURCE_PREFIX => 'myapp',
                    PREFIX          => 'ipa'
                },
                NAMESPACES => [
                    'RoutesAdvanced::Controller',
                    'RoutesAdvanced::Controller::My',
                    'RoutesAdvanced::Controller::Ipa',
                    'RoutesAdvanced::Controller::Ipa::Projects',
                ]
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
                        VERBS => { RETRIEVE => 1, },
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
                                    RETRIEVE => 1
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
                                     RETRIEVE => 1
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
                                    RETRIEVE => 1,
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
                                    RETRIEVE => 1,
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

}

return 1;
