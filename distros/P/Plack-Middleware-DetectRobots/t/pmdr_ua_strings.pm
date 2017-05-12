
package pmdr_ua_strings;

sub browser_ua {
	return (
		'Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/30.0.1599.17 Safari/537.36',
		'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.1 (KHTML, like Gecko) Chrome/22.0.1207.1 Safari/537.1',
		'Mozilla/5.0 (X11; Linux x86_64; rv:18.0) Gecko/20100101 Firefox/18.0',
		'Mozilla/5.0 (X11; Linux x86_64; rv:26.0) Gecko/20100101 Firefox/26.0',
		'Opera/3.7 (Windows 2000 2.3; )',
		'Opera/9.80 (Windows NT 6.0) Presto/2.12.388 Version/12.14',
		'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; Maxthon; .NET CLR 2.0.50727)',
		'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 2.0.50727; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729)',
		'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; Trident/6.0)',
		'Mozilla/5.0 (iPad; CPU OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A5355d Safari/8536.25',
	);
}

sub common_bot_ua {
	return (
		'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
		'Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)',
		'Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)',
		'Baiduspider+(+http://www.baidu.com/search/spider.htm)',
		'Baiduspider-image+(+http://www.baidu.com/search/spider.htm)',
		'Mozilla/5.0 (compatible; Baiduspider/2.0; +http://www.baidu.com/search/spider.html)',
		'Mozilla/2.0 (compatible; Ask Jeeves/Teoma)',
	);
}

sub other_bot_ua {
	return (
		'Mozilla/5.0 (compatible; YandexAntivirus/2.0; +http://yandex.com/bots)',
		'Mozilla/5.0 (compatible; YandexDirect/3.0; +http://yandex.com/bots)',
		'Sogou web spider/4.0(+http://www.sogou.com/docs/help/webmasters.htm#07)',
		'msnbot/1.1 (+http://search.msn.com/msnbot.htm)',
	);
}

1;
