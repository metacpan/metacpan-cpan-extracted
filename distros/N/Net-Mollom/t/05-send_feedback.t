#!perl -T
use strict;
use warnings;
use Test::More (tests => 9);
use Net::Mollom;
use Exception::Class::TryCatch qw(catch);

# ham content
my $mollom = Net::Mollom->new(
    private_key => '42d54a81124966327d40c928fa92de0f',
    public_key => '72446602ffba00c907478c8f45b83b03',
);
isa_ok($mollom, 'Net::Mollom');
$mollom->servers(['dev.mollom.com']);

my $check;
SKIP: {
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
    skip("Can't reach Mollom servers", 8) if catch(['Net::Mollom::CommunicationException']);
    isa_ok($check, 'Net::Mollom::ContentCheck');
    ok($check->is_ham, 'it is ham');

    # test parameter validation
    eval { $mollom->send_feedback };
    ok($@);
    like($@, qr/'feedback' missing/);
    eval { $mollom->send_feedback(feedback => 'sucks') };
    ok($@);
    like($@, qr/did not pass regex check/);

    sleep(1);
    my $results = $mollom->send_feedback(feedback => 'unwanted');
    ok($results);

    # specifying the session_id
    sleep(1);
    $results = $mollom->send_feedback(feedback => 'unwanted', session_id => 123);
    ok($results);
}
