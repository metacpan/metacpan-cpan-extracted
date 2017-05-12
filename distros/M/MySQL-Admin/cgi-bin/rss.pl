#!/usr/bin/perl
use warnings;
use strict;
no warnings 'redefine';
use vars qw( $m_hrS %conf $m_oDb $m_sSid $m_sUser $m_nRight);
use lib qw(%PATH%lib);
use CGI qw(-compile :all);
use DBI::Library::Database qw(:all);
use MySQL::Admin::Settings;
loadSettings('%PATH%config/settings.pl');
*m_hrS= \$MySQL::Admin::Settings::m_hrSettings;
%conf = (
  name => $m_hrS->{database}{name},
  host => $m_hrS->{database}{host},
  user => $m_hrS->{database}{user},
  password => $m_hrS->{database}{password},
);
*m_hrS = \$MySQL::Admin::Settings::m_hrSettings;
$m_oDb = new DBI::Library::Database();
$m_oDb->initDB(\%conf);
$m_oDb->serverName($m_hrS->{cgi}{serverName});
print header(
    -type    => 'text/html',
    -access_control_allow_origin => '*',
    -charset => 'UTF-8'
);
print $m_oDb->rss('news', 0,"$m_hrS->{cgi}{title} rss feed");