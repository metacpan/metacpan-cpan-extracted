#!/usr/bin/env perl
#
# Copyright (c) 2007, Jeremy Nixon
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# Neither the name of Jeremy Nixon nor the names of any contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# $Rev: 7 $
# $Date: 2008-01-28 20:43:20 -0500 (Mon, 28 Jan 2008) $

use Test::More;
use strict;

# Specify information here, or in the environment.
my $NNTPSERVER = '' || $ENV{NNTPSERVER};
my $NNTPUSER = '' || $ENV{NNTPUSER};
my $NNTPPASS = '' || $ENV{NNTPPASS};
my $NNTPPORT = $ENV{NNTPPORT} || 119;

my @datehdrs = <DATA>;
chomp @datehdrs;

my $tests = 119 + scalar @datehdrs;

if ($NNTPSERVER) {
    plan tests => $tests;
} else {
    plan skip_all => 'No NNTP server specified to use for testing.';
}

use_ok('News::NNTP');
News::NNTP->import(':all');

my $nntp = eval { News::NNTP->new({
    'server'          => $NNTPSERVER,
    'username'        => $NNTPUSER,
    'password'        => $NNTPPASS,
    'port'            => $NNTPPORT,
    'connect_timeout' => 30,
}) };
if (not defined $nntp) {
    BAIL_OUT("NNTP server connection failed. $@");
}
isa_ok($nntp,'News::NNTP');

# Testing basic accessors.
is($nntp->server, $NNTPSERVER, 'nntp server');
is($nntp->port, $NNTPPORT, 'nntp port');
is($nntp->connect_timeout, 30, 'connect timeout');
if ($NNTPUSER) {
    is($nntp->username, $NNTPUSER, 'nntp username');
} else {
    pass('nntp username');
}
if ($NNTPPASS) {
    is($nntp->password, $NNTPPASS, 'nntp password');
} else {
    pass('nntp password');
}

# These should be empty right now.
ok(!$nntp->data);
ok(!$nntp->curgroup);
ok(!$nntp->curart);
ok(!$nntp->curgroup_count);
ok(!$nntp->curgroup_lowater);
ok(!$nntp->curgroup_hiwater);
ok(!$nntp->modereader);

# We should have something here.
ok($nntp->lastcode);
ok($nntp->lastcodetype);

# Technically, a message isn't required.
ok(eval { $nntp->lastmsg } || 1);

isa_ok($nntp->sock, 'IO::Socket::INET', 'IO::Socket::INET object');

ok(cmd_has_multiline_input('post'), 'cmd_has_multiline_input');
ok(!cmd_has_multiline_input('group'), 'cmd_has_multiline_input');
ok(cmd_has_multiline_output('article'), 'cmd_has_multiline_output');
ok(cmd_has_multiline_output('list'), 'cmd_has_multiline_output');
ok(cmd_has_multiline_output('xover'), 'cmd_has_multiline_output');
ok(!cmd_has_multiline_output('group'), 'cmd_has_multiline_output');

SKIP: {
# If we didn't get a 2xx response, we can't proceed.
skip "NNTP connection was not successful, bailing", $tests - 24 - scalar @datehdrs - 1
    if ($nntp->lastcodetype != 2);

# Make sure lastcodetype matches the actual code.
my $code = $nntp->lastcode;
my $firstdigit = substr($code,0,1);
is($nntp->lastcodetype, $firstdigit, 'lastcodetype');

my $succ = $nntp->command('mode reader');
ok($succ);
my $resp = $nntp->lastresp;
$resp =~ /^(\d+)(?: (.*))?$/;
my $gotcode = $1; my $gotmsg = $2;
my $gotcodetype = substr($gotcode,0,1);
is($nntp->lastcode, $gotcode, 'lastcode from mode reader');
is($nntp->lastcodetype, $gotcodetype, 'lastcodetype from mode reader');
if ($gotmsg) {
    is($nntp->lastmsg, $gotmsg, 'lastmsg from mode reader');
} else {
    pass('lastmsg from mode reader');
}
is($nntp->lastcmd, 'mode reader', 'lastcmd from mode reader');
ok($nntp->modereader, 'modereader'); # 31

# A 'help' command should always succeed with a 100 response, and at least
# something in data.
$succ = $nntp->command('help');
ok($succ);
$resp = $nntp->lastresp;
is($nntp->lastcode, 100, 'lastcode from help');
is($nntp->lastcodetype, 1, 'lastcodetype from help');
is($nntp->lastcmd, 'help', 'lastcmd from help');
my $respbody = $nntp->data;
isa_ok($respbody, 'ARRAY'); # 35

# Find some newsgroups.
my @glist;
foreach my $hier (qw(news rec de no comp misc talk uk alt)) {
    $succ = $nntp->command('list active news.*');
    $respbody = $nntp->data;
    next unless ($respbody);
    @glist = @$respbody;
    if (@glist) { last }
}

if ($nntp->lastcode == 480) {
    BAIL_OUT('This NNTP server requires login, but none was provided. Cannot continue.');
}

is($nntp->lastcodetype, 2, 'lastcodetype from list active');
# Pull the full active file only as a last resort.
if (not @glist) {
    $succ = $nntp->command('list active');
    $respbody = $nntp->data;
    @glist = @$respbody;
}
if (not @glist) {
    fail('get active list');
    BAIL_OUT('no newsgroups found on server');
}
pass('get active list');

# We want groups with articles in them.
@glist = grep { News::NNTP->active_count($_) > 8 } @glist;
if (not @glist) {
    fail('use active_count to find groups with articles');
    BAIL_OUT('no newsgroups with articles found');
}
pass('use active_count to find groups with articles');

my $choice = $glist[rand(scalar @glist)];
my ($gname,$hiw,$low,undef) = split /\s+/, $choice;
is($gname, active_group($choice), 'active_group');
is($hiw, active_hiwater($choice), 'active_hiwater');
is($low, active_lowater($choice), 'active_lowater');
is(active_count($choice), $hiw-$low, 'active_count'); # 43

$succ = $nntp->command("group $gname");
ok($succ);
$resp = $nntp->lastresp;
is($nntp->lastcodetype, 2, 'lastcodetype from group');
my ($gcode,$gcount,$glo,$ghi,undef) = split /\s+/, $resp;
is($nntp->lastcode, $gcode, 'lastcode from group');
is($nntp->curgroup_count, $gcount, 'curgroup_count');
is($nntp->curgroup_lowater, $glo, 'curgroup_lowater');
is($nntp->curgroup_hiwater, $ghi, 'curgroup_hiwater');
is($nntp->curgroup, $gname, 'curgroup');
is($nntp->lastcmd, "group $gname", 'lastcmd from group');
my (undef, $gresp) = split /\s+/, $resp, 2;
is($nntp->lastmsg, $gresp, 'lastmsg from group'); # 52

$succ = $nntp->command("article $ghi");
ok($succ, 'article by number');
is($nntp->lastcodetype, 2, 'lastcodetype from article by number');
my $art1 = $nntp->data;
isa_ok($art1, 'ARRAY', 'article data');

$succ = $nntp->command('list overview.fmt');
ok($succ, 'list overview.fmt');
my $fmt = $nntp->overview_fmt;
isa_ok($fmt,'ARRAY');

# Grab an overview for the same article we just looked at.
$succ = $nntp->command("xover $ghi");
ok($succ);
is($nntp->lastcodetype, 2, 'lastcodetype from xover, single entry');
my $oventry = $nntp->data; $oventry = $oventry->[0];
ok($oventry, 'overview data'); # 60

my $ovhash = $nntp->ov_hashref($oventry);
is ($ovhash->{'NUMBER'}, $ghi, 'article number from parsed overview entry');
ok(defined $ovhash->{'from'});
ok(defined $ovhash->{'date'});
ok(defined $ovhash->{'subject'});
ok(defined $ovhash->{'message-id'});
ok(defined $ovhash->{'bytes'});
ok(defined $ovhash->{'lines'});

# Pull the article by message-id.
my $mid = $ovhash->{'message-id'};
$resp = $nntp->command("article $mid");
ok($resp, 'article by message-id');
is($nntp->lastcodetype, 2, 'lastcodetype from article by message-id');
my $art2 = $nntp->data;
isa_ok($art2,'ARRAY', 'article data');
cmp_ok(scalar @$art2, '>', 4, 'article data');

# Grab multiple overviews.
$resp = $nntp->command('xover '. ($ghi-7) ."-$ghi");
is($nntp->lastcodetype, 2, 'lastcodetype from xover, multiple entries');

my $xover = $nntp->data;
isa_ok($xover, 'ARRAY', 'multiple xover response'); # 73

# Unfortunately we can't actually know there are 8 entries present.
for (my $i = 0; $i < 8; $i++) {
    if (defined($xover->[$i])) {
        $ovhash = $nntp->ov_hashref($xover->[$i]);
        my $id = $ovhash->{'message-id'};
        ok(defined($id), 'message-id from multi-overview output');
        $succ = $nntp->command("article $id");
        is($nntp->lastcodetype, 2, 'lastcodetype from article command');
        my $art = $nntp->data;
        isa_ok($art, 'ARRAY', 'article data');
        cmp_ok(scalar @$art, '>', 4, 'article data');
    } else {
        pass('dummy test from xover');
        pass('dummy test from xover');
        pass('dummy test from xover');
        pass('dummy test from xover');
    }
}

# Ok, now try something that should produce an error response.
$succ = $nntp->command("my hovercraft is full of eels");
is($nntp->lastcodetype, 5, 'error response'); # 106

# Test the response hook.
my ($response,$wascalled);
$nntp->resphook(sub { $wascalled = 1; $response = shift } );
$choice = $glist[rand(scalar @glist)];
$gname = (split /\s+/, $choice)[0];
$succ = $nntp->command("group $gname");
$resp = $nntp->lastresp;
my ($tcode,$tmesg) = split /\s+/, $response, 2;

is($nntp->lastcodetype, 2, 'group codetype');
ok($wascalled, 'hook was called');
is($response,$resp, 'response from hook matches response');
is($tcode,$nntp->lastcode, 'lastcode match from hook');
is($tmesg,$nntp->lastmsg, 'lastmsg match from hook');

($gcode,$gcount,$glo,$ghi,undef) = split /\s+/, $response;
is($nntp->lastcode, $gcode, 'lastcode from group');
is($nntp->curgroup_count, $gcount, 'curgroup_count');
is($nntp->curgroup_lowater, $glo, 'curgroup_lowater');
is($nntp->curgroup_hiwater, $ghi, 'curgroup_hiwater');
is($nntp->curgroup, $gname, 'curgroup');
is($nntp->lastcmd, "group $gname", 'lastcmd from group');

$nntp->resphook(undef);

# Need to test passing coderefs to command().

ok($nntp->drop);

}

for (@datehdrs) {
    my ($h,$u) = split /\t/, $_;
    my $v = parse_date($h);
    is($v,$u, 'parse_date');
}

{
    local $ENV{TZ} = 'America/New_York';
    is(format_date(1191462777), 'Wed, 03 Oct 2007 21:52:57 -0400', 'format_date');
}

# Some Date headers pulled from Usenet articles.
__DATA__
Wed, 5 Sep 2007 16:12:01 +0200	1189001521
Wed, 5 Sep 2007 14:21:25 +0000 (UTC)	1189002085
Wed, 05 Sep 2007 12:07:44 -0700	1189019264
Fri, 7 Sep 2007 04:07:44 +0000 (UTC)	1189138064
Sun, 09 Sep 2007 19:04:13 +0200	1189357453
Sun, 9 Sep 2007 18:03:55 +0000 (UTC)	1189361035
Sun, 09 Sep 2007 21:57:05 +0200	1189367825
Sun, 09 Sep 2007 22:32:21 +0200	1189369941
09 Sep 2007 23:26:07 GMT	1189380367
Sun, 09 Sep 2007 16:28:09 -0700	1189380489
Sun, 09 Sep 2007 21:59:43 -0400	1189389583
Sun, 09 Sep 2007 19:03:21 -0700	1189389801
Mon, 10 Sep 2007 08:38:56 +0200	1189406336
Mon, 10 Sep 2007 06:05:48 -0400	1189418748
Mon, 10 Sep 2007 11:31:06 +0000 (UTC)	1189423866
Mon, 10 Sep 2007 14:49:37 +0200	1189428577
Mon, 17 Sep 2007 14:49:10 GMT	1190040550
Tue, 18 Sep 2007 15:35:20 -0500	1190147720
Tue, 18 Sep 2007 23:23:47 +0200	1190150627
Tue, 2 Oct 2007 21:04:40 GMT	1191359080
Tue, 02 Oct 2007 22:41:57 GMT	1191364917
02 Oct 2007 21:41:49 GMT	1191361309
Wed, 03 Oct 2007 00:58:03 -0000	1191373083
Mon, 1 Oct 2007 10:49:32 -0600	1191257372
Thu, 23 Dec 2004 15:37:52 GMT	1103816272
Thu, 23 Dec 2004 15:38:50 +0000	1103816330
23 Dec 2004 17:38:31 GMT	1103823511
Thu, 23 Dec 2004 10:24:45 -0800	1103826285
Thu, 23 Dec 2004 14:04:41 -0600	1103832281
23 Dec 2004 16:09:53 -0800	1103846993
Fri, 24 Dec 2004 13:28:09 +1000	1103858889
05 Sep 2007 10:44:56 GMT	1188989096
05 Sep 2007 10:25:16 GMT	1188987916
Wed, 05 Sep 2007 05:44:53 -0500	1188989093
Sun, 24 Jul 2005 14:55:46 -0700	1122242146
Sun, 24 Jul 2005 23:13:13 -0000	1122246793
13 Mar 2007 22:19:38 -0700	1173849578
13 Mar 2007 22:28:06 -0700	1173850086
Wed, 14 Mar 2007 05:36:49 -0500	1173868609
Wed, 14 Mar 2007 06:53:55 -0400	1173869635
Wed, 14 Mar 2007 13:24:07 GMT	1173878647
Sat, 15 Sep 2007 07:49:01 CST	1189864141
Thu, 20 Sep 2007 23:25:47 CST	1190352347
