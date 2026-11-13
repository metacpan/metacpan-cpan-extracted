#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Net::CardDAVTalk;

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
  return qq{<?xml version="1.0" encoding="utf-8"?>\n}
       . qq{<d:multistatus xmlns:d="DAV:" xmlns:card="urn:ietf:params:xml:ns:carddav">}
       . join('', @_)
       . qq{</d:multistatus>};
}

sub response {
  my ($href, @propstats) = @_;
  return "<d:response><d:href>$href</d:href>" . join('', @propstats) . "</d:response>";
}

sub propstat {
  my ($status, $props) = @_;
  my $s = defined $status ? "<d:status>HTTP/1.1 $status</d:status>" : '';
  return "<d:propstat><d:prop>$props</d:prop>$s</d:propstat>";
}

sub new_talk {
  my $ua = MockUA->new;
  my $talk = Net::CardDAVTalk->new(url => 'http://dav.example.com/addressbooks/user/');
  $talk->ua($ua);
  return ($talk, $ua);
}

my $Base = '/addressbooks/user/Default';

# SabreDAV-style PROPFIND response: every prop lives inside a propstat,
# and missing props come back in a separate 404 propstat.
my $Propfind = multistatus(
  # the collection itself
  response("$Base/",
    propstat('200 OK', '<d:resourcetype><d:collection/><card:addressbook/></d:resourcetype>'),
    propstat('404 Not Found', '<d:getcontenttype/><d:getetag/>'),
  ),
  # a normal card
  response("$Base/one.vcf",
    propstat('200 OK', '<d:getcontenttype>text/vcard; charset=utf-8</d:getcontenttype>'
                     . '<d:getetag>"etag-one"</d:getetag><d:resourcetype/>'),
  ),
  # legacy content type
  response("$Base/two.vcf",
    propstat('200 OK', '<d:getcontenttype>text/x-vcard</d:getcontenttype>'
                     . '<d:getetag>"etag-two"</d:getetag>'),
  ),
  # props split across two 200 propstats
  response("$Base/three.vcf",
    propstat('200 OK', '<d:getetag>"etag-three"</d:getetag>'),
    propstat('200 OK', '<d:getcontenttype>text/vcard</d:getcontenttype>'),
  ),
  # no content type from the server - assume it's a card
  response("$Base/four.vcf",
    propstat('200 OK', '<d:getetag>"etag-four"</d:getetag>'),
    propstat('404 Not Found', '<d:getcontenttype/>'),
  ),
  # not a card
  response("$Base/notes.txt",
    propstat('200 OK', '<d:getcontenttype>text/plain</d:getcontenttype>'
                     . '<d:getetag>"etag-notes"</d:getetag>'),
  ),
  # a sub-collection
  response("$Base/sub/",
    propstat('200 OK', '<d:resourcetype><d:collection/></d:resourcetype>'
                     . '<d:getetag>"etag-sub"</d:getetag>'),
  ),
  # server error for this resource
  response("$Base/broken.vcf",
    propstat('500 Internal Server Error', '<d:getetag/><d:getcontenttype/>'),
  ),
  # no status at all
  response("$Base/nostatus.vcf",
    propstat(undef, '<d:getetag>"etag-nostatus"</d:getetag>'),
  ),
);

my %Expected = (
  "$Base/one.vcf"   => '"etag-one"',
  "$Base/two.vcf"   => '"etag-two"',
  "$Base/three.vcf" => '"etag-three"',
  "$Base/four.vcf"  => '"etag-four"',
);

subtest 'GetContactLinks in list context' => sub {
  my ($talk, $ua) = new_talk();
  $ua->queue($Propfind);

  my ($Links, $Errors) = $talk->GetContactLinks('Default');

  is_deeply($Links, \%Expected, 'only vcard resources, with etags')
    or diag explain $Links;
  ok(!exists $Links->{Errors}, 'no Errors key mixed into the links');

  is(scalar @$Errors, 2, 'two errors') or diag explain $Errors;
  like($Errors->[0], qr{broken\.vcf: HTTP/1\.1 500}, 'error for 500 propstat');
  like($Errors->[1], qr{nostatus\.vcf: $}, 'error for propstat with no status');

  my $Req = $ua->requests->[0];
  is($Req->{method}, 'PROPFIND', 'sent a PROPFIND');
  is($Req->{uri}, "http://dav.example.com:80$Base/", 'to the collection');
  is($Req->{headers}{Depth}, 1, 'with Depth: 1');
  like($Req->{content}, qr{getcontenttype}, 'asks for getcontenttype');
  like($Req->{content}, qr{getetag}, 'asks for getetag');
  like($Req->{content}, qr{resourcetype}, 'asks for resourcetype');
};

subtest 'GetContactLinks in scalar context' => sub {
  my ($talk, $ua) = new_talk();
  $ua->queue($Propfind);

  my $Links = $talk->GetContactLinks('Default');
  is_deeply($Links, \%Expected, 'returns just the links hashref');
};

subtest 'GetContactLinks with an empty collection' => sub {
  my ($talk, $ua) = new_talk();
  $ua->queue(multistatus(
    response("$Base/",
      propstat('200 OK', '<d:resourcetype><d:collection/></d:resourcetype>'),
    ),
  ));

  my ($Links, $Errors) = $talk->GetContactLinks('Default');
  is_deeply($Links, {}, 'no links');
  is_deeply($Errors, [], 'no errors');
};

subtest 'GetContactLinks with a single response' => sub {
  # one response with one propstat exercises the XML array normalisation
  my ($talk, $ua) = new_talk();
  $ua->queue(multistatus(
    response("$Base/one.vcf",
      propstat('200 OK', '<d:getcontenttype>text/vcard</d:getcontenttype>'
                       . '<d:getetag>"etag-one"</d:getetag>'),
    ),
  ));

  my $Links = $talk->GetContactLinks('Default');
  is_deeply($Links, { "$Base/one.vcf" => '"etag-one"' }, 'found the card');
};

subtest 'GetContacts uses the links and passes errors through' => sub {
  my ($talk, $ua) = new_talk();
  $ua->queue($Propfind);

  my $Card = sub {
    my $name = shift;
    "BEGIN:VCARD\r\nVERSION:3.0\r\nUID:$name\r\nFN:$name\r\nEND:VCARD\r\n";
  };
  $ua->queue(multistatus(map {
    my ($name) = m{/(\w+)\.vcf$};
    response($_,
      propstat('200 OK', "<d:getetag>$Expected{$_}</d:getetag>"
                       . "<card:address-data>" . $Card->($name) . "</card:address-data>"),
    );
  } sort keys %Expected));

  my ($Contacts, $Errors, $HRefs) = $talk->GetContacts('Default');

  my $Report = $ua->requests->[1];
  is($Report->{method}, 'REPORT', 'then sent a multiget REPORT');
  my @Asked = $Report->{content} =~ m{<D:href>([^<]*)</D:href>}g;
  is_deeply(\@Asked, [sort keys %Expected], 'multiget asks for exactly the card hrefs');

  is_deeply([sort map { $_->{uid} } @$Contacts], [qw(four one three two)], 'got the cards');
  is_deeply($HRefs, \%Expected, 'hrefs and etags from the multiget');
  is(scalar @$Errors, 2, 'PROPFIND errors are passed through') or diag explain $Errors;
};

subtest 'SyncContactLinks' => sub {
  my ($talk, $ua) = new_talk();
  $ua->queue(multistatus(
    response("$Base/one.vcf",
      propstat('200 OK', '<d:getetag>"etag-one"</d:getetag>'),
      propstat('404 Not Found', '<card:address-data/>'),
    ),
    "<d:response><d:href>$Base/gone.vcf</d:href><d:status>HTTP/1.1 404 Not Found</d:status></d:response>",
    "<d:response><d:href>$Base/nostatus.vcf</d:href></d:response>",
    response("$Base/broken.vcf",
      propstat(undef, '<d:getetag>"etag-broken"</d:getetag>'),
    ),
    '<d:sync-token>http://example.com/sync/42</d:sync-token>',
  ));

  my ($Added, $Removed, $Errors, $SyncToken) = $talk->SyncContactLinks('Default');

  is_deeply($Added, { "$Base/one.vcf" => '"etag-one"' }, 'added');
  is_deeply($Removed, [ "$Base/gone.vcf" ], 'removed');
  is($SyncToken, 'http://example.com/sync/42', 'sync token');
  is(scalar @$Errors, 2, 'missing statuses are errors, not fatal warnings')
    or diag explain $Errors;
};

subtest 'SyncContactLinks follows a truncated response' => sub {
  my ($talk, $ua) = new_talk();
  my $trunc = "<d:response><d:href>$Base/</d:href><d:status>HTTP/1.1 507 Insufficient Storage</d:status></d:response>";
  $ua->queue(
    multistatus(response("$Base/a%40b.vcf", propstat('200 OK', '<d:getetag>"ea"</d:getetag>')),
                $trunc, '<d:sync-token>tok-1</d:sync-token>'),
    multistatus(response("$Base/two.vcf", propstat('200 OK', '<d:getetag>"e2"</d:getetag>')),
                '<d:sync-token>tok-2</d:sync-token>'),
  );

  my ($Added, $Removed, $Errors, $SyncToken) = $talk->SyncContactLinks('Default');

  is(scalar @{$ua->requests}, 2, 'asked again from the token it was given');
  like($ua->requests->[1]{content}, qr{<D:sync-token>tok-1</D:sync-token>}, 'with that token');
  is_deeply($Added, { "$Base/a\@b.vcf" => '"ea"', "$Base/two.vcf" => '"e2"' },
    'both pages, hrefs unescaped');
  is_deeply($Removed, [], 'the collection is not reported removed');
  is_deeply($Errors, [], 'nor is the 507 an error');
  is($SyncToken, 'tok-2', 'the last token');
};

subtest 'hrefs are unescaped, and escaped once on the way back' => sub {
  my ($talk, $ua) = new_talk();
  my $card = "BEGIN:VCARD\r\nVERSION:3.0\r\nUID:ab\r\nFN:A B\r\nN:B;A;;;\r\nEND:VCARD\r\n";

  # Google's CardDAV writes '@' as is in a PROPFIND, its CalDAV as %40:
  # either way the caller gets the same href
  $ua->queue(multistatus(
    response("$Base/a%40b.vcf", propstat('200 OK', '<d:getetag>"e1"</d:getetag>')),
    response("$Base/c d.vcf",   propstat('200 OK', '<d:getetag>"e2"</d:getetag>')),
  ));
  my $Links = $talk->GetContactLinks($Base);
  is_deeply([sort keys %$Links], ["$Base/a\@b.vcf", "$Base/c d.vcf"], 'GetContactLinks: unescaped');

  $ua->queue(multistatus(
    response("$Base/a%40b.vcf",
      propstat('200 OK', qq{<d:getetag>"e1"</d:getetag><card:address-data>$card</card:address-data>})),
  ));
  my ($Contacts, $Errors, $MLinks) = $talk->GetContactsMulti('Default', ["$Base/a\@b.vcf"]);
  like($ua->requests->[-1]{content}, qr{<D:href>/addressbooks/user/Default/a%40b\.vcf</D:href>},
    'GetContactsMulti: the href goes out escaped');
  is_deeply([keys %$MLinks], ["$Base/a\@b.vcf"], 'GetContactsMulti: links unescaped');
  is($Contacts->[0]{href}, "$Base/a\@b.vcf", 'and so is the card\'s href');
  is($Contacts->[0]{CPath}, 'Default/a@b.vcf', 'and its path');

  $ua->queue($card);
  $talk->GetContact("$Base/a\@b.vcf");
  is($ua->requests->[-1]{uri}, 'http://dav.example.com:80/addressbooks/user/Default/a%40b.vcf',
    'an href passed back is escaped once, not twice');

  $ua->queue(multistatus(
    response("$Base/a%40b.vcf",
      propstat('200 OK', qq{<d:getetag>"e1"</d:getetag><card:address-data>$card</card:address-data>})),
  ));
  $talk->GetContactAndProps('Default/a@b.vcf');
  like($ua->requests->[-1]{content}, qr{<D:href>/addressbooks/user/Default/a%40b\.vcf</D:href>},
    'GetContactAndProps: a relative path goes out as the escaped absolute href');

  $ua->queue(multistatus(
    response('/addressbooks/user/My%20Book/',
      propstat('200 OK', '<d:resourcetype><d:collection/><card:addressbook/></d:resourcetype><d:displayname>Mine</d:displayname>')),
  ));
  my $Books = $talk->GetAddressBooks();
  is($Books->[0]{href}, '/addressbooks/user/My Book/', 'GetAddressBooks: href unescaped');
  is($Books->[0]{path}, 'My Book', 'and path');
};

done_testing;
