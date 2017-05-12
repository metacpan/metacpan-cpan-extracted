use Test::Most;
use String::CamelSnakeKebab qw/http_header_case/;

my %tests = (
    "user-agent"       => "User-Agent",
    "dnt"              => "DNT",
    "remote-ip"        => "Remote-IP",
    "te"               => "TE",
    "ua-cpu"           => "UA-CPU",
    "x-ssl-cipher"     => "X-SSL-Cipher",
    "x-wap-profile"    => "X-WAP-Profile",
    "x-xss-protection" => "X-XSS-Protection",
);

cmp_deeply http_header_case($_) => $tests{$_}, 
    sprintf("%20s -> %s", $tests{$_}, $_)
        for keys %tests;

done_testing;
