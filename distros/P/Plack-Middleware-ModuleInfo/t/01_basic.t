use warnings;
use strict;
use Plack::Builder;
use HTTP::Request::Common;
use File::Spec;
use Plack::Test;
use Test::More;

{
    my $app = builder {
        enable 'ModuleInfo',
            allow => '0.0.0.0/0',
            path  => '/module_info';
        sub { [200,[],['OK']] };
    };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/module_info');

        is $res->code, 200;

        like $res->content, qr{PID:\s*\d+};
        like $res->content, qr{lib:};

        note $res->content if $ENV{AUTHOR_TEST};
    };
}

{
    my $app = builder {
        enable 'ModuleInfo',
            allow => '0.0.0.0/0',
            path  => '/module_info';
        sub { [200,[],['OK']] };
    };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/module_info?ThisIsNotFoundModule');

        is $res->code, 200;

        like $res->content, qr{PID:\s*\d+};
        like $res->content, qr{lib:};
        like $res->content, qr{module:\s*"'ThisIsNotFoundModule' not found};

        note $res->content if $ENV{AUTHOR_TEST};
    };
}

{
    my $app = builder {
        enable 'ModuleInfo',
            allow => '0.0.0.0/0',
            path  => '/module_info';
        sub { [200,[],['OK']] };
    };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/module_info?Plack-Middleware-ModuleInfo');

        is $res->code, 200;

        like $res->content, qr{module:};
        like $res->content, qr{name:.*Plack::Middleware::ModuleInfo};
        like $res->content, qr{version:.*$Plack::Middleware::ModuleInfo::VERSION};
        my $expect = quotemeta File::Spec->catfile(qw/Plack Middleware ModuleInfo/);
        like $res->content, qr{file:.*$expect};

        note $res->content if $ENV{AUTHOR_TEST};
    };
}

{
    my $app = builder {
        enable 'ModuleInfo',
            allow => [],
            path  => '/module_info';
        sub { [200,[],['OK']] };
    };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/module_info');
        is $res->code, 403;

        my $res_foo = $cb->(GET '/foo');
        is $res_foo->code, 200;
    };
}

done_testing;
