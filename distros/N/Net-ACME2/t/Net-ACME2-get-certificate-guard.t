#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::FailWarnings;

use Digest::MD5;
use HTTP::Status;
use URI;
use JSON;

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::ACME2_Server;

#----------------------------------------------------------------------

{
    package MyCA;

    use parent qw( Net::ACME2 );

    use constant {
        HOST => 'acme.someca.net',
        DIRECTORY_PATH => '/acme-directory',
    };
}

my $_RSA_KEY = <<END;
-----BEGIN RSA PRIVATE KEY-----
MIICWwIBAAKBgQCkOYWppsEFfKHqIntkpUjmuwnBH3sRYP00YRdIhrz6ypRpxX6H
c2Q0IrSprutu9/dUy0j9a96q3kRa9Qxsa7paQj7xtlTWx9qMHvhlrG3eLMIjXT0J
4+MSCw5LwViZenh0obBWcBbnNYNLaZ9o31DopeKcYOZBMogF6YqHdpIsFQIDAQAB
AoGAN7RjSFaN5qSN73Ne05bVEZ6kAmQBRLXXbWr5kNpTQ+ZvTSl2b8+OT7jt+xig
N3XY6WRDD+MFFoRqP0gbvLMV9HiZ4tJ/gTGOHesgyeemY/CBLRjP0mvHOpgADQuA
+VBZmWpiMRN8tu6xHzKwAxIAfXewpn764v6aXShqbQEGSEkCQQDSh9lbnpB/R9+N
psqL2+gyn/7bL1+A4MJwiPqjdK3J/Fhk1Yo/UC1266MzpKoK9r7MrnGc0XjvRpMp
JX8f4MTbAkEAx7FvmEuvsD9li7ylgnPW/SNAswI6P7SBOShHYR7NzT2+FVYd6VtM
vb1WrhO85QhKgXNjOLLxYW9Uo8s1fNGtzwJAbwK9BQeGT+cZJPsm4DpzpIYi/3Zq
WG2reWVxK9Fxdgk+nuTOgfYIEyXLJ4cTNrbHAuyU8ciuiRTgshiYgLmncwJAETZx
KQ51EVsVlKrpFUqI4H72Z7esb6tObC/Vn0B5etR0mwA2SdQN1FkKrKyU3qUNTwU0
K0H5Xm2rPQcaEC0+rwJAEuvRdNQuB9+vzOW4zVig6HS38bHyJ+qLkQCDWbbwrNlj
vcVkUrsg027gA5jRttaXMk8x9shFuHB9V5/pkBFwag==
-----END RSA PRIVATE KEY-----
END

#----------------------------------------------------------------------

my $server = Test::ACME2_Server->new( ca_class => 'MyCA' );

my $acme = MyCA->new(
    key => $_RSA_KEY,
    directory => MyCA->DIRECTORY_PATH(),
);

$acme->create_account(
    termsOfServiceAgreed => 1,
);

# Create an order — it starts in 'pending' status with no certificate URL
my @domains = ('example.com');
my $order = $acme->create_order(
    identifiers => [ map { { type => 'dns', value => $_ } } @domains ],
);

is( $order->status(), 'pending', 'new order is pending' );
is( $order->certificate(), undef, 'pending order has no certificate URL' );

# get_certificate_chain() must throw when certificate URL is not set
throws_ok(
    sub { $acme->get_certificate_chain($order) },
    qr/certificate/i,
    'get_certificate_chain() throws on order without certificate URL',
);

# get_certificate_chains() must throw the same way
throws_ok(
    sub { $acme->get_certificate_chains($order) },
    qr/certificate/i,
    'get_certificate_chains() throws on order without certificate URL',
);

# Now also test with an explicitly non-valid status
# (Simulate an order that has status 'processing' but no cert URL)
$order->update({ status => 'processing', certificate => undef });

throws_ok(
    sub { $acme->get_certificate_chain($order) },
    qr/certificate/i,
    'get_certificate_chain() throws for processing order',
);

done_testing();
