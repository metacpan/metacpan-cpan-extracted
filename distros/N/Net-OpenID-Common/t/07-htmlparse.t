#!/usr/bin/perl

use warnings;
use strict;
use Test::More;
use Net::OpenID::Common;

sub html_is { is_deeply(OpenID::util::html_extract_linkmetas(shift),@_) }

html_is('plain text hello world',{},'plain') ;
html_is('<body><link rel="boo" href="not real"></body>',{},'body');
html_is('<link rel=boo href=real>',{link =>[{rel=>'boo',href=>'real'}]},'nohead');

my $p1 = 'https://api.screenname.aol.com/auth/openidServer';
my $doc1 = <<END ;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd"><html><head><link rel="openid.server" href="$p1"/><link rel="openid2.provider" href="$p1"/><meta http-equiv="Content-Type" content="text/html; charset=UTF-8"><title>AOL OpenId</title><meta http-equiv="refresh" content="0;url=https://api.screenname.aol.com/auth/openid/name/test"></head><body>If not redirected automatically, please click <a href="https://api.screenname.aol.com/auth/openid/name/test">here</a> to continue</body></html>
END
my $r1 = 
{
link => [
 {rel=>"openid.server", href=>"$p1",'/'=>'/'},
 {rel=>"openid2.provider", href=>"$p1",'/'=>'/'},
],
meta => [
 {'http-equiv'=>"Content-Type", content=>"text/html; charset=UTF-8"},
 {'http-equiv'=>"refresh", content=>"0;url=https://api.screenname.aol.com/auth/openid/name/test"},
]
};
my $r0;
html_is($doc1,$r1,'basic') ;
done_testing();

__END__

my $uri2 = 'http://openid.example.com/everything_in_comments';
addf_uri($uri2,content => <<END );
<html><head><link rel="openid.server"   href="http://www.livejournal.com/misc/openid.bml" />
<link rel="openid.delegate" href="http://openid1.net/delegate" />
<link rel="openid2.provider" href="http://www.livejournal.com/misc/openid.bml" />
<link rel="openid2.local_id" href="http://openid2.net/delegate" />
<meta name="foaf:maker" content="foaf:mbox_sha1sum '4caa1d6f6203d21705a00a7aca86203e82a9cf7a'"/>
<link rel="meta" type="application/rdf+xml" title="FOAF"
      href="http://brad.livejournal.com/data/foaf" />
<link rel="alternate" type="application/rss+xml" title="RSS"
      href="http://www.livejournal.com/~brad/data/rss" />
<link rel="alternate" type="application/atom+xml" title="Atom" 
      href="http://www.livejournal.com/~brad/data/atom" /></head><body>Bite me</body></html>
END
is_deeply($csr->_find_semantic_info($uri2),
{'openid.server'=>'http://www.livejournal.com/misc/openid.bml',
 'openid.delegate'=>'http://openid1.net/delegate',
 'openid2.provider'=>'http://www.livejournal.com/misc/openid.bml',
 'openid2.local_id'=>'http://openid2.net/delegate',
 'foaf.maker'=> "foaf:mbox_sha1sum '4caa1d6f6203d21705a00a7aca86203e82a9cf7a'",
 'foaf'=>"http://brad.livejournal.com/data/foaf",
 'rss'=>"http://www.livejournal.com/~brad/data/rss",
 'atom'=>"http://www.livejournal.com/~brad/data/atom",
},'everything from consumer.pm comments' );


my $uri3 = 'http://openid.example.com/cdata_crap';
addf_uri($uri3,content => <<END );
<html><head>
<link rel="openid.server"   href="http://www.livejournal.com/misc/openid.bml" />
<link rel="openid.delegate" href="http://openid1.net/delegate" />
<script type="text/javascript">//<![CDATA[
var toss = '
<link rel="openid2.provider" href="http://www.livejournal.com/misc/openid2.bml" />
<link rel="openid2.local_id" href="http://openid2.net/delegate" />
<meta name="foaf:maker" content="foaf:mbox_sha1sum \'4caa1d6f6203d21705a00a7aca86203e82a9cf7a\'"/>
'; // ]]>
</script>
<!-- <!---- comment me out
<link rel="meta" type="application/rdf+xml" title="FOAF"
     href="http://brad.livejournal.com/data/foaf" /> 
oh and comments do not nest so the next one is real -->
<link rel="alternate" type="application/rss+xml" title="RSS"
      href="http://www.livejournal.com/~brad/data/rss" /> <!-- -->
<style type="text/css"><![CDATA[
hr { visibility:none msg:make sure the first CDATA is not grabbing too much }
]]></style>
<link rel="alternate" type="application/atom+xml" title="Atom" 
      href="http://www.livejournal.com/~brad/data/atom" /></head><body>bitez moi</body></html>
END
is_deeply($csr->_find_semantic_info($uri3),
{'openid.server'=>'http://www.livejournal.com/misc/openid.bml',
 'openid.delegate'=>'http://openid1.net/delegate',
 'rss'=>"http://www.livejournal.com/~brad/data/rss",
 'atom'=>"http://www.livejournal.com/~brad/data/atom",
},'CDATA/comment silliness' );


my $uri4 = 'http://openid.aol.com/oldstyle';
addf_uri($uri4,content => <<END );
<HTML><HEAD>
<LINK REL=xopenid.serverx HREF="not it" />
<LINK REL=openid.delegate HREF="http://openid1.net/delegate"></HEAD>
<BODY><head><LINK REL=openid2.provider HREF="not it either"></head></BODY></HTML>
END
is_deeply($csr->_find_semantic_info($uri4),
{'openid.delegate'=>'http://openid1.net/delegate'},'HTML 4.0- test');

my $uri4a = 'http://openid.aol.com/oldstyle2';
addf_uri($uri4a,content => <<END );
<HTML><HEAD>
<LINK REL=xopenid.serverx HREF="not it" />
<LINK REL=openid.delegate HREF="http://openid1.net/delegate?x=1&amp;y=2&amp;z=3"></HEAD>
<BODY><head><LINK REL=openid2.provider HREF="not it either"></head></BODY></HTML>
END
is_deeply($csr->_find_semantic_info($uri4a),
{'openid.delegate'=>'http://openid1.net/delegate?x=1&y=2&z=3'},'HTML 4.0- test');

my $uri5 = 'http://google.com/somewhere';
addf_uri($uri5,content => <<END );
<html>
<head> <meta http-equiv="content-type" content="text/html; charset=utf-8"/> <title> OpenID for Google Accounts </title> <link rel="openid2.provider openid.server" href="http://openid-provider.appspot.com/joey%40kitenet.net" /> <link href="/static/base.css" rel="stylesheet" type="text/css"/> 
</head><body>bye</body></html>
END
my $answer5 = 
{'openid2.provider'=>'http://openid-provider.appspot.com/joey%40kitenet.net',
 'openid.server'=>'http://openid-provider.appspot.com/joey%40kitenet.net'
};
is_deeply($csr->_find_semantic_info($uri5), $answer5,'link with two refs in it');
is_deeply($csr->_find_semantic_info($uri5), $answer5,'link with two refs in it(again)');
addf_uri($uri5,content => 'randomness');
is_deeply($csr->_find_semantic_info($uri5), $answer5,'link with two refs in it(yet again)');

my $uri4b = 'http://openid.aol.com/oldstyle4b';
addf_uri($uri4b,content => <<END );
<HTML><HEAD>
<LINK REL=xopenid.serverx HREF="not it" />
<LINK REL=openid.delegate HREF="http://op&#x65;nid1.net/deleg&#97;te?x=1&amp;y=2&amp;z=3"></HEAD>
<BODY><head><LINK REL=openid2.provider HREF="not it either"></head></BODY></HTML>
END
is_deeply($csr->_find_semantic_info($uri4b),
{'openid.delegate'=>'http://openid1.net/delegate?x=1&y=2&z=3'},'numerical entities');

my $uri6 = 'http://google.com/somewhere6';
addf_uri($uri6,content => <<END );
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
  <link rel=openid2.provider href='http://openid.example.com/~user'>
  <title>Nice test</title>
  <form action="doit">
  <p>Send me your comment:
  <input type=text name=comment value='<html><head><link
rel=openid2.provider href="http://bogous.example.net"></head>'>
  <input type=submit>
  </form>
END
is_deeply($csr->_find_semantic_info($uri6),
{
'openid2.provider' => 'http://openid.example.com/~user',
},'headless injection example');

1;
