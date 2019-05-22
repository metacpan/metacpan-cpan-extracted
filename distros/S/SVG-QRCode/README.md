# NAME

SVG::QRCode - Generate SVG based QR Code

# SYNOPSIS

    use SVG::QRCode;

    my $qrcode = SVG::QRCode->new(
      {
        casesensitive => 0,
        darkcolor     => 'black',
        level         => 'M',
        lightcolor    => 'white',
        margin        => 10,
        size          => 5,
        version       => 0,
      }
    );
    my $svg  = $qrcode->plot('https://perldoc.pl');
    my $svg2 = $qrcode->param(darkcolor => 'red')->plot('https://perldoc.pl');

    # export function
    use SVG::QRCode 'plot_qrcode';

    my $svg = plot_qrcode('https://perldoc.pl', \%params);

# DESCRIPTION

[SVG::QRCode](https://metacpan.org/pod/SVG::QRCode) generates QR Codes as SVG images.

# FUNCTIONS

## plot\_qrcode

    use SVG::QRCode 'plot_qrcode';

    my $svg = plot_qrcode($text, \%params);

Creates a QR Code using the provided text and parameters.

# CONSTRUCTOR

## new

    $qrcode = SVG::QRCode->new(\%params);

Creates a new QR Code plotter. Accepted parameters are:

- casesensitive

    If your application is case-sensitive using 8-bit characters, set to `1`. Default `0`.

- darkcolor

    Color of the dots. Default `'black'`.

- level

    Error correction level, one of `'L'` (low), `'M'` (medium), `'Q'` (quartile), `'H'` (high). Default `'M'`.

- lightcolor

    Color of the background. Default `'white'`.

- margin

    Margin around the code. Default `10`.

- size

    Size of the dots. Default `5`.

- version

    Symbol version from `1` to `40`. `0` will adapt the version to the required capacity. Default `0`.

# METHODS

## param

    my $value = $svg->param($name);
    $svg = $svg->param($name, $newvalue);
    $svg = $svg->param($name, '');          # set to default

Getter and setter for the parameters.

## plot

    my $svg = $qrcode->plot($text);

Creates a QR Code.

# SEE ALSO

[Text::QRCode](https://metacpan.org/pod/Text::QRCode).

# AUTHOR & COPYRIGHT

Copyright (C) 2019, Tekki (Rolf Stöckli).

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.
