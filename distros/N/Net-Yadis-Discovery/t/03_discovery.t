use Test::More tests => 15;
BEGIN { use_ok('Net::Yadis::Discovery') };

my $disc = Net::Yadis::Discovery->new();

foreach (<DATA>) {
    my ($url,$final,$xrd) = split(/[\t\n]/,$_);
    next if ($xrd =~ /xrds_html$/);            # Not correspond for Yadis document's header is text/html case.
    $disc->discover($url);
    my $identity_url = $disc->identity_url;
    my $xrd_url = $disc->xrd_url;
    $identity_url =~ s/www\.openidenabled\.com\/resources/openidenabled.com/;
    $xrd_url =~ s/www\.openidenabled\.com\/resources/openidenabled.com/;
    is($identity_url,$final);
    is($xrd_url,$xrd);
}

__END__
http://openidenabled.com/yadis-test/discover/equiv	http://openidenabled.com/yadis-test/discover/equiv	http://openidenabled.com/yadis-test/discover/xrds
http://openidenabled.com/yadis-test/discover/header	http://openidenabled.com/yadis-test/discover/header	http://openidenabled.com/yadis-test/discover/xrds
http://openidenabled.com/yadis-test/discover/xrds	http://openidenabled.com/yadis-test/discover/xrds	http://openidenabled.com/yadis-test/discover/xrds
http://openidenabled.com/yadis-test/discover/xrds_html	http://openidenabled.com/yadis-test/discover/xrds_html	http://openidenabled.com/yadis-test/discover/xrds_html
http://openidenabled.com/yadis-test/discover/redir_equiv	http://openidenabled.com/yadis-test/discover/equiv	http://openidenabled.com/yadis-test/discover/xrds
http://openidenabled.com/yadis-test/discover/redir_header	http://openidenabled.com/yadis-test/discover/header	http://openidenabled.com/yadis-test/discover/xrds
http://openidenabled.com/yadis-test/discover/redir_xrds	http://openidenabled.com/yadis-test/discover/xrds	http://openidenabled.com/yadis-test/discover/xrds
http://openidenabled.com/yadis-test/discover/redir_xrds_html	http://openidenabled.com/yadis-test/discover/xrds_html	http://openidenabled.com/yadis-test/discover/xrds_html
http://openidenabled.com/yadis-test/discover/redir_redir_equiv	http://openidenabled.com/yadis-test/discover/equiv	http://openidenabled.com/yadis-test/discover/xrds