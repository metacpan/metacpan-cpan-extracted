use inc::Module::Install;

RTx('RT-Authen-ExternalAuth');

feature 'SSL LDAP Connections' =>
    -default => 0,
    recommends('Net::SSLeay' => 0),
    ;

feature 'External LDAP Sources' =>
    -default => 1,
    recommends('Net::LDAP' => 0),
    ;

feature 'External DBI Sources' =>
    -default => 1,
    recommends('DBI' => 0),
    ;

feature 'SSO Cookie Sources' =>
    -default => 1,
    recommends('CGI::Cookie' => 0),
    ;

author_tests('xt');

rt_too_new '4.4.0';

&auto_install();

repository 'https://github.com/bestpractical/rt-authen-externalauth';

sign;
&WriteAll;
