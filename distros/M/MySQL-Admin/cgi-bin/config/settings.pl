$VAR1 = {
          'version' => '1.15',
          'files' => {
                       'owner' => 'www-data',
                       'chmod' => '0755',
                       'group' => 'www-data'
                     },
          'database' => {
                          'host' => 'localhost',
                          'CurrentPass' => '',
                          'CurrentHost' => 'localhost',
                          'CurrentUser' => 'lze',
                          'password' => '',
                          'user' => 'lze',
                          'CurrentDb' => 'lze',
                          'name' => 'lze'
                        },
          'htmlright' => '2',
          'mod' => 'n',
          'tree' => {
                      'navigation' => '/var/www/cgi-bin/config/tree.pl',
                      'links' => '/var/www/cgi-bin/config/links.pl'
                    },
          'language' => 'en',
          'actions' => '/var/www/cgi-bin/config/actions.pl',
          'uploads' => {
                         'right' => 2,
                         'path' => '/var/www/html//download',
                         'enabled' => 1,
                         'chmod' => 438,
                         'maxlength' => '2100000000000000'
                       },
          'saveTranslate' => '0',
          'session' => '/var/www/cgi-bin/config/session.pl',
          'floodtime' => 10,
          'cgi' => {
                     'bin' => '/var/www/cgi-bin',
                     'serverName' => 'http://localhost',
                     'DocumentRoot' => '/var/www/html/',
                     'cookiePath' => '/',
                     'expires' => '+1y',
                     'style' => 'mysql',
                     'title' => 'MySQL::Admin'
                   },
          'size' => '16',
          'admin' => {
                       'password' => 'testpass'
                     },
          'defaultAction' => 'ShowDatabases',
          'apacheconfig' => '/etc/apache2/sites-enabled/',
          'translate' => '/var/www/cgi-bin/config/translate.pl',
          'news' => {
                      'right' => 5,
                      'messages' => '5',
                      'captcha' => 3
                    },
          'config' => '/var/www/cgi-bin/config/settings.pl'
        };
$m_hrSettings =$VAR1;