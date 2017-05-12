#!perl -T
use strict;
use warnings;
use Test::More (tests => 8);
use Net::Mollom;

# ham content
my $mollom = Net::Mollom->new(
    private_key => '42d54a81124966327d40c928fa92de0f',
    public_key => '72446602ffba00c907478c8f45b83b03',
);
isa_ok($mollom, 'Net::Mollom');
$mollom->servers(['dev.mollom.com']);

# check parameter validation
eval { $mollom->get_image_captcha(foo => 1) };
ok($@);
like($@, qr/was not listed/);

SKIP: {
    my $url;
    eval { $url = $mollom->get_image_captcha() };
    skip("Can't reach Mollom servers", 5) if $@ && $@ =~ /no data/;
    ok($url);
    like($url, qr/^http:\/\//, "got URL $url");

    # now try after a content check
    my $check = $mollom->check_content(
        post_title => 'Foo Bar',
        post_body  => 'Lorem ipsum dolor sit amet',
    );
    isa_ok($check, 'Net::Mollom::ContentCheck');
    $url = $mollom->get_image_captcha();
    ok($url);
    like($url, qr/^http:\/\//, "got URL $url");
}
