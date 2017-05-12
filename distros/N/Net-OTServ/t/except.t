use Test::More;
use Test::Exception;

BEGIN {
    use_ok 'Net::OTServ';
}

throws_ok { Net::OTServ::status 'example.com' } qr/offline/;
throws_ok { Net::OTServ::status 'unused.a3f.at', 7171 } qr/offline/;
throws_ok { Net::OTServ::status 'a3f.at', 80 } qr/reply|offline/i;

done_testing;


