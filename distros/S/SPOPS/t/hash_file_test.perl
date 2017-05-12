$data = {
          'smtp_host' => '127.0.0.1',
          'crypt_password' => 1,
          'module' => {
                        '' => {
                                'redir' => 'basicpage'
                              },
                        '_notfound_' => {
                                          'redir' => 'basicpage'
                                        },
                        'default' => {
                                       'method' => 'handler',
                                       'conductor' => 'main',
                                       'template' => 'Interact::Template::Toolkit'
                                     }
                      },
          'package_list' => 'package_list.dat',
          'default_error_handler' => 'Interact::Error::System',
          'template_ext' => 'tmpl',
          'system_alias' => {
                              'SPOPS::Secure' => [
                                                   'secure'
                                                 ],
                              'Interact::Auth' => [
                                                    'auth',
                                                    'auth_user',
                                                    'auth_group'
                                                  ],
                              'Interact::Error::Main' => [
                                                           'error_handler'
                                                         ],
                              'SPOPS::Impl::SecurityObj' => [
                                                              'security_object',
                                                              'object_security',
                                                              'security'
                                                            ],
                              'Interact::Handler::Component' => [
                                                                  'component'
                                                                ],
                              'Interact::Error' => [
                                                     'error'
                                                   ],
                              'Interact::Package' => [
                                                       'package'
                                                     ],
                              'Interact::Cookies' => [
                                                       'cookies'
                                                     ],
                              'Interact::Session::MySQL' => [
                                                              'session'
                                                            ]
                            },
          'default_objects' => {
                                 'site_admin_group' => 3,
                                 'theme' => 4,
                                 'group' => 2
                               },
          'admin_email' => 'chris@cwinters.com',
          'conductor' => {
                           'main' => {
                                       'method' => 'handler',
                                       'class' => 'Interact::UI::Main'
                                     }
                         },
          'db_info' => {
                         'username' => 'foobar',
                         'db_owner' => '',
                         'password' => '',
                         'dsn' => 'DBI:mysql:database=mysql',
                         'db_name' => 'interact'
                       },
          'replication_location' => 'devel',
          'cache' => {
                       'data' => {
                                   'use_ipc' => '0',
                                   'max_size' => 2000000,
                                   'SPOPS' => '0',
                                   'use' => '0',
                                   'expire' => 600,
                                   'class' => 'Interact::Cache::File'
                                 },
                       'ipc' => {
                                  'key' => 'CMWC',
                                  'class' => 'Interact::Cache::IPC'
                                }
                     },
          'SPOPS' => {
                       '_meta' => {
                                    'parse_into_hash' => [
                                                           'field',
                                                           'no_insert',
                                                           'no_update',
                                                           'skip_undef'
                                                         ]
                                  }
                     },
          'error_object_class' => 'Interact::ErrorObject',
          'stash_class' => 'Interact::Intranet',
          'session_class' => 'Apache::Session::MySQL',
          'refresh_time' => 1200,
          'request_class' => 'Interact::Request',
          'dir' => {
                     'log' => '$BASE/logs',
                     'image' => '$HTML/images',
                     'mail' => '$BASE/mail',
                     'pod' => '/home/httpd/interact/doc',
                     'upload' => '$BASE/uploads',
                     'module' => '$BASE/modules',
                     'help' => '$HTML/help',
                     'error' => '$BASE/error',
                     'package' => [
                                    '/home/httpd/interact/pkg'
                                  ],
                     'cache' => '$BASE/cache',
                     'overflow' => '$HTML/overflow',
                     'html' => '$BASE/html',
                     'config' => '$BASE/conf',
                     'download' => '$HTML/downloads',
                     'data' => '$BASE/data',
                     'base' => undef,
                     'template' => '$BASE/templates'
                   },
          'SPOPS_config_class' => 'SPOPS::Configure::DBI'
        };
