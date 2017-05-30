# NAME

Pcore::PDF - non-blocking HTML to PDF converter

# SYNOPSIS

    use Pcore::PDF;

    my $pdf = Pcore::PDF->new({
        prince      => 'path-to-princexml-executable',
        max_threads => 4,
    });

    my $cv = AE::cv;

    $pdf->generate_pdf($html, sub ($res) {
        if (!$res) {
            say $res;
        }
        else {

            # $res->{data}->{pdf} contains ScalarRef to generated PDF content
        }

        return;
    });

    $cv->recv;

# DESCRIPTION

Generate PDF from HTML templates, using princexml.

# ATTRIBUTES

- prince

    Path to `princexml` executable. Mandatory attribute.

- max\_threads

    Maximum number of princexml processes. Under Windows this value is always `1`, under linux default value is `4`.

# METHODS

- generate\_pdf( $self, $html, $cb )

    Generates PDF from `$html` template. Call `$cb->($result)` on finish, where `$result` is a standard Pcore API result object, see [Pcore::Util::Result](https://metacpan.org/pod/Pcore::Util::Result) documentation for details.

# SEE ALSO

- [Pcore](https://metacpan.org/pod/Pcore)
- [Pcore::Util::Result](https://metacpan.org/pod/Pcore::Util::Result)
- [https://www.princexml.com/](https://www.princexml.com/)

# AUTHOR

zdm <zdm@softvisio.net>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by zdm.
