use warnings;
use strict;

use Data::Dumper;
use Test::More('tests', 19);
use HTTP::Status;

BEGIN
{
    use_ok('POE::Filter::SimpleHTTP');
    use_ok('POE::Filter::SimpleHTTP::Regex');
    use_ok('POE::Filter::SimpleHTTP::Error');
}

$POE::Filter::SimpleHTTP::DEBUG = 0;

my $request_data = <<'REQUEST';
GET / HTTP/1.0
User-Agent: Wget/1.11.4
Accept: */*
Host: localhost:64000
Connection: Keep-Alive


REQUEST

my $response_data = <<'RESPONSE';
HTTP/1.0 200 OK
Cache-Control: private, max-age=0
Date: Tue, 21 Apr 2009 16:10:03 GMT
Expires: -1
Content-Type: text/html; charset=ISO-8859-1
Set-Cookie: PREF=ID=7adf5b9e3e51d251:TM=1240330203:LM=1240330203:S=61k21igTTXkLcR5z; expires=Thu, 21-Apr-2011 16:10:03 GMT; path=/; domain=.google.com
Server: gws

<html><head><meta http-equiv="content-type" content="text/html; charset=ISO-8859-1"><title>Google</title><script>window.google={kEI:"2-_tSdmxEIewNKPptesP",kEXPI:"17259,20257",kHL:"en"};
window.google.sn="webhp";window.google.timers={load:{t:{start:(new Date).getTime()}}};try{window.google.pt=window.gtbExternal&&window.gtbExternal.pageT()||window.external&&window.external.pageT}catch(b){}
window.google.jsrt_kill=1;
var _gjwl=location;function _gjuc(){var a=_gjwl.hash;if(a.indexOf("&q=")>0||a.indexOf("#q=")>=0){a=a.substring(1);if(a.indexOf("#")==-1){for(var c=0;c<a.length;){var d=c;if(a.charAt(d)=="&")++d;var b=a.indexOf("&",d);if(b==-1)b=a.length;var e=a.substring(d,b);if(e.indexOf("fp=")==0){a=a.substring(0,c)+a.substring(b,a.length);b=c}else if(e=="cad=h")return 0;c=b}_gjwl.href="search?"+a+"&cad=h";return 1}}return 0}function _gjp(){!(window._gjwl.hash&&window._gjuc())&&setTimeout(_gjp,500)};
window._gjp && _gjp();</script><style>body,td,a,p,.h{font-family:arial,sans-serif}.h{color:#36c;font-size:20px}.q{color:#00c}.ts td{padding:0}.ts{border-collapse:collapse}#gbar{height:22px;padding-left:2px}.gbh,.gbd{border-top:1px solid #c9d7f1;font-size:1px}.gbh{height:0;position:absolute;top:24px;width:100%}#guser{padding-bottom:7px !important}#gbar,#guser{font-size:13px;padding-top:1px !important}@media all{.gb1,.gb3{height:22px;margin-right:.73em;vertical-align:top}#gbar{float:left}}a.gb1,a.gb3{color:#00c !important}.gb3{text-decoration:none}</style><script>google.y={};google.x=function(e,g){google.y[e.id]=[e,g];return false};</script></head><body bgcolor=#ffffff text=#000000 link=#0000cc vlink=#551a8b alink=#ff0000 onload="document.f.q.focus();if(document.images)new Image().src='/images/nav_logo4.png'" topmargin=3 marginheight=3><textarea id=csi style=display:none></textarea><div id=gbar><nobr><b class=gb1>Web</b> <a href="http://images.google.com/imghp?hl=en&tab=wi" class=gb1>Images</a> <a href="http://maps.google.com/maps?hl=en&tab=wl" class=gb1>Maps</a> <a href="http://news.google.com/nwshp?hl=en&tab=wn" class=gb1>News</a> <a href="http://video.google.com/?hl=en&tab=wv" class=gb1>Video</a> <a href="http://mail.google.com/mail/?hl=en&tab=wm" class=gb1>Gmail</a> <a href="http://www.google.com/intl/en/options/" class=gb3><u>more</u> &raquo;</a></nobr></div><div class=gbh style=left:0></div><div class=gbh style=right:0></div><div align=right id=guser style="font-size:84%;padding:0 0 4px" width=100%><nobr><a href="/url?sa=p&pref=ig&pval=3&q=http://www.google.com/ig%3Fhl%3Den%26source%3Diglk&usg=AFQjCNFA18XPfgb7dKnXfKz7x7g1GDH1tg">iGoogle</a> | <a href="https://www.google.com/accounts/Login?continue=http://www.google.com/&hl=en">Sign in</a></nobr></div><center><br clear=all id=lgpd><img alt="Google" height=110 src="/intl/en_ALL/images/logo.gif" width=276><br><br><form action="/search" name=f><table cellpadding=0 cellspacing=0><tr valign=top><td width=25%>&nbsp;</td><td align=center nowrap><input name=hl type=hidden value=en><input type=hidden name=ie value="ISO-8859-1"><input autocomplete="off" maxlength=2048 name=q size=55 title="Google Search" value=""><br><input name=btnG type=submit value="Google Search"><input name=btnI type=submit value="I'm Feeling Lucky"></td><td nowrap width=25%><font size=-2>&nbsp;&nbsp;<a href=/advanced_search?hl=en>Advanced Search</a><br>&nbsp;&nbsp;<a href=/preferences?hl=en>Preferences</a><br>&nbsp;&nbsp;<a href=/language_tools?hl=en>Language Tools</a></font></td></tr></table></form><br><br><font size=-1><a href="/intl/en/ads/">Advertising&nbsp;Programs</a> - <a href="/services/">Business Solutions</a> - <a href="/intl/en/about.html">About Google</a></font><p><font size=-2>&copy;2009 - <a href="/intl/en/privacy.html">Privacy</a></font></p></center><div id=xjsd><script>if(google.y)google.y.first=[];google.dstr=[];google.rein=[];window.setTimeout(function(){var xjs=document.createElement('script');xjs.src='/extern_js/f/CgJlbhICdXMgACswCjgVLCswDjgFLCswGDgDLCswJTjJiAEsKzAmOAQsKzAnOAAs/44fSbrQUBfg.js';(document.getElementById('xjsd') || document.body).appendChild(xjs)},0);google.y.first.push(function(){google.ac.i(document.f,document.f.q,'','')})</script></div><script>(function(){
function a(){google.timers.load.t.ol=(new Date).getTime();google.report&&google.report(google.timers.load,{ei:google.kEI,e:google.kEXPI})}if(window.addEventListener)window.addEventListener("load",a,false);else if(window.attachEvent)window.attachEvent("onload",a);google.timers.load.t.prt=(new Date).getTime();
})();
</script>


RESPONSE

my $response_chunked = <<'CHUNKED';
HTTP/1.1 200 OK
Cache-Control: private, max-age=0
Date: Tue, 21 Apr 2009 20:27:45 GMT
Expires: -1
Content-Type: text/html; charset=ISO-8859-1
Set-Cookie: PREF=ID=25452f5dd13e4bed:TM=1240345665:LM=1240345665:S=dpSsSFgwWhK_PaLX; expires=Thu, 21-Apr-2011 20:27:45 GMT; path=/; domain=.google.com
Server: gws
Transfer-Encoding: chunked

fef
<html><head><meta http-equiv="content-type" content="text/html; charset=ISO-8859-1"><title>Google</title><script>window.google={kEI:"QSzuSafWMIymNcOJifoP",kEXPI:"17259,20256",kHL:"en"};
window.google.sn="webhp";window.google.timers={load:{t:{start:(new Date).getTime()}}};try{window.google.pt=window.gtbExternal&&window.gtbExternal.pageT()||window.external&&window.external.pageT}catch(b){}
window.google.jsrt_kill=1;
var _gjwl=location;function _gjuc(){var a=_gjwl.hash;if(a.indexOf("&q=")>0||a.indexOf("#q=")>=0){a=a.substring(1);if(a.indexOf("#")==-1){for(var c=0;c<a.length;){var d=c;if(a.charAt(d)=="&")++d;var b=a.indexOf("&",d);if(b==-1)b=a.length;var e=a.substring(d,b);if(e.indexOf("fp=")==0){a=a.substring(0,c)+a.substring(b,a.length);b=c}else if(e=="cad=h")return 0;c=b}_gjwl.href="search?"+a+"&cad=h";return 1}}return 0}function _gjp(){!(window._gjwl.hash&&window._gjuc())&&setTimeout(_gjp,500)};
window._gjp && _gjp();</script><style>body,td,a,p,.h{font-family:arial,sans-serif}.h{color:#36c;font-size:20px}.q{color:#00c}.ts td{padding:0}.ts{border-collapse:collapse}#gbar{height:22px;padding-left:2px}.gbh,.gbd{border-top:1px solid #c9d7f1;font-size:1px}.gbh{height:0;position:absolute;top:24px;width:100%}#guser{padding-bottom:7px !important}#gbar,#guser{font-size:13px;padding-top:1px !important}@media all{.gb1,.gb3{height:22px;margin-right:.73em;vertical-align:top}#gbar{float:left}}a.gb1,a.gb3{color:#00c !important}.gb3{text-decoration:none}</style><script>google.y={};google.x=function(e,g){google.y[e.id]=[e,g];return false};</script></head><body bgcolor=#ffffff text=#000000 link=#0000cc vlink=#551a8b alink=#ff0000 onload="document.f.q.focus();if(document.images)new Image().src='/images/nav_logo4.png'" topmargin=3 marginheight=3><textarea id=csi style=display:none></textarea><div id=gbar><nobr><b class=gb1>Web</b> <a href="http://images.google.com/imghp?hl=en&tab=wi" class=gb1>Images</a> <a href="http://maps.google.com/maps?hl=en&tab=wl" class=gb1>Maps</a> <a href="http://news.google.com/nwshp?hl=en&tab=wn" class=gb1>News</a> <a href="http://video.google.com/?hl=en&tab=wv" class=gb1>Video</a> <a href="http://mail.google.com/mail/?hl=en&tab=wm" class=gb1>Gmail</a> <a href="http://www.google.com/intl/en/options/" class=gb3><u>more</u> &raquo;</a></nobr></div><div class=gbh style=left:0></div><div class=gbh style=right:0></div><div align=right id=guser style="font-size:84%;padding:0 0 4px" width=100%><nobr><a href="/url?sa=p&pref=ig&pval=3&q=http://www.google.com/ig%3Fhl%3Den%26source%3Diglk&usg=AFQjCNFA18XPfgb7dKnXfKz7x7g1GDH1tg">iGoogle</a> | <a href="https://www.google.com/accounts/Login?continue=http://www.google.com/&hl=en">Sign in</a></nobr></div><center><br clear=all id=lgpd><img alt="Google" height=110 src="/intl/en_ALL/images/logo.gif" width=276><br><br><form action="/search" name=f><table cellpadding=0 cellspacing=0><tr valign=top><td width=25%>&nbsp;</td><td align=center nowrap><input name=hl type=hidden value=en><input type=hidden name=ie value="ISO-8859-1"><input autocomplete="off" maxlength=2048 name=q size=55 title="Google Search" value=""><br><input name=btnG type=submit value="Google Search"><input name=btnI type=submit value="I'm Feeling Lucky"></td><td nowrap width=25%><font size=-2>&nbsp;&nbsp;<a href=/advanced_search?hl=en>Advanced Search</a><br>&nbsp;&nbsp;<a href=/preferences?hl=en>Preferences</a><br>&nbsp;&nbsp;<a href=/language_tools?hl=en>Language Tools</a></font></td></tr></table></form><br><br><font size=-1><a href="/intl/en/ads/">Advertising&nbsp;Programs</a> - <a href="/services/">Business Solutions</a> - <a href="/intl/en/about.html">About Google</a></font><p><font size=-2>&copy;2009 - <a href="/intl/en/privacy.html">Privacy</a></font></p></center><div id=xjsd><script>if(google.y)google.y.first=[];google.dstr=[];google.rein=[];window.setTimeout(function(){var xjs=document.createElement('script');xjs.src='/extern_js/f/CgJlbhICdXMgACswCjgVLCswDjgFLCswGDgDLCswJTjJiAEsKzAmOAQsKzAnOAAs/44fSbrQUBfg.js';(document.getElementById('xjsd') || document.body).appendChild(xjs)},0);google.y.firs
1a7
t.push(function(){google.ac.i(document.f,document.f.q,'','')})</script></div><script>(function(){
function a(){google.timers.load.t.ol=(new Date).getTime();google.report&&google.report(google.timers.load,{ei:google.kEI,e:google.kEXPI})}if(window.addEventListener)window.addEventListener("load",a,false);else if(window.attachEvent)window.attachEvent("onload",a);google.timers.load.t.prt=(new Date).getTime();
})();
</script>
0

CHUNKED

my $response_chunked_compressed = <<'COMPRESSED';
HTTP/1.1 200 OK
Cache-Control: max-age=172800
Date: Tue, 21 Apr 2009 23:25:48 GMT
Transfer-Encoding: gzip,chunked
Content-Md5: BpMcfPwGUXC7g/FpbRkO/A==
Content-Type: text/plain
Etag: "1pe1kjm:q7kclme8"
Expires: Thu, 23 Apr 2009 23:25:48 GMT
Last-Modified: Thu, 27 Dec 2001 17:40:27 GMT
Server: Jigsaw/2.3.0-beta1

B
       
56
íÆ¡ 0 0¿+¸d!óÎç©V5_Eßé"""""""""""""""""""""""""""""""""""ò+kÔÖ
 H  
0

COMPRESSED

my $response_chunked_deflated = <<'DEFLATED';
HTTP/1.1 200 OK
Cache-Control: max-age=172800
Date: Wed, 22 Apr 2009 00:50:41 GMT
Transfer-Encoding: deflate,chunked
Content-Md5: BpMcfPwGUXC7g/FpbRkO/A==
Content-Type: text/plain
Etag: "1pe1kjm:q7kclme8"
Expires: Fri, 24 Apr 2009 00:50:41 GMT
Last-Modified: Thu, 27 Dec 2001 17:40:27 GMT
Server: Jigsaw/2.3.0-beta1

58
xíÆ¡ 0 0¿+¸d!óÎç©V5_Eßé"""""""""""""""""""""""""""""""""""ò+]	x
0

DEFLATED

my $filter = POE::Filter::SimpleHTTP->new();
isa_ok($filter, 'POE::Filter');
isa_ok($filter, 'Moose::Object');
isa_ok($filter, 'POE::Filter::SimpleHTTP');
my $clone = $filter->clone();
isa_ok($clone, 'POE::Filter');
isa_ok($clone, 'Moose::Object');
isa_ok($clone, 'POE::Filter::SimpleHTTP');

$request_data =~ s/\n/\x0d\x0a/g;
$filter->get_one_start($request_data);

my $request = $filter->get_one()->[0];
#diag(Dumper($request));
isa_ok($request, 'HTTP::Request');
is($request->uri(), URI->new('/'), 'URI for the request');
#diag($request->content());


$response_data =~ s/\n/\x0d\x0a/g;
$filter->get_one_start($response_data);

my $response = $filter->get_one()->[0];

#diag(Dumper($response));
isa_ok($response, 'HTTP::Response');
is($response->code(), +RC_OK, 'Code for the response');
#diag($response->content());

$response_chunked =~ s/\n/\x0d\x0a/g;
$filter->get_one_start($response_chunked);

my $chunked = $filter->get_one()->[0];

#diag(Dumper($chunked));
isa_ok($chunked, 'HTTP::Response');
is($chunked->code(), +RC_OK, 'Code for chunked');
#diag($chunked->content());

$response_chunked_compressed =~ s/\n/\x0d\x0a/g;
$filter->get_one_start($response_chunked_compressed);

my $compressed = $filter->get_one()->[0];

#diag(Dumper($compressed));
isa_ok($compressed, 'HTTP::Response');
is($compressed->code(), +RC_OK, 'Code for compressed');
#diag($compressed->content());

$response_chunked_deflated =~ s/\n/\x0d\x0a/g;
$filter->get_one_start($response_chunked_deflated);

my $deflated = $filter->get_one()->[0];

#diag(Dumper($deflated));
isa_ok($deflated, 'HTTP::Response');
is($deflated->code(), +RC_OK, 'Code for deflated');
#diag($deflated->content());
