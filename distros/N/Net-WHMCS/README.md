# SYNOPSIS

        use Net::WHMCS;
        use Digest::MD5 'md5_hex';

        my $whmcs = Net::WHMCS->new(
                WHMCS_URL => 'http://example.com/whmcs/includes/api.php',
                api_identifier => 'D4j1dKYE3g40VROOPCGyJ9zRwP0ADJIv',
                api_secret => 'F1CKGXRIpylMfsrig3mwwdSdYUdLiFlo',
        );

        my $user = $whmcs->client->getclientsdetails({
                clientid => 1,
                stats => 'true',
        });

# DESCRIPTION

[https://developers.whmcs.com/api/](https://developers.whmcs.com/api/)

NOTE: the modules are incomplete. please feel free to fork on github [https://github.com/fayland/perl-Net-WHMCS](https://github.com/fayland/perl-Net-WHMCS) and send me pull requests.

# PARTS

## client

        my $user = $whmcs->client->getclientsdetails({
                clientid => 1,
                stats => 'true',
        });

[Net::WHMCS::Client](https://metacpan.org/pod/Net::WHMCS::Client)

## support

        $whmcs->support->openticket({
                clientid => 1,
                deptid => 1,
                subject => 'subject',
                message => 'message'
        });

[Net::WHMCS::Support](https://metacpan.org/pod/Net::WHMCS::Support)

## order

        $whmcs->order->addorder({
                clientid => 1,
                pid => 1,
                ...
        });

[Net::WHMCS::Order](https://metacpan.org/pod/Net::WHMCS::Order)

## misc

        $whmcs->misc->addproduct({
                type => 'other',
                gid => 1,
                name => 'Sample Product',
                paytype => 'recurring',
                'pricing[1][monthly]' => '5.00',
                'pricing[1][annually]' => '50.00',
                ...
        });

[Net::WHMCS::Miscellaneous](https://metacpan.org/pod/Net::WHMCS::Miscellaneous)
