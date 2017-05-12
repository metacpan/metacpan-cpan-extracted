use strict;
use warnings;

use Test::More;
use Test::Deep;

BEGIN { use_ok('Net::Hadoop::WebHDFS'); }
require_ok('Net::Hadoop::WebHDFS');

subtest 'check_success_json' => sub {
    my $c = Net::Hadoop::WebHDFS->new();

    ok ($c->check_success_json({code => 200, content_type => 'application/json', body => ''}));
    ok ($c->check_success_json({code => 200, content_type => 'application/json', body => '{"boolean":true}'}, 'boolean'));
    ok ($c->check_success_json({code => 200, content_type => 'application/json', body => '{"boolean":true}'}, 'boolean'));

    ok (! $c->check_success_json({code => 200, content_type => 'text/html', body => ''}));
    ok (! $c->check_success_json({code => 404, content_type => 'application/json', body => ''}));
    ok (! $c->check_success_json({code => 500, content_type => 'application/json', body => ''}));
    ok (! $c->check_success_json({code => 200, content_type => 'application/json', body => '{"boolean":true}'}, 'hogepos'));

    cmp_deeply($c->check_success_json({code => 200, content_type => 'application/json', body => '{"msg":{"x":1,"y":"yyy"}}'}, 'msg'),
               {x => 1, y => 'yyy'});
};

subtest 'api_path' => sub {
    my $c = Net::Hadoop::WebHDFS->new();

    is ($c->api_path('/'), '/webhdfs/v1/');
    is ($c->api_path('/foo/bar'), '/webhdfs/v1/foo/bar');
    is ($c->api_path('file1'), '/webhdfs/v1/file1');
};

subtest 'build_path' => sub {
    my $c = Net::Hadoop::WebHDFS->new();

    is ($c->build_path('/', 'OPEN'), '/webhdfs/v1/?op=OPEN');
    like ($c->build_path('/foo', 'MKDIRS', permission => '0600'),
          qr{^/webhdfs/v1/foo\?(op=MKDIRS&permission=0600|permission=0600&op=MKDIRS)$}
      );
    like ($c->build_path('/foo', 'RENAME', destination => '/foo bar'),
          qr{^/webhdfs/v1/foo\?(destination=%2Ffoo\+bar&op=RENAME|op=RENAME&destination=%2Ffoo\+bar)$}
      );

    $c = Net::Hadoop::WebHDFS->new(username => 'hadoop');
    like ($c->build_path('/', 'OPEN'), qr!^/webhdfs/v1/\?(op=OPEN&user\.name=hadoop|user\.name=hadoop&op=OPEN)!);
    cmp_bag([split(m!&!, (split(m!\?!, $c->build_path('/foo', 'MKDIRS', permission => '0600')))[1])],
            ['op=MKDIRS', 'permission=0600', 'user.name=hadoop']);

    $c = Net::Hadoop::WebHDFS->new(username => 'hadoop', doas => 'maskman');
    cmp_bag([split(m!&!, (split(m!\?!, $c->build_path('/', 'OPEN')))[1])],
            ['op=OPEN', 'user.name=hadoop', 'doas=maskman']);
    cmp_bag([split(m!&!, (split(m!\?!, $c->build_path('/foo', 'MKDIRS', permission => '0600')))[1])],
            ['op=MKDIRS', 'permission=0600', 'user.name=hadoop', 'doas=maskman']);

};

done_testing;
