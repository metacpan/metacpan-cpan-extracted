#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Net::DAVTalk;

# A minimal HTTP::Tiny stand-in: hands back queued responses in order
# and records each request so we can check what was sent.
package MockUA {
  sub new { bless { queue => [], requests => [] }, shift }
  sub queue { my $Self = shift; push @{$Self->{queue}}, @_ }
  sub requests { $_[0]{requests} }
  sub request {
    my ($Self, $Method, $URI, $Args) = @_;
    push @{$Self->{requests}}, { method => $Method, uri => $URI, %$Args };
    my $Body = shift @{$Self->{queue}} // die "no response queued for $Method $URI";
    return {
      success  => 1,
      status   => 207,
      reason   => 'Multi-Status',
      protocol => 'HTTP/1.1',
      headers  => {},
      content  => $Body,
    };
  }
}

sub multistatus {
  my ($token, @responses) = @_;
  return qq{<?xml version="1.0" encoding="utf-8"?>\n}
       . qq{<d:multistatus xmlns:d="DAV:">}
       . join('', @responses)
       . (defined $token ? "<d:sync-token>$token</d:sync-token>" : '')
       . qq{</d:multistatus>};
}

sub changed {
  my ($href, $etag) = @_;
  return "<d:response><d:href>$href</d:href><d:propstat><d:prop>"
       . "<d:getetag>$etag</d:getetag></d:prop>"
       . "<d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response>";
}

sub gone {
  my ($href, $status) = @_;
  $status //= '404 Not Found';
  return "<d:response><d:href>$href</d:href>"
       . "<d:status>HTTP/1.1 $status</d:status></d:response>";
}

sub new_talk {
  my $ua = MockUA->new;
  my $talk = Net::DAVTalk->new(url => 'http://dav.example.com/dav/');
  $talk->ua($ua);
  return ($talk, $ua);
}

my $Coll = '/dav/coll';

# --- a plain sync from nothing
{
  my ($talk, $ua) = new_talk();
  $ua->queue(multistatus('t1', changed("$Coll/a.ics", '"ea"'), changed("$Coll/b.ics", '"eb"')));
  my ($Added, $Removed, $Errors, $Token) = $talk->SyncCollection($Coll);
  is_deeply($Added, { "$Coll/a.ics" => '"ea"', "$Coll/b.ics" => '"eb"' }, 'full sync: every member added');
  is_deeply($Removed, [], 'nothing removed');
  is_deeply($Errors, [], 'no errors');
  is($Token, 't1', 'the new token');
  is(scalar @{$ua->requests}, 1, 'one REPORT');
  is($ua->requests->[0]{method}, 'REPORT', 'it is a REPORT');
  like($ua->requests->[0]{content}, qr{<D:sync-token\s*/>}, 'with an empty sync-token');
}

# --- from a token, with removals, a missing property and an odd status
{
  my ($talk, $ua) = new_talk();
  $ua->queue(multistatus('t2',
    changed("$Coll/a.ics", '"ea2"'),
    gone("$Coll/b.ics"),
    gone("$Coll/c.ics", '403 Forbidden'),
    "<d:response><d:href>$Coll/d.ics</d:href>"
      . "<d:propstat><d:prop><d:getetag>\"ed\"</d:getetag></d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat>"
      . "<d:propstat><d:prop><d:getcontenttype/></d:prop><d:status>HTTP/1.1 404 Not Found</d:status></d:propstat>"
      . "</d:response>",
  ));
  my ($Added, $Removed, $Errors, $Token) = $talk->SyncCollection("$Coll/", syncToken => 't1');
  like($ua->requests->[0]{content}, qr{<D:sync-token>t1</D:sync-token>}, 'the token is sent');
  like($ua->requests->[0]{uri}, qr{/dav/coll/$}, 'to the collection, one trailing slash');
  is_deeply($Added, { "$Coll/a.ics" => '"ea2"', "$Coll/d.ics" => '"ed"' }, 'changed members');
  is_deeply($Removed, ["$Coll/b.ics"], 'only a 404 is a removal');
  is(scalar @$Errors, 1, 'one error');
  like($Errors->[0], qr{c\.ics: HTTP/1\.1 403}, 'for the odd status, not the missing property');
  is($Token, 't2', 'the new token');
}

# --- a truncated response (RFC 6578 3.6) is followed until it is whole
{
  my ($talk, $ua) = new_talk();
  $ua->queue(
    multistatus('p1', changed("$Coll/a.ics", '"ea"'), changed("$Coll/b.ics", '"eb"'),
                gone("$Coll/", '507 Insufficient Storage')),
    multistatus('p2', changed("$Coll/c.ics", '"ec"'), gone("$Coll/a.ics"),
                gone("$Coll/", '507 Insufficient Storage')),
    multistatus('p3', changed("$Coll/a.ics", '"ea3"'), gone("$Coll/b.ics")),
  );
  my ($Added, $Removed, $Errors, $Token) = $talk->SyncCollection($Coll);
  is(scalar @{$ua->requests}, 3, 'three REPORTs');
  like($ua->requests->[1]{content}, qr{<D:sync-token>p1</D:sync-token>}, 'the second from the first token');
  like($ua->requests->[2]{content}, qr{<D:sync-token>p2</D:sync-token>}, 'the third from the second');
  is_deeply($Added, { "$Coll/a.ics" => '"ea3"', "$Coll/c.ics" => '"ec"' },
    'a member is what the last round says: removed then back, it is added');
  is_deeply($Removed, ["$Coll/b.ics"], 'added then removed, it is removed');
  is_deeply($Errors, [], 'the 507 is neither an error nor a removal');
  is($Token, 'p3', 'the last token');
}

# --- iCloud lists the collection itself, with an etag, among the changes
{
  my ($talk, $ua) = new_talk();
  $ua->queue(multistatus('i1', changed("$Coll/", '"ecoll"'), changed("$Coll/a.ics", '"ea"')));
  my ($Added, $Removed, $Errors) = $talk->SyncCollection($Coll);
  is_deeply($Added, { "$Coll/a.ics" => '"ea"' }, 'the collection is not a member');
  is_deeply($Errors, [], 'nor an error');
}

# --- a server that truncates without moving on is not asked forever
{
  my ($talk, $ua) = new_talk();
  $ua->queue(
    multistatus('s1', changed("$Coll/a.ics", '"ea"'), gone("$Coll/", '507 Insufficient Storage')),
    multistatus('s1', gone("$Coll/", '507 Insufficient Storage')),
  );
  my ($Added, $Removed, $Errors, $Token) = $talk->SyncCollection($Coll);
  is(scalar @{$ua->requests}, 2, 'stops when the token does not change');
  is_deeply($Added, { "$Coll/a.ics" => '"ea"' }, 'and keeps what came');
  like($Errors->[0], qr{truncated without a new sync-token}, 'with an error');
  is($Token, 's1', 'and the token');
}

# --- MaxRounds
{
  my ($talk, $ua) = new_talk();
  $ua->queue(map { multistatus("m$_", gone("$Coll/", '507 Insufficient Storage')) } 1..3);
  ok(!eval { $talk->SyncCollection($Coll, MaxRounds => 2); 1 }, 'gives up after MaxRounds');
  like($@, qr{still truncated after 2 rounds}, 'and says so');
}

# --- no token at all
{
  my ($talk, $ua) = new_talk();
  $ua->queue(multistatus(undef, changed("$Coll/a.ics", '"ea"')));
  ok(!eval { $talk->SyncCollection($Coll); 1 }, 'a response without a sync-token dies');
  like($@, qr{No sync-token}, 'and says why');
}

# --- a "0" token is a token (SOGo, on an empty calendar)
{
  my ($talk, $ua) = new_talk();
  $ua->queue(multistatus('0'));
  my ($Added, $Removed, $Errors, $Token) = $talk->SyncCollection($Coll);
  is($Token, '0', '"0" is returned as the token');
}

# --- hrefs are unescaped, unless asked for raw
{
  my ($talk, $ua) = new_talk();
  $ua->queue(multistatus('u1', changed("$Coll/a%40b.ics", '"e"'), gone("$Coll/c%20d.ics")),
             multistatus('u2', changed("$Coll/a%40b.ics", '"e"')));
  my ($Added, $Removed) = $talk->SyncCollection($Coll);
  is_deeply([keys %$Added], ["$Coll/a\@b.ics"], 'added hrefs unescaped');
  is_deeply($Removed, ["$Coll/c d.ics"], 'removed hrefs unescaped');
  ($Added) = $talk->SyncCollection($Coll, raw => 1);
  is_deeply([keys %$Added], ["$Coll/a%40b.ics"], 'raw: hrefs as sent');
}

done_testing();
