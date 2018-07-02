#!/usr/bin/perl -w
use lib ('/var/www/htdocs/cgi-bin/lib');
use DBI::Library;
use MySQL::Admin::GUI;
use MySQL::Admin::Settings;
use XML::RSS;
use HTML::Entities;
use LWP::UserAgent;
use strict;
use vars qw(@content $c $m_oDatabase $m_hrSettings );
require Exporter;
no warnings "uninitialized";
loadSettings("/var/www/html/cgi-bin/config/settings.pl");
*m_hrSettings = \$MySQL::Admin::Settings::m_hrSettings;
my ( $m_oDatabase, $m_dbh ) = new DBI::Library(
    {
        name     => $m_hrSettings->{database}{name},
        host     => $m_hrSettings->{database}{host},
        user     => $m_hrSettings->{database}{user},
        password => $m_hrSettings->{database}{password},
        style    => $m_hrSettings->{cgi}{style}
    }
);
my @o        = $m_oDatabase->fetch_array("select url from blogs where `right` = 0");
my $m_sStyle = $m_hrSettings->{cgi}{'style'};
push @content, '<table border="0" width="100%"><tr><td><table CELLSPACING="0" CELLPADDING="0"><tr><td height="1200" valign="top">';

foreach my $url (@o) {
    eval(
        q|
    my $rss = new XML::RSS;
    my $ua  = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->agent('lindnereirssreader');
    my $response = $ua->get($url);
    if ( $response->is_success ) {
        $c = $response->content;
        $rss->parse($c);
        my $item = $rss->{'items'}[0];
	unless ( utf8::is_utf8( $item->{'title'} ) ){
		    utf8::decode(  $item->{'title'}  );
		}
	if ( defined( $item->{'title'} ) && defined( $item->{'link'} ) ) {
            maxlength( 30, \$item->{'title'} );
            $item->{'title'} =~ s/(.{50}).+/$1/;
            push @content,
                  '<img src="/style/'
                . $m_sStyle
                . '/buttons/rss.png" alt="news"/><a href="',
                encode_entities( $item->{'link'} ),
                '" target="_blank" style="color:black;">', $item->{'title'},
                '</a><br/>';
        }
        my $item2 = $rss->{'items'}[1];
        unless ( utf8::is_utf8( $item2->{'title'} ) ){
		    utf8::decode(  $item2->{'title'}  );
		}
        if ( defined( $item2->{'title'} ) && defined( $item2->{'link'} ) ) {
            maxlength( 30, \$item2->{'title'} );
            $item->{'title'} =~ s/(.{50}).+/$1/;
            push @content,
                  '<img src="/style/'
                . $m_sStyle
                . '/buttons/rss.png" alt="news"/><a href="',
                encode_entities( $item2->{'link'} ),
                '" target="_blank" style="color:black;">', $item2->{'title'},
                '</a><br/>';
        }
    }
    |
    );
} ## end foreach my $url (@o)
push @content, "</td></tr></table><br/></td></tr></table><br/><br/>";
use Symbol;
my $fh = gensym();
open $fh, ">$m_hrSettings->{cgi}{bin}/config/feeds.bak" or die "$!";
print $fh @content;
close $fh;
rename "$m_hrSettings->{cgi}{bin}/config/feeds.bak", "$m_hrSettings->{cgi}{bin}/config/feeds.html"
  or die "makeFeeds.pl: $!";
1;
