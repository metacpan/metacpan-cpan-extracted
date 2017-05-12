use Test::Able::Runner;
use Test::Builder;
use Net::Netrc;

{
    no warnings 'once';

    # Fallback to ~/.netrc
    if (not defined $ENV{TEST_NGP_USER}) {
        my $mach = Net::Netrc->lookup("picasaweb.google.com");
        if ($mach) {
            $ENV{TEST_NGP_USER} = $mach->login;
            $ENV{TEST_NGP_PWD}  = $mach->password;
        }
    }
    $Net::Google::PicasaWeb::Test::USER = $ENV{TEST_NGP_USER};
    $Net::Google::PicasaWeb::Test::PWD  = $ENV{TEST_NGP_PWD};
}

my $Test = Test::Builder->new;
$Test->plan(skip_all => "no online tests unless TEST_NET_GOOGLE_PICASAWEB_ONLINE, TEST_NGP_USER, and TEST_NGP_PWD are set") 
    unless $ENV{TEST_NGP_USER} 
       and $ENV{TEST_NGP_PWD} 
       and $ENV{TEST_NET_GOOGLE_PICASAWEB_ONLINE};

use_test_packages
    -base_package => 'Net::Google::PicasaWeb::Test',
    -test_path    => [ 't/online' ];

run;
