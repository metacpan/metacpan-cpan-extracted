# NAME

Net::MyPeople::Bot::IPUpdator - Update server IP address setting for MyPeople Bot API. 

# VERSION

version 0.002

# SYNOPSIS

	use Net::MyPeople::Bot::IPUpdator;

	use Log::Log4perl qw(:easy);
	Log::Log4perl->easy_init($DEBUG); # You can see all logs.

	my $upd = Net::MyPeople::Bot::IPUpdator->new(daum_id=>$daumid,daum_pw=>$daumpw);
	#my $upd = Net::MyPeople::Bot::IPUpdator->new(daum_id=>$daumid,daum_pw=>$daumpw, myip_url=>['http://GET_MY_IPADDR_URL']);
	my $nowip = $upd->update($ip);
	if( $nowip ){ # OK
		print "IPADDR is updated to $nowip\n";
		print "OK\n";
	}
	else{
		print "FAIL\n";
	}

or

	$ mypeople_bot_ipupdate DAUMID DAUMPW IPADDR

# SEE ALSO

- [Net::MyPeople::Bot](http://search.cpan.org/perldoc?Net::MyPeople::Bot)
- MyPeople : [https://mypeople.daum.net/mypeople/web/main.do](https://mypeople.daum.net/mypeople/web/main.do)
- MyPeople Bot API Home : [http://dna.daum.net/apis/mypeople](http://dna.daum.net/apis/mypeople)
- MyPeople Bot API Buffer Service : [http://mabook.com:8080/](http://mabook.com:8080/)

# AUTHOR

khs <sng2nara@gmail.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by khs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
