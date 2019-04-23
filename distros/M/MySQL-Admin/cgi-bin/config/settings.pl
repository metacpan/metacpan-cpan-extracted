$VAR1 = {
          'session' => '/var/www/cgi-bin/config/session.pl',
          'language' => 'en',
          'actions' => '/var/www/cgi-bin/config/actions.pl',
          'config' => '/var/www/cgi-bin/config/settings.pl',
          'database' => {
                          'name' => 'lze',
                          'CurrentDb' => 'lze',
                          'CurrentUser' => 'lze',
                          'CurrentHost' => 'localhost',
                          'host' => 'localhost',
                          'CurrentPass' => '',
                          'password' => '',
                          'user' => 'lze'
                        },
          'translate' => '/var/www/cgi-bin/config/translate.pl',
          'files' => {
                       'group' => 'www-data',
                       'owner' => 'www-data',
                       'chmod' => '0755'
                     },
          'mod' => 0,
          'floodtime' => 10,
          'saveTranslate' => '0',
          'htmlright' => '2',
          'size' => '16',
          'uploads' => {
                         'right' => 2,
                         'maxlength' => '2100000000000000',
                         'chmod' => 438,
                         'path' => '/var/www/html//download',
                         'enabled' => 1
                       },
          'apacheconfig' => '/etc/apache2/sites-enabled/',
          'cgi' => {
                     'serverName' => 'http://localhost',
                     'expires' => '+1y',
                     'title' => 'MySQL::Admin',
                     'style' => 'mysql',
                     'cookiePath' => '/',
                     'bin' => '/var/www/cgi-bin',
                     'DocumentRoot' => '/var/www/html/'
                   },
          'news' => {
                      'captcha' => 3,
                      'messages' => '5',
                      'right' => 5
                    },
          'version' => '1.14',
          'tree' => {
                      'navigation' => '/var/www/cgi-bin/config/tree.pl',
                      'links' => '/var/www/cgi-bin/config/links.pl'
                    },
          'defaultAction' => 'ShowDatabases',
          'admin' => {
                       'password' => 'testpass'
                     }
        };
$m_hrSettings =$VAR1;