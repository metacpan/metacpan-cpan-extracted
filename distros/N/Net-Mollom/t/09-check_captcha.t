#!perl -T
use strict;
use warnings;
use Test::More (tests => 6);
use Net::Mollom;
use Exception::Class::TryCatch qw(catch);

# ham content
my $mollom = Net::Mollom->new(
    private_key => '42d54a81124966327d40c928fa92de0f',
    public_key => '72446602ffba00c907478c8f45b83b03',
);
isa_ok($mollom, 'Net::Mollom');
$mollom->servers(['dev.mollom.com']);

# check parameter validation
eval { $mollom->check_captcha() };
ok($@);
like($@, qr/missing/, 'needs a solution');

SKIP: {
    my $url;
    eval { $url = $mollom->get_image_captcha };
    skip("Can't reach Mollom servers", 3) if catch(['Net::Mollom::CommunicationException']);
    ok($url);

    # now test it out
    my $result = $mollom->check_captcha(solution => 'incorrect');
    ok(!$result, 'solution incorrect');
    $result = $mollom->check_captcha(solution => 'correct');
    ok($result, 'solution correct');
}
