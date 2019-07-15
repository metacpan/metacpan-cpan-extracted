# NAME

Pcore::PDF - non-blocking HTML to PDF converter

# SYNOPSIS

    use Pcore::PDF;

    my $pdf = Pcore::PDF->new({
        bin         => 'path-to-princexml-executable',
        max_threads => 4,
    });

    # blocking mode, blocks only current coroutine
    my $res = $pdf->generate_pdf($html);

    # non-blocking mode
    $pdf->generate_pdf($html, sub ($res) {
        if (!$res) {
            say $res;
        }
        else {

            # $res->{data} contains ScalarRef to generated PDF content
        }

        return;
    });

# DESCRIPTION

Generate PDF from HTML templates, using princexml.

# ATTRIBUTES

- bin

    Path to `princexml` executable. Mandatory attribute.

- max\_threads

    Maximum number of princexml processes. Default value is `4`.

# METHODS

- generate\_pdf( $self, $html, $cb = undef )

    Generates PDF from `$html` template. `$result` is a standard Pcore API result object, see [Pcore::Lib::Result](https://metacpan.org/pod/Pcore::Lib::Result) documentation for details.

# SEE ALSO

- [Pcore](https://metacpan.org/pod/Pcore)
- [Pcore::Lib::Result](https://metacpan.org/pod/Pcore::Lib::Result)
- [https://www.princexml.com/](https://www.princexml.com/)

# AUTHOR

zdm <zdm@softvisio.net>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by zdm.
