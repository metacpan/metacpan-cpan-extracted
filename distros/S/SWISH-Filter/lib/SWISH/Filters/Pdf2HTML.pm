package SWISH::Filters::Pdf2HTML;
use strict;
use vars qw( $VERSION @ISA );
$VERSION = '0.191';
@ISA = ('SWISH::Filters::Base');

sub new {
    my ($class) = @_;

    my $self = bless { mimetypes => [qr!application/pdf!], }, $class;

    return $self->set_programs(qw/ pdftotext pdfinfo /);
}

sub filter {
    my ( $self, $doc ) = @_;

    my $user_data = $doc->user_data;
    my $title_tag
        = ref $user_data eq 'HASH'
        ? $user_data->{pdf}{title_tag}
        : 'title';

    my $user_meta = $doc->meta_data || {};
    my $file = $doc->fetch_filename;

    $self->mywarn("Pdf2HTML handling $file");

    my $metadata = $self->get_pdf_headers($file);

    # merge pdf meta with meta we inherited, preferring user meta
    $metadata->{$_} = $user_meta->{$_} for keys %$user_meta;

    my $headers = $self->format_meta_headers($metadata);

    if ( $title_tag && exists $metadata->{$title_tag} ) {
        my $title = $self->escapeXML( $metadata->{$title_tag} );

        $headers = "<title>$title</title>\n" . $headers;
    }

    # Check for encrypted content

    my $content_ref;

    # patch provided by Martial Chartoire
    if (   $metadata->{encrypted}
        && $metadata->{encrypted} =~ /yes\.*\scopy:no\s\.*/i )
    {
        $content_ref = \'';

    }
    else {
        $content_ref = $self->get_pdf_content_ref($file);
    }

    # update the document's content type
    $doc->set_content_type('text/html');

    my $txt = <<EOF;
<html>
<head>
$headers
</head>
<body>
<pre>
$$content_ref
</pre>
</body>
</html>
EOF

    return ( \$txt, $metadata );

}

sub get_pdf_headers {

    my ( $self, $file ) = @_;

    # We need a file name to pass to the pdf conversion programs

    my %metadata;
    my $headers = $self->run_pdfinfo($file);
    return \%metadata unless $headers;

    for ( split /\n/, $headers ) {
        if (/^\s*([^:]+):\s+(.+)$/) {
            my ( $metaname, $value ) = ( lc($1), $2 );
            $metaname =~ tr/ /_/;
            $metadata{$metaname} = $value;
        }
    }

    return \%metadata;
}

sub get_pdf_content_ref {
    my ( $self, $file ) = @_;

    my $content = $self->escapeXML( $self->run_pdftotext( $file, '-' ) );

    return \$content;
}

1;
__END__

=head1 NAME

SWISH::Filters::Pdf2HTML - Perl extension for filtering PDF documents with Swish-e

=head1 DESCRIPTION

This is a plug-in module that uses the xpdf package to convert PDF documents
to html for indexing by Swish-e.  Any info tags found in the PDF document are created
as meta tags.

This filter plug-in requires the xpdf package available at:

    http://www.foolabs.com/xpdf/

You may pass into SWISH::Filter's new method a tag to use as the html
<title> if found in the PDF info tags:

    my %user_data;
    $user_data{pdf}{title_tag} = 'title';

    $was_filtered = $filter->filter(
        document  => $filename,
        user_data => \%user_data,
    );

Then if a PDF info tag of "title" is found that will be used as the HTML <title>.
If no tag is passed, C<title> will be used as the default tag.


=head1 AUTHOR

Bill Moseley

=head1 SEE ALSO

L<SWISH::Filter>


