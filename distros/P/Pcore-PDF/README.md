# NAME

Pcore::PDF - non-blocking HTML to PDF converter

# SYNOPSIS

    use Pcore::PDF;

    my $pdf = Pcore::PDF->new({
        bin         => 'path-to-princexml-executable',
        max_threads => 4,
    });

    # $res->{data} contains ScalarRef to generated PDF content
    my $res = $pdf->generate_pdf($html);

# DESCRIPTION

Generate PDF from HTML templates, using princexml.

# ATTRIBUTES

- bin

    Path to `princexml` executable. Mandatory attribute.

- max\_threads

    Maximum number of princexml processes. Default value is `4`.

# METHODS

- generate\_pdf( $self, $html )

    Generates PDF from `$html` template. `$result` is a standard Pcore API result object, see [Pcore::Util::Result](https://metacpan.org/pod/Pcore%3A%3AUtil%3A%3AResult) documentation for details.

# SEE ALSO

- [Pcore](https://metacpan.org/pod/Pcore)
- [Pcore::Util::Result](https://metacpan.org/pod/Pcore%3A%3AUtil%3A%3AResult)
- [https://www.princexml.com/](https://www.princexml.com/)

# AUTHOR

zdm <zdm@softvisio.net>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by zdm.
