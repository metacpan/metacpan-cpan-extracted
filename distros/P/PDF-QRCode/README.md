![](https://github.com/oetiker/pdf-qrcode/workflows/Unit%20Tests/badge.svg?branch=main)

# NAME

PDF::QRCode - add qrcode method to a PDF::API2 or PDF::Builder.

# SYNOPSIS

```perl
use PDF::API2; # or PDF::Builder
use PDF::QRCode;

my $pdf = PDF::API2->new(-file=>'qr.pdf');
$pdf->mediabox('a4');
my $gfx = $pdf->page->gfx;
$gfx->qrcode(x => 100, y => 100, 
   level => 'L', size => 40, text => 'Hello World');
$pdf->save;
```

# DESCRIPTION

The [PDF::QRCode](https://metacpan.org/pod/PDF%3A%3AQRCode) module monkey patches the 'qrcode' method into the
[PDF::API2::Content](https://metacpan.org/pod/PDF%3A%3AAPI2%3A%3AContent) or [PDF::Builder::Content](https://metacpan.org/pod/PDF%3A%3ABuilder%3A%3AContent) class, so that you can use it directly from there. See the example above

## $gfx->qrcode(%cfg)

Adds a qr code to the given gfx content. It expects the following parameters:

- x

    horizontal position

- y

    vertical position

- size

    width/height

- text

    the content of the qrcode

- level (optional)

    qr code level `L`, `M`, `Q`, `H`

# AUTHOR

Tobias Oetiker, <tobi@oetiker.ch>

# COPYRIGHT

Copyright OETIKER+PARTNER AG 2020

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10 or,
at your option, any later version of Perl 5 you may have available.
