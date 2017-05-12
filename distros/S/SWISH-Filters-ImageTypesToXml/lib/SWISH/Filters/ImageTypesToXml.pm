package SWISH::Filters::ImageTypesToXml;
use strict;
use warnings;
use SWISH::Filter::MIMETypes;
use base 'SWISH::Filters::Base';

=head1 NAME

SWISH::Filters::ImageTypesToXml - A filter that applies Imager::ImageTypes to index

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

A SWISHE filter that takes an incoming jpg and analyzes it with Imager::ImageTypes.
This filter also accepts incoming XML as long as there is a base64 image data.

If an XML file is passed into the filter it will look for the "b64_data" tag.
If the xml contains this tag it will process the image that is stored in
base64 format.

=head1 DEZI CONFIGURATION

Within the dezi configuration there are paremters that can be passed into the
user meta data of this filter.

    { 
        engine_config => {
            ...
        },
        image_types_config => {
            generate_histogram  => 1
        }
    }

=head2 generate_histogram(1|0)

This will either dump the colors of the histogram or not. It is off by
default.

=head1 METHODS

=head2 new ( $class )

Constructor. Dynamically loads Imager and Search::Tools::XML. Also sets the
filter mimtype to whatever Imager supports.

=cut

sub new {
    my ( $class ) = @_;

    $class = ref $class || $class;

    my $self = bless { }, $class;

    return $self->_init;
}

sub _init {
    my ( $self ) = @_;

    $self->use_modules(qw/Imager Search::Tools::XML/);

    my @mimetypes = (
        map { SWISH::Filter::MIMETypes->get_mime_type('*.' . $_) } Imager->read_types,
        'application/xml'
    );

    $self->{mimetypes} = \@mimetypes;

    return $self;
}

sub _parse_xml {
    my ( $self, $xml ) = @_;

    if ( $xml ) {
        use XML::Simple;
        use MIME::Base64;
        if ( my $ds = XMLin($xml) ) {
            if ( my $bin = decode_base64($ds->{b64_data}) ) {
                $self->{b64_data} = $ds->{b64_data};
                return $bin;
            }
        }
    }
}


=head2 filter( $self, $doc )

Generates Imager::ImageTypes meta data for indexing.

=cut

sub filter {
    my ( $self, $doc ) = @_;

    my $file        = $doc->fetch_filename;
    my $user_meta   = $doc->meta_data || {
        image_types_config => {
            generate_histogram  => 0
        }
    };

    my $utils       = Search::Tools::XML->new;
    my $imager      = Imager->new;
    my $img         = $doc->is_binary ? $imager->read( file => $file ) :
                      $utils->looks_like_xml($file) ? $imager->read( data => $self->_parse_xml($file) ) : undef;

    return unless $img;

    my $image_data  = {
        width       => $img->getwidth,
        height      => $img->getheight,
        channels    => $img->getchannels,
        colorcount  => $img->getcolorcount,
        %{$user_meta}
    };

    $image_data->{counts}   = [ $img->getcolorusage ] if $user_meta->{image_types_config}{generate_histogram};
    $image_data->{b64_data} = $self->{b64_data} if $self->{b64_data};

    $doc->set_content_type('application/xml');
    my $xml = $utils->perl_to_xml($image_data, 'image_data', );

    return $xml;
}

=head1 AUTHOR

Logan Bell, C<< <loganbell at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-swish-filters-imagetypestoxml at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SWISH-Filters-ImageTypesToXml>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SWISH::Filters::ImageTypesToXml


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Filters-ImageTypesToXml>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SWISH-Filters-ImageTypesToXml>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SWISH-Filters-ImageTypesToXml>

=item * Search CPAN

L<http://search.cpan.org/dist/SWISH-Filters-ImageTypesToXml/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Logan Bell.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of SWISH::Filters::ImageTypesToXml
