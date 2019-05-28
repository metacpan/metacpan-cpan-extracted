#!/usr/bin/perl
use warnings;
use strict;
no warnings 'redefine';
use vars qw(@menuNavi $m_hrS %conf $m_oDb $m_sSid $m_sUser $m_nRight $m_hrLng);
use lib qw(%PATH%lib);
use MySQL::Admin qw(:all);
use DBI::Library::Database qw(:all);
use MySQL::Admin::Settings;
use URI::Escape;
print header(
    -type    => 'text/xml',
    -charset => 'UTF-8',
    -access_control_allow_origin => '*'
);
use CGI qw(param header);
# loadSettings('config/settings.pl');
init('%PATH%config/settings.pl');
*m_hrLng = \$MySQL::Admin::Translate::lang;
$m_hrS = $MySQL::Admin::m_hrSettings;
%conf = (
name => $m_hrS->{database}{name},
host => $m_hrS->{database}{host},
user => $m_hrS->{database}{user},
password => $m_hrS->{database}{password},
);

$m_oDb = new DBI::Library::Database();
$m_oDb->initDB(\%conf);
$m_sSid = cookie( -name => 'sid' );
$m_sSid = defined $m_sSid ? $m_sSid : '123';
$m_sUser = $m_oDb->getName($m_sSid);
$m_sUser = defined $m_sUser ? $m_sUser : 'guest';
$m_nRight = $m_oDb->userright($m_sUser);
$m_nRight = defined $m_nRight ? $m_nRight: 0;
@menuNavi = $m_oDb->fetch_AoH("select * from $m_hrS->{database}{name}.mainmenu where `right` <= $m_nRight order by position");
print q(<?xml version="1.0" encoding="UTF-8"?><actions>);
print uri_escape("javascript:requestURI('cgi-bin/mysql.pl?action=EditFile&name='+cAction,'EditFile','EditFile')");
for(my $i = 0; $i <= $#menuNavi;$i++){
	$menuNavi[$i]->{title} = translate($menuNavi[$i]->{title});
	SWITCH:{
	  if($menuNavi[$i]->{output} eq 'requestURI'){
	  print qq(<action position="$menuNavi[$i]->{menu}" output="$menuNavi[$i]->{output}">
		  <title>$menuNavi[$i]->{title}</title>
		  <xml>cgi-bin/mysql.pl?action=$menuNavi[$i]->{action}</xml>
		  <out>content</out>
		  <id>$menuNavi[$i]->{action}</id>
		  <text>$menuNavi[$i]->{title}</text>
		  </action>);
		  last SWITCH;
	  }
	  if($menuNavi[$i]->{output} eq 'javascript'){
	  print qq(<action position="$menuNavi[$i]->{menu}" output="$menuNavi[$i]->{output}">
		  <title>$menuNavi[$i]->{title}</title>
		  <javascript>).uri_escape($menuNavi[$i]->{action}).qq(</javascript>
		  <out>content</out>
		  <id>$menuNavi[$i]->{id}</id>
		  <text>$menuNavi[$i]->{title}</text>
		  </action>);
		  last SWITCH;
	  }
	  if($menuNavi[$i]->{output} eq 'loadPage'){
	  print qq(<action position="$menuNavi[$i]->{menu}" output="$menuNavi[$i]->{output}">
		  <title>$menuNavi[$i]->{title}</title>
		  <javascript>cgi-bin/mysql.pl?action=$menuNavi[$i]->{action}</javascript>
		  <out>content</out>
		  <id>$menuNavi[$i]->{action}</id>
		  <text>$menuNavi[$i]->{title}</text>
		  </action>);
		  last SWITCH;
	  }
	}
}
print '</actions>';
