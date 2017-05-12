package SWISH::Filters::IPTC2html;
use strict;
use warnings;
use vars qw( $VERSION @ISA );
$VERSION = '0.191';
@ISA     = ('SWISH::Filters::Base');

sub new {

    my ($class) = @_;
    my $self = bless {
        mimetypes => [qr!image/jpeg!],    # list of types this filter handles
    }, $class;
    return $self->use_modules(qw/ Image::IPTCInfo /);
}

sub filter {

    my ( $self, $doc ) = @_;
    my $file = $doc->fetch_filename;

    my $user_meta = $doc->meta_data || {};

    # Create new info object
    my $info = Image::IPTCInfo->new($file);

    # Check if file had IPTC data
    return unless defined($info);

    # Get specific attributes...
    my $caption = $info->Attribute('caption/abstract');

    # does it need escaping? silly test
    if ( $caption =~ m/[<>&]/ ) {
        $caption = $self->escapeXML($caption);
    }

    my $headers = "<title>$caption</title>\n"
        . $self->format_meta_headers($user_meta);

    # update the document's content type
    # uncommented set_content_type() to fix RT bug #20887
    $doc->set_content_type('text/html');

    my $xml = $info->ExportXML('image');

    my $txt = <<EOF;
<html>
<head>
$headers
</head>
<body>
$xml
</body>
</html>
EOF

    return (
        \$txt,
        {   title => $caption,
            map { $_ => $user_meta->{$_} } keys %$user_meta
        }
    );
}

1;

__END__ 

=head1 NAME

SWISH::Filters::IPTC2html - Perl extension for filtering image files with Swish-e

=head1 DESCRIPTION

This is a plug-in module that uses the Perl Image::IPTCInfo package 
to extract meta-data into html for indexing by Swish-e.

This filter plug-in requires the Image::IPTC package available at:

 http://search.cpan.org/~jcarter/

=head1 AUTHOR

Bill Conlon

=head1 SEE ALSO

L<SWISH::Filter>

=head1 SUPPORT

Please contact the Swish-e discussion list. http://swish-e.org/

=cut

