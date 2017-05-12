package SWISH::Filters::ImageToXml;

use strict;
use warnings;
use base 'SWISH::Filters::Base';

=head1 NAME

SWISH::Filters::ImageToXml - A filter that converts an image to base64 and outputs XML

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

A SWISHE filter that takes an incoming image and converts it to base64 and
returns XML.

=head2 XML

The following is an example of the generated XML.

    <doc>
        <b64_data>...BASE 64 CONTENT...</b64_data>
    </doc>

=head1 METHODS

=head2 new ( $class )

Constructor. 

=cut

sub new {
    my ( $class ) = @_;

    $class = ref $class || $class;

    my $self = bless { }, $class;

    return $self->_init;
}

sub _init {
    my ( $self ) = @_;

    $self->use_modules(qw/MIME::Base64/);

    my @mimetypes = (
        'image/vnd.sealedmedia.softseal.gif',
        'image/png',
        'image/x-ms-bmp',
        'image/vnd.microsoft.icon',
        'image/tiff',
        'image/jpeg',
        'image/x-portable-anymap',
        'image/targa' 
    );

    $self->{mimetypes} = \@mimetypes;

    return $self;
}

=head2 filter( $self, $doc )

Generates Imager::ImageTypes meta data for indexing.

=cut

sub filter {
    my ( $self, $doc ) = @_;

    return unless $doc->is_binary;

    my $file        = $doc->fetch_filename;
    open my $fh, $file or return;

    my $bin = do { local $/; <$fh> };
    my $xml = '<doc><b64_data>' . encode_base64($bin) .  '</b64_data></doc>';

    return $xml;
}

=head1 AUTHOR

Logan Bell, C<< <loganbell at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-swish-filters-imagetoxml at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SWISH-Filters-ImageToXml>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SWISH::Filters::ImageToXml


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Filters-ImageToXml>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SWISH-Filters-ImageToXml>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SWISH-Filters-ImageToXml>

=item * Search CPAN

L<http://search.cpan.org/dist/SWISH-Filters-ImageToXml/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Logan Bell.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of SWISH::Filters::ImageToXml
