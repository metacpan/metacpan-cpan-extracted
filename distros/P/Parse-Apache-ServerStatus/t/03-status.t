use strict;
use warnings;
use Test::More tests => 31;
use Parse::Apache::ServerStatus;

my $status_auto = <<EOT;
BusyWorkers: 2
IdleWorkers: 10
Scoreboard: ___WW_______.........
EOT

my $status_auto_e = <<EOT;
Total Accesses: 5
Total kBytes: 8
Uptime: 70
ReqPerSec: .0714286
BytesPerSec: 117.029
BytesPerReq: 1638.4
BusyWorkers: 2
IdleWorkers: 10
Scoreboard: ___WW_______.........
EOT

my $status1 = <<EOT;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<HTML><HEAD>
<TITLE>Apache Status</TITLE>
</HEAD><BODY>
<H1>Apache Server Status for localhost</H1>

Server Version: Apache/1.3.34 (Ubuntu)<br>
Server Built: Mar  8 2007 00:01:35<br>
<hr>

Current Time: Monday, 27-Oct-2008 16:57:03 CET<br>
Restart Time: Monday, 27-Oct-2008 16:56:55 CET<br>
Parent Server Generation: 1 <br>
Server uptime:  8 seconds<br>

1 requests currently being processed, 5 idle servers
<PRE>W_____..........................................................
................................................................
................................................................
</PRE>
EOT

my $status1e = <<EOT;
Server Version: Apache/1.3.34 (Ubuntu)<br>
Server Built: Mar  8 2007 00:01:35<br>
<hr>
Current Time: Saturday, 13-Oct-2007 20:41:00 CEST<br>
Restart Time: Saturday, 13-Oct-2007 20:30:09 CEST<br>
Parent Server Generation: 0 <br>
Server uptime:  10 minutes 51 seconds<br>
Total accesses: 239409 - Total Traffic: 1.7 MB<br>
CPU Usage: u.32 s.21 cu0 cs0 - .0814% CPU load<br>
368 requests/sec - 7.3 MB/second - 6.3 kB/request<br>

1 requests currently being processed, 32 idle servers
<PRE>___________W____........._________________......................
................................................................
................................................................
</PRE>
Scoreboard Key: <br>
"<B><code>_</code></B>" Waiting for Connection, 
"<B><code>S</code></B>" Starting up, 
"<B><code>R</code></B>" Reading Request,<BR>
"<B><code>W</code></B>" Sending Reply, 
"<B><code>K</code></B>" Keepalive (read), 
"<B><code>D</code></B>" DNS Lookup,<BR>
"<B><code>L</code></B>" Logging, 
"<B><code>G</code></B>" Gracefully finishing, 
"<B><code>.</code></B>" Open slot with no current process<P>
<P>
<p>
EOT

my $status2 = <<EOT;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<html><head>
<title>Apache Status</title>
</head><body>
<h1>Apache Server Status for www.bloonix.de</h1>

<dl><dt>Server Version: Apache/2.2.3 (Debian) mod_fastcgi/2.4.2 mod_ssl/2.2.3 OpenSSL/0.9.8c</dt>
<dt>Server Built: Mar 22 2008 09:29:10
</dt></dl><hr /><dl>
<dt>Current Time: Monday, 27-Oct-2008 16:07:52 CET</dt>
<dt>Restart Time: Monday, 27-Oct-2008 16:07:46 CET</dt>
<dt>Parent Server Generation: 0</dt>
<dt>Server uptime:  6 seconds</dt>
<dt>1 requests currently being processed, 9 idle workers</dt>
</dl><pre>W_________......................................................
................................................................
................................................................
................................................................
</pre>
<p>Scoreboard Key:<br />
"<b><code>_</code></b>" Waiting for Connection, 
"<b><code>S</code></b>" Starting up, 
"<b><code>R</code></b>" Reading Request,<br />
"<b><code>W</code></b>" Sending Reply, 
"<b><code>K</code></b>" Keepalive (read), 
"<b><code>D</code></b>" DNS Lookup,<br />
"<b><code>C</code></b>" Closing connection, 
"<b><code>L</code></b>" Logging, 
"<b><code>G</code></b>" Gracefully finishing,<br /> 
"<b><code>I</code></b>" Idle cleanup of worker, 
"<b><code>.</code></b>" Open slot with no current process</p>
<p />
EOT

my $status2e = <<EOT;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<html><head>
<title>Apache Status</title>
</head><body>
<h1>Apache Server Status for www.bloonix.de</h1>

<dl><dt>Server Version: Apache/2.2.3 (Debian) mod_fastcgi/2.4.2 mod_ssl/2.2.3 OpenSSL/0.9.8c</dt>
<dt>Server Built: Mar 22 2008 09:29:10
</dt></dl><hr /><dl>
<dt>Current Time: Monday, 27-Oct-2008 16:06:15 CET</dt>
<dt>Restart Time: Monday, 27-Oct-2008 15:34:41 CET</dt>
<dt>Parent Server Generation: 0</dt>
<dt>Server uptime:  31 minutes 33 seconds</dt>
<dt>Total accesses: 27 - Total Traffic: 3.8 mB</dt>
<dt>CPU Usage: u0 s0 cu0 cs0</dt>
<dt>.0143 requests/sec - 7.3 MB/second - 6.7 kB/request</dt>
<dt>1 requests currently being processed, 9 idle workers</dt>
</dl><pre>W_________________..............................................
................................................................
................................................................
................................................................
</pre>
<p>Scoreboard Key:<br />
"<b><code>_</code></b>" Waiting for Connection, 
"<b><code>S</code></b>" Starting up, 
"<b><code>R</code></b>" Reading Request,<br />
"<b><code>W</code></b>" Sending Reply, 
"<b><code>K</code></b>" Keepalive (read), 
"<b><code>D</code></b>" DNS Lookup,<br />
"<b><code>C</code></b>" Closing connection, 
"<b><code>L</code></b>" Logging, 
"<b><code>G</code></b>" Gracefully finishing,<br /> 
"<b><code>I</code></b>" Idle cleanup of worker, 
"<b><code>.</code></b>" Open slot with no current process</p>
<p />
EOT

my $prs = Parse::Apache::ServerStatus->new();
my $ret = ();

# testing apache auto
$ret = $prs->parse($status_auto) or die $prs->errstr;
ok($ret->{ta} == 0, "total accesses apache auto");
ok($ret->{r} == 2, "requests apache auto");
ok($ret->{i} == 10, "idles apache auto");
ok($ret->{W} == 2, "rest apache auto");

# testing apache auto extended
$ret = $prs->parse($status_auto_e) or die $prs->errstr;
ok($ret->{ta} == 5, "total accesses apache auto extended");
ok($ret->{r} == 2, "requests apache auto extended");
ok($ret->{i} == 10, "idles apache auto extended");
ok($ret->{W} == 2, "rest apache auto extended");

# testing apache v1
$ret = $prs->parse($status1) or die $prs->errstr;
ok($ret->{ta} == 0, "total accesses apache");
ok($ret->{r} == 1, "requests apache");
ok($ret->{i} == 5, "idles apache");
ok($ret->{W} == 1, "rest apache");

# testing apache v1 extended
$ret = $prs->parse($status1e) or die $prs->errstr;
ok($ret->{ta} == 239409, "total accesses apache extended");
ok($ret->{tt} eq '1.7 MB', "total traffic apache extended");
ok($ret->{bs} eq '7654604.8', "bytes per second apache extended");
ok($ret->{br} eq '6451.2', "bytes per request apache extended");
ok($ret->{r} == 1, "requests apache extended");
ok($ret->{i} == 32, "idles apache extended");
ok($ret->{W} == 1, "rest apache extended");

# testing apache v2
$ret = $prs->parse($status2) or die $prs->errstr;
ok($ret->{ta} == 0, "total accesses apache2");
ok($ret->{r} == 1, "requests apache2");
ok($ret->{i} == 9, "idles apache2");
ok($ret->{W} == 1, "rest apache2");

# testing apache v2 extended
$ret = $prs->parse($status2e) or die $prs->errstr;
ok($ret->{ta} == 27, "total accesses apache2 extended");
ok($ret->{tt} eq '3.8 mB', "total traffic apache2 extended");
ok($ret->{rs} eq '.0143', "requests per second apache2 extended");
ok($ret->{bs} eq '7654604.8', "bytes per second apache2 extended");
ok($ret->{br} eq '6860.8', "bytes per request apache2 extended");
ok($ret->{r} == 1, "requests apache2 extended");
ok($ret->{i} == 9, "idles apache2 extended");
ok($ret->{W} == 1, "rest apache2 extended");
