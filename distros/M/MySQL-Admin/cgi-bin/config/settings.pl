$VAR1 = {
          'htmlright' => '2',
          'translate' => '/var/www/cgi-bin/config/translate.pl',
          'config' => '/var/www/cgi-bin/config/settings.pl',
          'tree' => {
                      'navigation' => '/var/www/cgi-bin/config/tree.pl',
                      'links' => '/var/www/cgi-bin/config/links.pl'
                    },
          'database' => {
                          'CurrentDb' => 'lze',
                          'user' => 'lze',
                          'host' => 'localhost',
                          'CurrentUser' => 'lze',
                          'CurrentPass' => '',
                          'name' => 'lze',
                          'CurrentHost' => 'localhost',
                          'password' => ''
                        },
          'actions' => '/var/www/cgi-bin/config/actions.pl',
          'cgi' => {
                     'expires' => '+1y',
                     'style' => 'mysql',
                     'title' => 'MySQL::Admin',
                     'cookiePath' => '/',
                     'DocumentRoot' => '/var/www/html/',
                     'bin' => '/var/www/cgi-bin',
                     'serverName' => 'http://localhost'
                   },
          'version' => '1.14',
          'uploads' => {
                         'enabled' => 1,
                         'right' => 2,
                         'chmod' => 438,
                         'path' => '/var/www/html//download',
                         'maxlength' => '2100000000000000'
                       },
          'defaultAction' => 'ShowDatabases',
          'apacheconfig' => '/etc/apache2/sites-enabled/',
          'size' => '16',
          'floodtime' => 10,
          'news' => {
                      'messages' => '5',
                      'right' => 5,
                      'captcha' => 3
                    },
          'language' => 'en',
          'session' => '/var/www/cgi-bin/config/session.pl',
          'saveTranslate' => '0',
          'admin' => {
                       'password' => 'testpass'
                     },
          'files' => {
                       'group' => 'lze',
                       'chmod' => '0755',
                       'owner' => 'lze'
                     },
          'mod' => 'n'
        };
$m_hrSettings =$VAR1;