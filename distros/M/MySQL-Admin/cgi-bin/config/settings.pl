$VAR1 = {
          'actions' => '/var/www/cgi-bin/config/actions.pl',
          'htmlright' => '2',
          'news' => {
                      'right' => 5,
                      'messages' => '5',
                      'captcha' => 3
                    },
          'tree' => {
                      'links' => '/var/www/cgi-bin/config/links.pl',
                      'navigation' => '/var/www/cgi-bin/config/tree.pl'
                    },
          'mod' => 'n',
          'uploads' => {
                         'path' => '/var/www/html//download',
                         'enabled' => 1,
                         'chmod' => 438,
                         'right' => 2,
                         'maxlength' => '2100000000000000'
                       },
          'translate' => '/var/www/cgi-bin/config/translate.pl',
          'floodtime' => 10,
          'admin' => {
                       'password' => 'testpass'
                     },
          'apacheconfig' => '/etc/apache2/sites-enabled/',
          'language' => 'en',
          'config' => '/var/www/cgi-bin/config/settings.pl',
          'defaultAction' => 'ShowDatabases',
          'files' => {
                       'group' => 'www-data',
                       'chmod' => '0755',
                       'owner' => 'www-data'
                     },
          'size' => '16',
          'cgi' => {
                     'expires' => '+1y',
                     'serverName' => 'http://localhost',
                     'style' => 'mysql',
                     'bin' => '/var/www/cgi-bin',
                     'cookiePath' => '/',
                     'DocumentRoot' => '/var/www/html/',
                     'title' => 'MySQL::Admin'
                   },
          'saveTranslate' => '0',
          'session' => '/var/www/cgi-bin/config/session.pl',
          'database' => {
                          'name' => 'lze',
                          'user' => 'lze',
                          'CurrentHost' => 'localhost',
                          'password' => '',
                          'CurrentDb' => 'lze',
                          'CurrentUser' => 'lze',
                          'host' => 'localhost',
                          'CurrentPass' => ''
                        },
          'version' => '1.14'
        };
$m_hrSettings =$VAR1;