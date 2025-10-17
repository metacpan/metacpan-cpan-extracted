# NAME

SVG::Barcode::UPCA - Generator for SVG based UPCA barcodes

# SYNOPSIS

    use SVG::Barcode::UPCA;

    my $upca = SVG::Barcode::UPCA->new;
    my $svg     = $upca->plot('012345678905');

    $upca->linewidth;     # 1
    $upca->lineheight;    # 50
    $upca->textsize;      # 10
                             # from SVG::Barcode:
    $upca->foreground;    # black
    $upca->background;    # white
    $upca->margin;        # 2
    $upca->id;
    $upca->class;
    $upca->width;
    $upca->height;
    $upca->scale;

    my %params = (
      lineheight => 40,
      textsize   => 0,
    );
    $upca = SVG::Barcode::UPCA->new(%params);

    # use as function
    use SVG::Barcode::UPCA 'plot_upca';

    my $svg = plot_upca('012345678905', %params);

# DESCRIPTION

[SVG::Barcode::UPCA](https://metacpan.org/pod/SVG%3A%3ABarcode%3A%3AUPCA) is a generator for SVG based UPCA barcodes.

# FUNCTIONS

## plot\_upca

    use SVG::Barcode::UPCA 'plot_upca';

    $svg = plot_upca($text, %params);

Returns a UPCA barcode using the provided text and parameters.

# CONSTRUCTOR

## new

    $upca = SVG::Barcode::UPCA->new;             # create with defaults
    $upca = SVG::Barcode::UPCA->new(\%params);

Creates a new UPCA plotter. Inherited from [SVG::Barcode](https://metacpan.org/pod/SVG%3A%3ABarcode#new).

# METHODS

## plot

Creates a SVG code. Inherited from [SVG::Barcode](https://metacpan.org/pod/SVG%3A%3ABarcode#plot).

# PARAMETERS

Inherited from [SVG::Barcode](https://metacpan.org/pod/SVG%3A%3ABarcode):
[background](https://metacpan.org/pod/SVG%3A%3ABarcode#background),
[class](https://metacpan.org/pod/SVG%3A%3ABarcode#class),
[foreground](https://metacpan.org/pod/SVG%3A%3ABarcode#foreground),
[height](https://metacpan.org/pod/SVG%3A%3ABarcode#height),
[id](https://metacpan.org/pod/SVG%3A%3ABarcode#id),
[margin](https://metacpan.org/pod/SVG%3A%3ABarcode#margin),
[scale](https://metacpan.org/pod/SVG%3A%3ABarcode#scale),
[width](https://metacpan.org/pod/SVG%3A%3ABarcode#width).

## lineheight

    $value   = $upca->lineheight;
    $upca = $upca->lineheight($newvalue);
    $upca = $upca->lineheight('');          # 30

Getter and setter for the height of a line. Default `30`.

## linewidth

    $value   = $upca->linewidth;
    $upca = $upca->linewidth($newvalue);
    $upca = $upca->linewidth('');          # 1

Getter and setter for the width of a single line. Default `1`.

## textsize

    $value   = $upca->textsize;
    $upca = $upca->textsize($newvalue);
    $upca = $upca->textsize('');          # 10

Getter and setter for the size of the text a the bottom. `0` hides the text. Default `10`.

# AUTHOR & COPYRIGHT

Derived from SVG::Barcode::Code128 © 2019–2020 by Tekki (Rolf Stöckli).

© 2025 by bwarden (Brett T. Warden).

This program is free software, you can redistribute it and/or modify it under the terms of the
Artistic License version 2.0.

# SEE ALSO

[SVG::Barcode](https://metacpan.org/pod/SVG%3A%3ABarcode), [GD::Barcode::UPCA](https://metacpan.org/pod/GD%3A%3ABarcode%3A%3AUPCA).
