# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl OMA-DRM.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use lib 'lib/';
use Test::More tests => 1;
BEGIN { use_ok('OMA::Download::OTA') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


    my $dota = OMA::Download::OTA->new(
        ### Mandatory
        name        => 'test download',
        vendor      => 'Some vendor',
        type        => 'text/plain',
        size        => 128,
        description      => 'Some description',
        objectURI        => 'http://example.com/file.txt',
        installNotifyURI => 'http://example.com/status',
        nextURL          => 'http://example.com/thanks',
    );
    
    my $res = $dota->packit;
    
