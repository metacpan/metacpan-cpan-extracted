#!perl

use Test2::V0;
use Test2::Require::Internet -tcp => [ 'dns.google', 53 ];    # dns.google should map to 8.8.8.8 or 8.8.4.4

use Test::File::ShareDir -share => {
    -dist => {
        "Robots-Validate" => "share"
    }
};

use Net::DNS::Resolver;

use Robots::Validate;

use experimental qw( signatures );

my $resolver = Net::DNS::Resolver->new(
    nameservers => ['dns.google'],
    recurse     => 0,
    debug       => 0,
);

my $rv = Robots::Validate->new( resolver => $resolver, validation_mode => 'first' );


subtest 'imessage' => sub {

    run_tests(
        [

            {
                line => __LINE__,
                args => [
                    '194.83.69.99',
"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_1) AppleWebKit/601.2.4 (KHTML, like Gecko) Version/9.0.1 Safari/601.2.4 facebookexternalhit/1.1 Facebot Twitterbot/1.0"
                ],
                res => "",
            },

        ]
    );

};

sub run_tests($tests) {

   for my $test ( $tests->@* ) {
        my @args = $test->{args}->@*;
        is $rv->validate(@args), $test->{res}, join( " ", sprintf( '[line %u]', $test->{line} ), @args );
    }


}

done_testing;
