#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Net::CalDAVTalk;

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
    return { success => 1, status => 207, reason => 'Multi-Status',
             protocol => 'HTTP/1.1', headers => {}, content => $Body };
  }
}

my $Cal = '/calendars/user/Default';
sub multistatus {
  my ($token, @r) = @_;
  return qq{<?xml version="1.0" encoding="utf-8"?>\n<d:multistatus xmlns:d="DAV:">}
       . join('', @r) . "<d:sync-token>$token</d:sync-token></d:multistatus>";
}
sub changed {
  my ($href, $etag) = @_;
  return "<d:response><d:href>$href</d:href><d:propstat><d:prop><d:getetag>$etag</d:getetag>"
       . "</d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response>";
}
sub status {
  my ($href, $status) = @_;
  return "<d:response><d:href>$href</d:href><d:status>HTTP/1.1 $status</d:status></d:response>";
}

my $ua = MockUA->new;
my $talk = Net::CalDAVTalk->new(url => 'http://dav.example.com/calendars/user/');
$talk->ua($ua);

# Google pages a calendar's sync: each page ends in a 507 on the collection
$ua->queue(
  multistatus('p1', changed("$Cal/a%40example.com.ics", '"ea"'), status("$Cal/", '507 Insufficient Storage')),
  multistatus('p2', changed("$Cal/b.ics", '"eb"'), status("$Cal/c.ics", '404 Not Found'),
                    status("$Cal/d.ics", '403 Forbidden')),
);
my ($Added, $Removed, $Errors, $Token) = $talk->SyncEventLinks('Default');

is(scalar @{$ua->requests}, 2, 'a truncated sync is asked again');
like($ua->requests->[1]{content}, qr{<D:sync-token>p1</D:sync-token>}, 'from the token it came with');
is_deeply($Added, { "$Cal/a\@example.com.ics" => '"ea"', "$Cal/b.ics" => '"eb"' },
  'both pages, hrefs unescaped as they always were');
is_deeply($Removed, ["$Cal/c.ics"], 'only a 404 is a removal: not the 507, not the 403');
is(scalar @$Errors, 1, 'the 403 is an error');
is($Token, 'p2', 'the last token');

# an href goes back out escaped, in the multiget body as in the URL
$ua->queue(qq{<?xml version="1.0" encoding="utf-8"?>\n<d:multistatus xmlns:d="DAV:"></d:multistatus>});
$talk->GetEventsMulti('Default', ["$Cal/a\@example.com.ics", "$Cal/c d.ics"]);
like($ua->requests->[-1]{content}, qr{<D:href>/calendars/user/Default/a%40example\.com\.ics</D:href>},
  'GetEventsMulti: hrefs escaped in the body');
like($ua->requests->[-1]{content}, qr{<D:href>/calendars/user/Default/c%20d\.ics</D:href>},
  'a space too');

done_testing();
