use 5.012;
use lib 't/lib';
use MyTest;
use Test::More;
use Test::Catch;
use Protocol::HTTP::Response;

catch_run('[cookie_jar]');

subtest "simple API test" => sub {
    my $jar = Protocol::HTTP::CookieJar->new;
    my $origin = URI::XS->new('http://crazypanda.ru/home');
    $jar->add("c1", { value => "v1", domain => 'crazypanda.ru' }, $origin);
    $jar->add("c2", { value => "v2", domain => 'crazypanda.ru', path => "/something" }, $origin);
    is scalar(@{ $jar->all_cookies->{"crazypanda.ru"}}), 2;

    subtest "(de)serialization" => sub {
        my $data = $jar->to_string(1);
        my $jar2 = Protocol::HTTP::CookieJar->new($data);
        my ($err, $all) = Protocol::HTTP::CookieJar::parse_cookies($data);
        is_deeply $jar2->all_cookies, $all;
        ok !$err;

        $jar2->clear;
        is_deeply $jar2->all_cookies, {};
    };

    subtest "find" => sub {
        my $cookies = $jar->find(URI::XS->new('http://crazypanda.ru/h'));
        is_deeply $cookies, [{
            path      => '/home',
            domain    => 'crazypanda.ru',
            name      => 'c1',
            value     => 'v1',
            secure    => 0,
            http_only => 0,
            host_only => '',
            same_site => COOKIE_SAMESITE_DISABLED,
        }];
    };

    subtest "collect & populate" => sub {
        $jar->set_ignore(sub {
            my ($name, $coo) = @_;
            return scalar($name =~ /^unsecure/);
        });
        my $res = Protocol::HTTP::Response->new({
            cookies => {
                c3 => {
                    value  => "v3",
                    domain => "crazypanda.ru",
                },
                unsecure => {
                    value  => "v4",
                    domain => "crazypanda.ru",
                },
            },
        });
        $jar->collect($res, "http://crazypanda.ru/games");
        is scalar(@{ $jar->all_cookies->{"crazypanda.ru"}}), 3;

        my $req = Protocol::HTTP::Request->new({ uri => "http://crazypanda.ru/" });
        $jar->populate($req);
        is_deeply [sort keys %{ $req->cookies }], [qw/c1 c2 c3/];
    };

    subtest "remove" => sub {
        $jar->remove("crazypanda.ru", "", "/home");
        is scalar(@{ $jar->all_cookies->{"crazypanda.ru"}}), 2;
    };
};

done_testing;
