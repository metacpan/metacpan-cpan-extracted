$VAR1 = {
          'saveTranslate' => '0',
          'cgi' => {
                     'title' => 'MySQL::Admin',
                     'DocumentRoot' => '/var/www/htdocs/',
                     'expires' => '+1y',
                     'bin' => '/var/www/cgi-bin',
                     'style' => 'mysql',
                     'serverName' => 'http://localhost',
                     'cookiePath' => '/'
                   },
          'mod' => 'n',
          'database' => {
                          'CurrentPass' => '',
                          'host' => 'localhost',
                          'user' => 'root',
                          'CurrentUser' => 'root',
                          'CurrentHost' => 'localhost',
                          'password' => '',
                          'name' => 'MySQLAdmin',
                          'CurrentDb' => 'MySQLAdmin'
                        },
          'language' => 'en',
          'size' => '16',
          'translate' => '/var/www/cgi-bin/config/translate.pl',
          'actions' => '/var/www/cgi-bin/config/actions.pl',
          'admin' => {
                       'password' => 'testpass'
                     },
          'htmlright' => '2',
          'floodtime' => 10,
          'defaultAction' => 'ShowDatabases',
          'tree' => {
                      'navigation' => '/var/www/cgi-bin/config/tree.pl',
                      'links' => '/var/www/cgi-bin/config/links.pl'
                    },
          'version' => '1.12',
          'config' => '/var/www/cgi-bin/config/settings.pl',
          'uploads' => {
                         'path' => '/var/www/htdocs//download',
                         'right' => 2,
                         'enabled' => 1,
                         'chmod' => 438,
                         'maxlength' => '2100000000000000'
                       },
          'files' => {
                       'chmod' => '0755',
                       'owner' => 'lze',
                       'group' => 'lze'
                     },
          'session' => '/var/www/cgi-bin/config/session.pl',
          'news' => {
                      'captcha' => 3,
                      'messages' => '5',
                      'right' => 5
                    },
          'apacheconfig' => '/etc/apache2/sites-enabled/'
        };
$m_hrSettings =$VAR1;