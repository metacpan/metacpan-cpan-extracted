use strict;
use warnings;
use Test::More;
use PAD::Plugin;
use Plack::Request;

subtest basic => sub {
    my $request = Plack::Request->new({ PATH_INFO => '/foo' });

    my $plugin = PAD::Plugin->new(
        plugin  => 'PAD::Plugin::Static',
        extra   => 'foo',
        request => $request,
    );

    isa_ok $plugin, 'PAD::Plugin';

    is_deeply { %$plugin }, {
        plugin  => 'PAD::Plugin::Static',
        extra   => 'foo',
        request => $request,
    };

    is $plugin->suffix, qr/.+/;
    is $plugin->content_type, 'text/plain; charset=UTF-8';

    isa_ok $plugin->request, 'Plack::Request';

    is $plugin->relative_path, './foo';

    is_deeply $plugin->execute, [ 501, [], [] ];
};

subtest 'null path info' => sub {
    my $request = Plack::Request->new({ PATH_INFO => "/foo\0bar" });
    my $plugin  = PAD::Plugin->new(
        plugin  => 'PAD::Plugin::Static',
        request => $request,
    );

    note explain eval { $plugin->relative_path };
    note explain $@;
    like $@, qr/Bad Request/;
};

subtest traverse => sub {
    my $request = Plack::Request->new({
        PATH_INFO => "/../../../etc/passwd.t"
    });

    my $plugin  = PAD::Plugin->new(
        plugin  => 'PAD::Plugin::Static',
        request => $request,
    );

    note explain eval { $plugin->relative_path };
    note explain $@;
    like $@, qr/Forbidden/;
};

subtest 'directory traversal' => sub {
    my $request = Plack::Request->new({
        PATH_INFO => "/../Makefile.PL"
    });

    my $plugin  = PAD::Plugin->new(
        plugin  => 'PAD::Plugin::Static',
        request => $request,
    );

    note explain eval { $plugin->relative_path };
    note explain $@;
    like $@, qr/Forbidden/;
};

done_testing;

