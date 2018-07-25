$VAR1 = {
          'files' => {
                       'owner' => 'www-data',
                       'group' => 'www-data',
                       'chmod' => '0755'
                     },
          'admin' => {
                       'password' => 'testpass'
                     },
          'database' => {
                          'password' => '',
                          'CurrentHost' => 'localhost',
                          'CurrentPass' => '',
                          'name' => 'lze',
                          'host' => 'localhost',
                          'CurrentUser' => 'lze',
                          'user' => 'lze',
                          'CurrentDb' => 'lze'
                        },
          'config' => '/var/www/cgi-bin/config/settings.pl',
          'tree' => {
                      'navigation' => '/var/www/cgi-bin/config/tree.pl',
                      'links' => '/var/www/cgi-bin/config/links.pl'
                    },
          'cgi' => {
                     'cookiePath' => '/',
                     'style' => 'mysql',
                     'DocumentRoot' => '/var/www/html/',
                     'serverName' => 'http://localhost',
                     'title' => 'MySQL::Admin',
                     'expires' => '+1y',
                     'bin' => '/var/www/cgi-bin'
                   },
          'saveTranslate' => '0',
          'uploads' => {
                         'maxlength' => '2100000000000000',
                         'path' => '/var/www/html//download',
                         'right' => 2,
                         'chmod' => 438,
                         'enabled' => 1
                       },
          'apacheconfig' => '/etc/apache2/sites-enabled/',
          'floodtime' => 10,
          'language' => 'en',
          'size' => '16',
          'translate' => '/var/www/cgi-bin/config/translate.pl',
          'session' => '/var/www/cgi-bin/config/session.pl',
          'version' => '1.14',
          'htmlright' => '2',
          'actions' => '/var/www/cgi-bin/config/actions.pl',
          'defaultAction' => 'ShowDatabases',
          'mod' => 'n',
          'news' => {
                      'right' => 5,
                      'messages' => '5',
                      'captcha' => 3
                    }
        };
$m_hrSettings =$VAR1;