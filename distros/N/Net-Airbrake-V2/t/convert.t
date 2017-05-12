use strict;
use warnings;
use utf8;
use lib 't/lib';
use V2Tester;

subtest 'full' => sub {
  my $test = notify({
    config => {
      environment_name => 'test',
      base_url => 'https://example.com/net-airbrake-v2/blah',
    },
    code => sub {
      eval { die 'エラー！！' };
      return shift->notify($@, {
        context => {
          url       => 'u',
          component => 'c',
          action    => 'a',
          rootDirectory => '/tmp',
          version       => '1.0',
        },
        # Test nested structures.
        params      => {
          p1 => 'p2',
          h1 => {
            k1 => 'pi',
            k2 => ['g', 'g'],
            'h<>3' => {
              'a b' => [1, {c => 7, '&' => qq[<hi there="you\x95"/>], n => undef}],
              u => "❤",
            }
          }
        },
        session     => { s1 => 's2' },
        # Test more than one var.
        environment => { e1 => 'e2', x => 'y' },
      });
    },
  });

  my $tx = $test->{tx};
  #diag $test->{xml};

  ok !utf8::is_utf8($test->{xml}), 'xml is bytes';
  like $test->{xml}, qr/\xE2\x9D\xA4/, 'xml is utf8-encoded';

  tags_are($tx, error => {
    class   => 'CORE::die', # Net::Airbrake fabricates this.
    message => 'エラー！！',
  });

  $tx->ok("$xml_root/error/backtrace/line[1]", sub {
    my ($bt) = @_;
    $bt->is('./@file',     __FILE__, 'file');
    $bt->like('./@number', qr/\d+/,  'line number');
    $bt->is('./@method',   'N/A',    'function');
  }, 'error backtrace');

  tags_are($tx, request => {
    url       => 'u',
    component => 'c',
    action    => 'a',
  });

  vars_are($tx, 'params',   { 'p1' => 'p2' });
  vars_are($tx, 'params/var[@key="h1"]', {
    k1 => 'pi',
    k2 => '["g","g"]',
  });
  vars_are($tx, 'params/var[@key="h1"]/var[@key="h<>3"]', {
    'a b' => '[1,{"&" => "<hi there=\"you\x{95}\"/>","c" => 7,"n" => undef}]',
    # Test::XPath uses XML::LibXML which will result in a character string.
    'u'   => decode_utf8("\xE2\x9D\xA4"),
  });

  vars_are($tx, 'session',  { 's1' => 's2' });

  vars_are($tx, 'cgi-data', { 'e1' => 'e2', x => 'y'});

  tags_are($tx, 'server-environment' => {
    'environment-name' => 'test',
    'project-root'     => '/tmp',
    'app-version'      => '1.0',
  });
};

subtest 'minimal' => sub {
  my $test = notify({
    config => {
      environment_name => 'tiny',
      base_url => 'https://example.com/err',
    },
    code => sub {
      shift->notify('Oops');
    },
  });

  my $tx = $test->{tx};

  tags_are($tx, error => {
    class   => 'error', # Net::Airbrake fabricates this.
    message => 'Oops',
  });

  $tx->ok("$xml_root/error/backtrace", 'backtrace required');

  not_present($tx, request => [qw(
    url
    component
    action
    params
    session
    cgi-data
  )]);

  not_present($tx, 'server-environment' => [qw(
    project-root
    app-version
  )]);
};

subtest 'convert_*' => sub {
  my $req = class()->convert_request({}, {api_key => 'ak'});

  is ref($req), 'HASH', 'ref in, ref out';

  is eval { $req->{notice}{'api-key'}[0] }, 'ak', 'data';

  my $res = class()->convert_response({x => 'y'});

  is ref($res), 'HASH', 'ref in, ref out';

  is eval { $res->{x} }, 'y', 'data';
};

done_testing;
