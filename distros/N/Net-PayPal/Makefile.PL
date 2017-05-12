use 5.014002;
use ExtUtils::MakeMaker;
use Term::ANSIColor;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Net::PayPal',
    VERSION_FROM => 'lib/Net/PayPal.pm',
    PREREQ_PM    => {
        'Cache::FileCache' => undef,
        'LWP::UserAgent'   => undef,
        'JSON'             => undef,
        'Crypt::SSLeay'    => undef,
        'Test::More'       => undef,
        'Crypt::CBC'       => undef,
        'Crypt::Blowfish'  => undef
    },
    (
        $] >= 5.005
        ? (
            ABSTRACT_FROM => 'lib/Net/PayPal.pm',
            AUTHOR        => 'Sherzod B. Ruzmetov <sherzodr@cpan.org>'
          )
        : ()
    ),
);


unless ($ENV{NET_PAYPAL_CLIENT_ID} && $ENV{NET_PAYPAL_SECRET}) {
    print color("bold red");
    print << 'USAGE';
To run the tests you must set the following environmental variables:

    NET_PAYPAL_CLIENT_ID    - to the value of your client_id as provided by PayPal Developer Network
    NET_PAYPAL_SECRET       - to the value of your secret token as provided by PayPal Developer Network

Not setting the above variables will cause all the tests to skip!

USAGE

    print color("reset");
}


