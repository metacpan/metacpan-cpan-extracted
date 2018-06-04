$VAR1 = {
          'database' => {
                          'name' => 'lze',
                          'CurrentUser' => 'lze',
                          'host' => 'localhost',
                          'user' => 'lze',
                          'password' => '',
                          'CurrentPass' => '',
                          'CurrentDb' => 'lze',
                          'CurrentHost' => 'localhost'
                        },
          'language' => 'en',
          'floodtime' => 10,
          'apacheconfig' => '/etc/apache2/sites-enabled/',
          'cgi' => {
                     'bin' => '/var/www/cgi-bin',
                     'serverName' => 'http://localhost',
                     'cookiePath' => '/',
                     'expires' => '+1y',
                     'style' => 'mysql',
                     'DocumentRoot' => '/var/www/html/',
                     'title' => 'MySQL::Admin'
                   },
          'actions' => '/var/www/cgi-bin/config/actions.pl',
          'size' => '16',
          'version' => '1.13',
          'admin' => {
                       'password' => 'testpass'
                     },
          'news' => {
                      'captcha' => 3,
                      'messages' => '5',
                      'right' => 5
                    },
          'config' => '/var/www/cgi-bin/config/settings.pl',
          'defaultAction' => 'ShowDatabases',
          'session' => '/var/www/cgi-bin/config/session.pl',
          'htmlright' => '2',
          'mod' => 'n',
          'translate' => '/var/www/cgi-bin/config/translate.pl',
          'saveTranslate' => '0',
          'files' => {
                       'owner' => 'lze',
                       'group' => 'lze',
                       'chmod' => '0755'
                     },
          'tree' => {
                      'links' => '/var/www/cgi-bin/config/links.pl',
                      'navigation' => '/var/www/cgi-bin/config/tree.pl'
                    },
          'uploads' => {
                         'chmod' => 438,
                         'maxlength' => '2100000000000000',
                         'path' => '/var/www/html//download',
                         'right' => 2,
                         'enabled' => 1
                       }
        };
$m_hrSettings =$VAR1;