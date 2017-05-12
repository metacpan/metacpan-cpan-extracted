use strict;
use warnings;

package # no_index
  V2Tester;

use Test::More 0.96;
use Test::MockModule;
use Test::XPath;

use parent 'Exporter';
our @EXPORT = (
  qw(
    class
    notify
    $xml_root
    not_present
    tags_are
    vars_are
    decode_utf8
  ),
  @Test::More::EXPORT,
);

my $mod = 'Net::Airbrake::V2';
eval "require $mod" or die $@;

warn "Net::Airbrake VERSION may not be compatible"
  if Net::Airbrake->VERSION ne '0.02';

our $xml_root = '/notice';

sub class { $mod }

sub not_present {
  my ($tx, $parent, $tags) = @_;
  subtest "not present (in $parent)" => sub {
    foreach my $tag ( @$tags ){
      $tx->not_ok("$xml_root/$parent/$tag", $tag);
    }
  };
}

sub tags_are {
  my ($tx, $parent, $vals) = @_;
  subtest $parent => sub {
    while( my ($tag, $content) = each %$vals ){
      $tx->is("$xml_root/$parent/$tag", $content, $tag);
    }
  };
}

sub vars_are {
  my ($tx, $parent, $vars) = @_;

  my $count = 0;
  $tx->ok(qq!$xml_root/request/$parent!, sub { ++$count }, $parent);
  is $count, 1, "$parent occurs once";

  subtest $parent => sub {
    while( my ($key, $val) = each %$vars ){
      $tx->is(qq!$xml_root/request/$parent/var[\@key="$key"]!,
        $val, "$parent var $key");
    }
  };
}

sub notify {
  my ($test) = @_;
  my %config = %{ $test->{config} };

  my $client = new_ok($mod, [%config]);

  my $mock = Test::MockModule->new('HTTP::Tiny');

  my ($exp_res) = map { { id  => $_, url => "https://example.com/locate/$_" } }
    '9ef134aa-2118-9e28-fc51-cd52ecf75b91';

  my @req;
  $mock->mock(request => sub {
    push @req, [ @_[1,2,3] ];
    return {
      success => 1,
      status  => 200,
      headers => { 'Content-Type' => 'application/xml' },
      content => <<XML,
  <notice>
    <id>$exp_res->{id}</id>
    <url>$exp_res->{url}</url>
  </notice>
XML
    };
  });

  my $res = $test->{code}->($client);

  ok $res, 'response';
  is $res->{$_}, $exp_res->{$_}, "response $_"
    for qw( id url );

  is scalar(@req), 1, 'one request';

  is $req[0][0], 'POST', 'http post';
  is $req[0][1], "$config{base_url}/notifier_api/v2/notices",
    'base url with v2 suffix';

  is $req[0][2]->{headers}{ 'Content-Type' }, 'application/xml',
    'request content type';

  my $xml = $req[0][2]->{content};

  like $xml, qr/^\Q<?xml version="1.0" encoding="utf-8"?>\E/,
    'xml declaration with encoding';

  my $tx = Test::XPath->new(xml => $xml);

  $tx->is("$xml_root/\@version", '2.3', 'notice tag with version attribute');

  $tx->is(
    "$xml_root/server-environment/environment-name",
    $test->{config}{environment_name},
    'server environment name'
  );

  tags_are($tx, notifier => {
    name    => $mod,
    version => $mod->VERSION || '',
    url     => "https://metacpan.org/pod/$mod"
  });

  return {
    %$test,
    response => $res,
    client   => $client,
    xml      => $xml,
    tx       => $tx,
  };
}

sub decode_utf8 {
  my $x = shift;
  utf8::decode($x);
  return $x;
}

1;
