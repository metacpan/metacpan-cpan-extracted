use warnings;
use strict;

use File::Copy;
use JSON;
use Net::DynDNS::GoDaddy qw(api_key_get api_key_set);
use Test::More;

my $file = Net::DynDNS::GoDaddy::_api_key_file();

if (-e $file) {
    move($file, "$file.bak") or die "Can't move $file to $file.bak: $!";
}

# api_key_get() croak
{
    is eval {
        api_key_get();
        1;
    }, undef, "api_key_get() croaks if no key file exists ok";
    like $@, qr/doesn't exist/, "...and error message is sane";
}

# api_key_set() croak if can't write file (only run if not root user)
if ($^O !~ /win/i) {
    if (getpwuid($<) ne 'root') {
        open my $fh, '>', $file or die "Can't open $file for creation: $!";
        chmod(0400, $file) or die "Can't set permissions on $file: $!";
        close $fh;

        is eval {
            api_key_set(2, 3);
            1;
        }, undef, "api_key_set() croaks if can't open file for writing";
        like $@, qr/for writing/, "...and error message is sane";

        chmod(0640, $file) or die "Can't set perms on $file: $!";
    }
}

# api_key_set() croak on bad params
{
    is eval {
        api_key_set();
        1;
    }, undef, "api_key_set() croaks with no params";
    like $@, qr/API key and an API secret/, "...and error message is sane";

    is eval {
        api_key_set(2);
        1;
    }, undef, "api_key_set() croaks with only one param";
    like $@, qr/API key and an API secret/, "...and error message is sane";
}

# api_key_set() success
{
    is api_key_set(2, 3), 1, "api_key_set() returns properly";

    my $data;

    {
        local $/;
        open my $fh, '<', $file or die "Can't open $file: $!";
        $data = decode_json(<$fh>);
        close $fh;
    }
    is $data->{api_key}, 2, "API key in file is ok";
    is $data->{api_secret}, 3, "API secret in file is ok";
}

# api_key_get() success
{
    my ($k, $s) = api_key_get();

    is $k, 2, "API key from file is ok";
    is $s, 3, "API secret from file is ok";
}

if (-e "$file.bak") {
    move("$file.bak", $file) or die "Can't move $file.bak to $file: $!";
}
else {
    unlink $file or die "Can't remove temp config file";
    is -e $file, undef, "Removed temp config file ok";
}
done_testing();