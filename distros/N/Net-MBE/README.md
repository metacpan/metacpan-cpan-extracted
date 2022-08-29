# Net-MBE

Perl library to access Mailboxes Etc (MBE) online webservices

## SYNOPSIS

```perl
    use Net::MBE;
    use Net::MBE::DestinationInfo;
    use Net::MBE::ShippingParameters;

    my $mbe = Net::MBE->new({
        system => 'IT',
        Username => 'XXXXX',
        Passphrase => 'YYYYYYYY',
    });

    my $dest = Net::MBE::DestinationInfo->new({
        zipCode => '33085',
        country => 'IT', 
        state => 'PN'
    });

    my $shipparams = Net::MBE::ShippingParameters->new({
        destinationInfo => $dest,
        shipType => 'EXPORT',
        packageType => 'GENERIC',
    });
    $shipparams->addItem({
        weight => 1,
        length => 10,
        width  => 10,
        height => 10,
    });

    my $response = $mbe->ShippingOptions({
        internalReferenceID => '48147184XTST',
        shippingParameters => $shipparams,
    });

    use Data::Dump qw/dump/; print dump($response);
```

## DESCRIPTION

Mailboxes Etc (MBE), formerly a UPS-owned chain of shipping service outlets, is now an Italian
independent company which operated in several european countries.

This library is for accessing their various web services for getting rates, etc.

Currently, ONLY getting shipping rates is implemented.

## AUTHOR

Michele Beltrame, arthas@cpan.org

## LICENSE

This library is free software under the Mozilla Public License 2.0.
