#!/usr/bin/perl
use strict;
use warnings;
use Mojo::ByteStream 'b';
use Test::Mojo;
use Mojolicious::Lite;

use Test::More;
use Test::Warn;

my $poco_ns  = 'http://www.w3.org/TR/2011/WD-contacts-api-20110616/';
my $xhtml_ns = 'http://www.w3.org/1999/xhtml';

use_ok('Mojolicious::Plugin::XML::Loy');

# Plugin helper
my $t = Test::Mojo->new;
my $app = $t->app;

$app->log->level('error');

ok($app->plugin('XML::Loy' => {
  new_atom => [-Atom],
  new_atom_threading => [-Atom,-Atom::Threading],
  new_myxml => [-Loy, -Atom],
  new_hostmeta => [-XRD, -HostMeta],
  max_size => 700
}), 'New plugin');

ok(my $atom = $app->new_atom('feed'), 'Create new feed');

ok(my $atom_string = $atom->to_pretty_xml, 'Create pretty xml');
$atom_string =~ s/[\s\r\n]+//g;

is ($atom_string, '<?xmlversion="1.0"encoding="UTF-8'.
                  '"standalone="yes"?><feedxmlns="ht'.
                  'tp://www.w3.org/2005/Atom"/>',
                  'Initial Atom');

ok(my $entry = $atom->entry(id => '#33775'), 'Add entry');

ok(my $person = $atom->new_person(
  name => 'Bender',
  uri => 'http://sojolicio.us/bender'
), 'Add person');

$person->namespace('poco' => $poco_ns);
$person->add('uri', 'http://sojolicio.us/fry');
$person->add('poco:birthday' => '1/1/1970');


ok($entry->author($person), 'Add author');

is($atom->at('author name')->text, 'Bender', 'Author-Name');
is($atom->at('author uri')->text, 'http://sojolicio.us/bender', 'Author-URI');
is($atom->at('author birthday')->text, '1/1/1970', 'Author-Poco-Birthday');
is($atom->at('author birthday')->namespace, $poco_ns, 'Author-Poco-NS');

ok($atom->title(
  type => 'html',
  content => 'Dies ist <b>html</b> Inhalt.'
), 'Add title');

ok($atom->content(
  type => 'xhtml',
  content => 'This is <b>xhtml</b> content!'
), 'Add content');

ok(my $atom2 = $app->new_atom($atom->to_pretty_xml), 'Parse xml');

is($atom2->at('content div b')->text, 'xhtml', 'Pretty Print');

warning_is { $atom->in_reply_to('http://sojolicio.us') } q{Can't locate "in_reply_to" in "XML::Loy::Atom"}, "No threading";


# Test Threading
ok($entry = $app->new_atom_threading('entry'), 'New atom document');

is($entry->at(':root')->namespace, 'http://www.w3.org/2005/Atom', 'Namespace');

ok($person = $entry->new_person(name => 'Zoidberg'), 'New person');

ok($entry->author($person), 'Add author');

is($entry->at('entry > author > name')->text, 'Zoidberg', 'Name');

ok($entry->contributor($person), 'Contributor');

is($entry->at('entry > contributor > name')->text, 'Zoidberg', 'Name');

$entry->id('http://sojolicio.us/blog/2');

is($entry->at('entry')->attr->{'xml:id'}, 'http://sojolicio.us/blog/2', 'id');
is($entry->at('entry id')->text, 'http://sojolicio.us/blog/2', 'id');

ok($entry->replies('http://sojolicio.us/entry/1/replies' => {
  count => 5,
  updated => '500000'
}), 'Add replies entry');

ok(my $link = $entry->at('link[rel="replies"]'), 'Get replies link');
is($link->attr('thr:count'), 5, 'Thread Count');
is($link->attr('thr:updated'), '1970-01-06T18:53:20Z', 'Thread update');
is($link->attr('href'), 'http://sojolicio.us/entry/1/replies', 'Thread href');
is($link->attr('type'), 'application/atom+xml', 'Thread type');
is($link->namespace, 'http://www.w3.org/2005/Atom', 'Thread namespace');

ok($entry->total(8), 'Set total');

is($entry->at('total')->text, 8, 'Total number');
is($entry->at('total')->namespace,
   'http://purl.org/syndication/thread/1.0',
   'Total namespace'
 );

ok($entry->in_reply_to(
  'http://sojolicio.us/blog/1' => {
    href => 'http://sojolicio.us/blog/1x'
  }), 'Add in-reply-to');

is($entry->at('in-reply-to')->namespace,
   'http://purl.org/syndication/thread/1.0', 'In-reply-to namespace');

is($entry->at('in-reply-to')->attr('href'),
   'http://sojolicio.us/blog/1x', 'In-reply-to href');

is($entry->at('in-reply-to')->attr('ref'),
   'http://sojolicio.us/blog/1', 'In-reply-to ref');

ok(my $atom3 = $app->new_myxml('test'), 'New object');
is($atom3->mime, 'application/xml', 'Mime');
ok(my $myelem = $atom3->add('myelem'), 'New element');
ok($myelem->author(name => 'Mario'), 'Add author name');

is($myelem->mime, 'application/xml', 'Mime');

is($myelem->tag, 'myelem', 'Mime');
is($myelem->namespace, undef, 'Mime');
is($myelem->at('name')->namespace, 'http://www.w3.org/2005/Atom', 'Mime');


# Render
get '/' => sub {
  my $c = shift;
  my $entry = $c->new_atom_threading('entry');
  $entry->author(name => 'Akron');

  # Deprecated but tested!
  my $warn;
  local $SIG{__WARN__} = sub { $warn = shift };
  my $return = $c->render_xml($entry);
  like($warn, qr!\Qrender_xml is deprecated in favor of reply->xml\E!);
  return $return;
};

get '/xml' => sub {
  my $c = shift;
  my $entry = $c->new_xml(test => { root => 'yes' } => 'Works!');
  return $c->reply->xml($entry);
};

get '/fail' => sub {
  my $c = shift;
  my $entry = $c->new_xml(test => { root => 'yes' } => 'Works!');
  return $c->reply->xml($entry, status => 400);
};

$t->get_ok('/')
  ->content_like(qr{<author>})
  ->content_like(qr{<name>Akron</name>})
  ->content_type_is('application/atom+xml')
  ->status_is(200);

$t->get_ok('/xml')
  ->content_like(qr{<test})
  ->content_like(qr{root="yes"})
  ->content_type_is('application/xml')
  ->status_is(200);

$t->get_ok('/fail')
  ->content_like(qr{<test})
  ->content_like(qr{root="yes"})
  ->text_is(':root', 'Works!')
  ->content_type_is('application/xml')
  ->status_is(400);

get '/utf-8' => sub {
  my $c = shift;
  my $entry = $c->new_xml(test => { root => 'yes' } => 'Wörks!');
  $entry->add('yeah' => 'üöä');
  return $c->reply->xml($entry, status => 400);
};

$t->get_ok('/utf-8')
  ->content_like(qr{<test})
  ->content_like(qr{root="yes"})
  ->content_type_is('application/xml')
  ->text_like(':root', qr/\s*Wörks!\s*/)
  ->text_is('yeah', 'üöä')
  ->status_is(400);


# Max size
ok($atom->add('Further' => 'This expands it')->add('Even' => 'further'),
   'Extend object');
ok(!($atom2 = $app->new_atom($atom->to_pretty_xml)), 'Parse xml');
ok(!$atom2, 'To big');


get '/hostmeta' => sub {
  my $c = shift;
  my $xrd = $c->new_hostmeta;
  $xrd->host('sojolicio.us');

  # Render document with the correct mime-type
  return $c->reply->xml($xrd);
};

$t->get_ok('/hostmeta')
  ->content_like(qr{<hm:Host})
  ->content_like(qr{xmlns:xsi})
  ->content_like(qr{xmlns:hm})
  ->content_type_is('application/xrd+xml')
  ->text_is('Host', 'sojolicio.us')
  ->status_is(200);


ok($app->plugin('XML::Loy' => {
  new_atom => [-Atom]
}), 'Again create new_atom');

ok(my $xml = $app->new_myxml(feed => 'Hey!'), 'New XML');
ok($xml = $app->new_atom('feed'), 'New XML');


done_testing;

__END__
