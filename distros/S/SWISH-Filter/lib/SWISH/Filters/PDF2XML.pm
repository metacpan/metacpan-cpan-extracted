package SWISH::Filters::PDF2XML;
use strict;
use vars qw( $VERSION @ISA );
$VERSION = '0.191';
@ISA     = ('SWISH::Filters::Base');

sub new {
    my ($class) = @_;

    my $self = bless { mimetypes => [qr!application/pdf!], }, $class;

    # optional module for local timestamps
    if ( $self->use_modules(qw/ Time::Local /) ) {
        $self->{_has_time_local} = 1;
        $self->{_re}->{date}     = qr/(\d{4})(\d{2})(\d{2})/xms;
        $self->{_re}->{time}     = qr/(\d{2})(\d{2})(\d{2})/xms;
        $self->{_re}->{tz}       = qr/([+-Z])(\d{2})\'(\d{2})\'/xms;
    }

    if ( $self->use_modules(qw/ CAM::PDF /) ) {
        return $self;
    }

    return undef;    # CAM::PDF not installed
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

    $self->mywarn("PDF2XML handling $file");

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
    $doc->set_content_type('text/xml');

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

    # cribbed mostly from
    # http://api.metacpan.org/source/CDOLAN/CAM-PDF-1.60/bin/pdfinfo.pl
    my %metadata;
    my $pdfdoc = CAM::PDF->new( $file, q{}, q{}, 1 )
        or die "$CAM::PDF::errstr\n";

    # basic meta
    $metadata{pdf_version} = $pdfdoc->{pdfversion};
    $metadata{size}        = length $pdfdoc->{content};
    $metadata{pages}       = $pdfdoc->numPages();
    $metadata{file}        = $file;
    my $pdfinfo = $pdfdoc->{trailer}->{Info};
    $pdfinfo &&= $pdfdoc->getValue($pdfinfo);
    if ( !$pdfinfo ) {
        return \%metadata;
    }
    for my $key ( sort keys %$pdfinfo ) {
        my $metaname = lc $key;
        $metaname =~ s/ /_/g;
        my $val = $pdfinfo->{$key}->{value};
        if (   $pdfinfo->{$key}->{type} eq 'string'
            && $self->{_has_time_local}
            && $val
            && $val =~ m{ \A
                        D: $self->{_re}->{date} $self->{_re}->{time} $self->{_re}->{tz}
                        \z
                      }xms
            )
        {
            my ( $Y, $M, $D, $h, $m, $s, $sign, $tzh, $tzm )
                = ( $1, $2, $3, $4, $5, $6, $7, $8, $9 );
            if ( $sign eq 'Z' ) {
                $sign = q{+};
            }
            my $timegm
                = Time::Local::timegm( $s, $m, $h, $D, $M - 1, $Y - 1900 );
            my $tzshift = $sign . ( $tzh * 3600 + $tzm * 60 );
            $timegm += $tzshift;
            $val = localtime $timegm;
        }
        $metadata{$metaname} = $val;
    }

    return \%metadata;
}

sub get_pdf_content_ref {
    my ( $self, $file ) = @_;

    my $pdfdoc = CAM::PDF->new($file) or die "$CAM::PDF::errstr\n";
    my $content = '';
    for my $page ( $pdfdoc->rangeToArray( 1, $pdfdoc->numPages() ) ) {
        my $str = $pdfdoc->getPageText($page);
        if ( defined $str ) {
            CAM::PDF->asciify( \$str );    # TODO encodings?
            $content .= $str;
        }
    }

    return \$content;
}

1;

__END__

=head1 NAME

SWISH::Filters::PDF2XML - Perl extension for filtering PDF documents 

=head1 DESCRIPTION

This is a plug-in module that uses the L<CAM::PDF> package to convert PDF documents
to XML.  Any info tags found in the PDF document are created as meta tags.

You may pass into SWISH::Filter's new method a tag to use as the XML
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

Peter Karman

=head1 SEE ALSO

L<SWISH::Filter>


