$VAR1 = {
    'htmlright' => 2,
    'actions'   => 'cgi-bin/config/actions.pl',
    'tree'      => {
        'navigation' => 'cgi-bin/config/tree.pl',
        'links'      => 'cgi-bin/config/links.pl'
    },
    'defaultAction' => 'news',
    'files'         => {
        'owner' => 'linse',
        'group' => 'users',
        'chmod' => '0.62'
    },
    'size'    => 22,
    'uploads' => {
        'maxlength' => 2003153,
        'path'      => 'htdocs/downloads/',
        'chmod'     => 420,
        'enabled'   => 1
    },
    'session'     => 'cgi-bin/config/session.pl',
    'scriptAlias' => 'perl',
    'admin'       => {
        'firstname' => 'Firstname',
        'email'     => 'your@email.org',
        'street'    => 'example 33',
        'name'      => 'Name',
        'town'      => 'Berlin'
    },
    'language' => 'en',
    'version'  => '0.62',
    'cgi'      => {
        'bin'          => 'cgi-bin/',
        'style'        => 'mysql',
        'serverName'   => 'http://localhost',
        'cookiePath'   => '/',
        'title'        => 'MySql::Admin',
        'alias'        => 'perl',
        'DocumentRoot' => 'htdocs/',
        'expires'      => '+1y'
    },
    'database' => {
        'password' => 'keinz',
        'user'     => 'root',
        'name'     => 'LZE',
        'host'     => 'localhost'
    },
    'sidebar' => {
        'left'  => 1,
        'right' => 1
    },
    'translate' => 'cgi-bin/config/translate.pl',
    'config'    => 'cgi-bin/config/settings.pl',
    'news'      => {
        'maxlength' => 5000,
        'messages'  => 10
    }
};
$m_hrSettings = $VAR1;
