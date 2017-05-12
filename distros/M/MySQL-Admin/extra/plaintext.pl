#!/usr/bin/perl
use warnings;
use strict;
no warnings 'redefine';
use vars qw($bis $length $start $xml $xsl $m_hrS %conf $m_oDb $m_sSid $m_sUser $m_nRight);
use lib qw(lib);
use CGI qw(-compile :all);
use DBI::Library::Database qw(:all);
use MySQL::Admin::Settings;
use MySQL::Admin::GUI;
loadSettings('%PATH%/config/settings.pl');
*m_hrS = \$MySQL::Admin::Settings::m_hrSettings;
%conf = (
         name     => $m_hrS->{database}{name},
         host     => $m_hrS->{database}{host},
         user     => $m_hrS->{database}{user},
         password => $m_hrS->{database}{password},
        );
*m_hrS = \$MySQL::Admin::Settings::m_hrSettings;
$m_oDb = new DBI::Library::Database();
$m_oDb->initDB(\%conf);
$m_oDb->serverName($m_hrS->{cgi}{serverName});
$length = $m_oDb->tableLength('news');
$start  = param('start');
$start  = $start =~ /(\d+)/ ? $1 : 0;
$start  = ($start >= 0 and $start < $length) ? $start : 0;
$xml    = $m_oDb->rss('news', $start, "$m_hrS->{cgi}{title} rss feed");
utf8::encode($xml);
$xsl = openFile("cgi-bin/config/feed.xsl");
print header(
             -type                        => 'text/html',
             -access_control_allow_origin => '*',
             -charset                     => 'UTF-8'
            );
$bis = $start + 10;
print qq{
<html>
<head>
<title>$m_hrS->{cgi}{title}</title>
<script>location.href="$m_hrS->{cgi}{serverName}?cgi-bin/mysql.pl?von=$start&bis=$bis&action=news&links_pro_page=10"</script>
</head>
<body>
};

for (my ($i, $j) = 0 ,0 ; $i < $length / 10 ; $i++, $j += 10) {
    print qq|<a href="plaintext.pl?start=$j">Page $i</a>|;
}
use XML::XSLT;
my $xslt = XML::XSLT->new($xsl);
$xslt->transform($xml);
print $xslt->toString;
$xslt->dispose();
print '</body></html>';
