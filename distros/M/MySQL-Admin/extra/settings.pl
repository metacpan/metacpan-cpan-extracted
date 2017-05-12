$VAR1 = {
         'actions' => 'config/actions.pl',
         'session' => 'config/session.pl',
         'admin'   => {
                     'name'     => 'Admin',
                     'email'    => 'your@email.org',
                     'password' => 'testpass'
                    },
         'language'     => 'de',
         'config'       => 'config/settings.pl',
         'version'      => '0.82',
         'apacheconfig' => 'n',
         'cgi'          => {
                   'cookiePath'   => '/',
                   'bin'          => './',
                   'expires'      => '+1y',
                   'style'        => 'mysql',
                   'serverName'   => 'localhost',
                   'DocumentRoot' => '../',
                   'title'        => 'MySQL::Admin'
                  },
         'files' => {
                     'owner' => 'lze',
                     'chmod' => '0755',
                     'group' => 'lze'
                    },
         'login'   => 0,
         'mod'     => 'n',
         'uploads' => {
                       'path'      => '../download',
                       'chmod'     => 438,
                       'maxlength' => 21000000
                      },
         'translate' => 'config/translate.pl',
         'floodtime' => 10,
         'database'  => {
                        'CurrentPass' => 'keinz',
                        'user'        => 'root',
                        'name'        => 'LZE',
                        'password'    => 'keinz',
                        'CurrentDb'   => 'LZE',
                        'CurrentHost' => 'localhost',
                        'CurrentUser' => 'root',
                        'host'        => 'localhost'
                       }
        };
$m_hrSettings = $VAR1;
