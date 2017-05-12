use Test::More tests => 20;
BEGIN { use_ok('Net::Yadis::Discovery') };

my $disc = Net::Yadis::Discovery->new();

foreach (<DATA>) {
    my ($url,$result) = split(/[\t\n]/,$_);
    next if ($result =~ /Not_corresponding$/);
    $result = undef if ($result =~ /^(|EOF|None)$/);
    my ($final,$content);
    my %header;
    $disc->_get_contents($url,\$final,\$content,\%header);
    my $xrd = $header{'x-yadis-location'} || $header{'x-xrds-location'};
    is($xrd,$result);
}

__END__
http://openidenabled.com/yadis-test/html/test-0.html	found
http://openidenabled.com/yadis-test/html/test-1.html	found
http://openidenabled.com/yadis-test/html/test-2.html	found
http://openidenabled.com/yadis-test/html/test-3.html	found
http://openidenabled.com/yadis-test/html/test-4.html	found
http://openidenabled.com/yadis-test/html/test-5.html	found
http://openidenabled.com/yadis-test/html/test-6.html	found
http://openidenabled.com/yadis-test/html/test-7.html	&
http://openidenabled.com/yadis-test/html/test-8.html	found
http://openidenabled.com/yadis-test/html/test-9.html	found
http://openidenabled.com/yadis-test/html/test-10.html	/
http://openidenabled.com/yadis-test/html/test-11.html	
http://openidenabled.com/yadis-test/html/test-12.html	EOF
http://openidenabled.com/yadis-test/html/test-13.html	None
http://openidenabled.com/yadis-test/html/test-14.html	EOF-Not_corresponding
http://openidenabled.com/yadis-test/html/test-15.html	EOF-Not_corresponding
http://openidenabled.com/yadis-test/html/test-16.html	None
http://openidenabled.com/yadis-test/html/test-17.html	None-Not_corresponding
http://openidenabled.com/yadis-test/html/test-18.html	None
http://openidenabled.com/yadis-test/html/test-19.html	None
http://openidenabled.com/yadis-test/html/test-20.html	None
http://openidenabled.com/yadis-test/html/test-21.html	None
http://openidenabled.com/yadis-test/html/test-22.html	None-Not_corresponding