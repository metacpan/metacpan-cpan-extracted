#!perl -T
use strict;
use warnings;
use Test::More (tests => 17);
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
my $check;
eval { $check = $mollom->check_content(foo => 1) };
ok($@);
like($@, qr/was not listed/);
ok(!$check);

eval { $check = $mollom->check_content() };
ok($@);
like($@, qr/at least 1/, 'checking required parameters');
ok(!$check);

SKIP: {
    # now do the real thing
    eval {
        $check = $mollom->check_content(
            post_title => 'Foo Bar',
            post_body => q/
                Lorem ipsum dolor sit amet, consectetur adipiscing elit. 
                Mauris ultricies, lorem in gravida rhoncus, tortor dui viverra magna, 
                vitae vehicula neque ligula et nibh. Pellentesque habitant morbi tristique 
                senectus et netus et malesuada fames ac turpis egestas. Etiam et libero. 
                Vivamus orci.
            /,
        );
    };
    skip("Can't reach Mollom servers", 10) if catch(['Net::Mollom::CommunicationException']);
    isa_ok($check, 'Net::Mollom::ContentCheck');
    ok($check->is_ham, 'it is ham');
    ok(!$check->is_spam, 'it is not spam');
    ok(!$check->is_unsure, 'it is not unsure');
    cmp_ok($check->quality, '>', 0, 'testing content has some quality');

    $check = $mollom->check_content(
        post_title => 'spam, buy some v1@grA!',
        post_body => 'spam',
    );
    isa_ok($check, 'Net::Mollom::ContentCheck');
    ok(!$check->is_ham, 'it is not ham');
    ok($check->is_spam, 'it is spam');
    ok(!$check->is_unsure, 'it is not unsure');
    cmp_ok($check->quality, '==', 0.0, 'spam content has no quality');
}
