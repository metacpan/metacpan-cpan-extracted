package OCR::OcrSpace;

use 5.006;
use strict;
use warnings;

use LWP::UserAgent;
use Carp qw( carp confess croak );

use vars qw($VERSION @EXPORT @ISA $BASE_URL);

@ISA = qw(Exporter);

@EXPORT = qw( get_result  $BASE_URL);
############################################################
# DEFAULT base url
############################################################
$BASE_URL = 'http://api.ocr.space/parse/image';

=head1 NAME

Apr-2020 @ 

OCR::OcrSpace - Perl Interface to access L<https://ocr.space/OCRAPI>

The free OCR API provides a simple way of parsing images and multi-page PDF documents (PDF OCR) and getting the extracted text results returned in a JSON format.

This module implemented the Post request only.

Extract text from images , pdf via ocr-space

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    #using object oriented interaface
    use OCR::OcrSpace;

    my $ocrspace_obj = OCR::OcrSpace->new();

    my $param = {
        file                         => '/tmp/image.png',                     #full iamge path

                                    or 

        url                         => 'http://imagedatabase.com/test.jpg'   #image url to fetch from

                                    or

        base64Image                 => 'data:image/png;base64,iVBORw0KGgoAx7/7LNuCQS0posnocgEAFpySUVORK5CYII='

        #following optional parameter
        ocr_space_url                  => "https://api.ocr.space/parse/image",  
        apikey                         => 'XXXXXXXXXXXXXXXXXX',                 #API Key (mandatory)
        isOverlayRequired              =>'True',                                #optional
        language                       =>'eng' ,                                #optional
        scale                          => 'True',                               #optional
        isTable                        => 'True',                               #optional
        OCREngine                      => 2,                                    #optional
        filetype                       => 'PNG',                                #optional
        detectOrientation              => 'False',                              #optional
        isCreateSearchablePdf          => 'True',                               #optional
        isSearchablePdfHideTextLayer   => 'True',                               #optional

    };

    print $ocrspace_obj->get_result( $param );


    #using non-object oriented interaface

    use OCR::OcrSpace;
    print get_result( $param );



    #since ocrSpace uses http as well as HTTPs you can always set the following varible before call
    $BASE_URL

=head1 EXPORT

    #method
    get_result

    #varible
    $BASE_URL

=head1 SUBROUTINES/METHODS

=head2 new

    used to create a constructor of OCR::OcrSpace for object oriented mode

=cut

sub new {
    my ( $class, $params ) = ( @_ );

    return ( bless( {}, $class ) );
}

=head2 get_result

     params hash ref of following valid keys

=over 13

=item *  B<invocant>  { optional but required when using object oriented interface }

=item *  B<ocr_space_url>  { optional url if you want to use https mention url }

C<ocr_space_url> scalar string ([Optional] Default  L<http://api.ocr.space/parse/image>)

=item *  B<apikey>  { scalar string }

C<apikey> API Key (send in the header)

get your key from here L<http://eepurl.com/bOLOcf>

=item *   B<url or file or base64Imag>
 
C<url or file or base64Imag>
You can use three methods to upload the input image or PDF. We recommend the URL method for file sizes > 10 MB for faster upload speeds.

    url: URL of remote image file (Make sure it has the right content type)

    file: Multipart encoded image file with filename

    base64Image: Image as Base64 encoded string


=item * B<language>
 
C<language>

    [Optional]
    Arabic=ara
    Bulgarian=bul
    Chinese(Simplified)=chs
    Chinese(Traditional)=cht
    Croatian = hrv
    Czech = cze
    Danish = dan
    Dutch = dut
    English = eng
    Finnish = fin
    French = fre
    German = ger
    Greek = gre
    Hungarian = hun
    Korean = kor
    Italian = ita
    Japanese = jpn
    Polish = pol
    Portuguese = por
    Russian = rus
    Slovenian = slv
    Spanish = spa
    Swedish = swe
    Turkish = tur
 
Language used for OCR. If no language is specified, English eng is taken as default.

IMPORTANT: The language code has always 3-letters (not 2). So it is "eng" and not "en".
 
=item *  B<isOverlayRequired>
 
C<isOverlayRequired> scalar string ([Optional] Boolean value)


Default = False
If true, returns the coordinates of the bounding boxes for each word. If false, the OCR'ed text is returned only as a text block (this makes the JSON reponse smaller). Overlay data can be used, for example, to show text over the image.
 
 
=item *  B<filetype> 
 
C<filetype> scalar string  (Optional] String value: PDF, GIF, PNG, JPG, TIF, BMP)

Overwrites the automatic file type detection based on content-type. Supported image file formats are png, jpg (jpeg), gif, tif (tiff) and bmp. For document ocr, the api supports the Adobe PDF format. Multi-page TIFF files are supported.
 
 
=item *  B<detectOrientation>
 
C<detectOrientation> scalar string ([Optional] true/false)


if set to true, the api autorotates the image correctly and sets the TextOrientation parameter in the JSON response. If the image is not rotated, then TextOrientation=0, otherwise it is the degree of the rotation, e. g. "270".

 
=item *  B<isCreateSearchablePdf>
 
C<isCreateSearchablePdf> scalar string ([Optional] Boolean value)
 
Default = False
If true, API generates a searchable PDF. This parameter automatically sets isOverlayRequired = true


=item *  B<isSearchablePdfHideTextLayer>
 
C<isSearchablePdfHideTextLayer> scalar string ([Optional] Boolean value)
 
Default = False. If true, the text layer is hidden (not visible)


=item *  B<scale>
 
C<scale> scalar string ([Optional] true/false)


If set to true, the api does some internal upscaling. This can improve the OCR result significantly, especially for low-resolution PDF scans. Note that the front page demo uses scale=true, but the API uses scale=false by default. See also this OCR forum post.


=item *  B<isTable>
 
C<isTable> scalar string ([Optional] true/false)

If set to true, the OCR logic makes sure that the parsed text result is always returned line by line. This switch is recommended for table OCR, receipt OCR, invoice processing and all other type of input documents that have a table like structure.

=item *  B<OCREngine>
 
C<OCREngine> scalar int ([Optional] 1 or 2)

The default is engine 1. OCR Engine 2 is a new image-processing method.


=back

=head2 Notes from L<https://ocr.space/OCRAPI>

Tip: When serving images from an Amazon AWS S3 bucket or a similar service for use with the "URL" parameter, make sure it has the right content type. It should not be "Content-Type:application/x-www-form-urlencoded" (which seems to be the default) but image/png or similar. Alternatively you can include the filetype parameter and tell the API directly what type of document you are sending (PNG, JPG, GIF, PDF).


New: If you need to detect the status of checkboxes, please contact us about the Optical Mark Recognition (OMR) (Beta) features.


Select the best OCR Engine

New: We implemented a second OCR engine with a different processing logic. It is better than the default engine (engine1) in certain cases. So we recommend that you try engine1 first (since it is faster), but if the OCR results are not perfect, please try the same document with engine2. You can use the new OCR engine with our free online OCR service on the front page, and with the API.

Features of OCR Engine 1:

- Supports more languages (including Asian languages like Chinese, Japanese and Korean)

- Faster

- Supports larger images

- PDF OCR and Searchable PDF creation support

- Multi-Page TIFF scan support

- Parameter: OCREngine=1

Features of OCR Engine 2:

- Western Latin Character languages only (English, German, French,...)

- Language auto-detect (so it does not really matter what OCR language you select, as long as it uses Latin characters)

- Usually better at single number OCR and alphanumeric OCR (e. g. SUDOKO, Dot Matrix OCR, MRZ OCR,... )

- Usually better at special characters OCR like @+-...

- Image size limit 5000px width and 5000px height

- Parameter: OCREngine=2

- No PDF OCR and Offline OCR yet. If you need this, please contact us for an internal beta.

The returned OCR result JSON response is identical for both engines! So you can easily switch between both engines as needed. If you have any question about using Engine 1 or 2, please ask in our OCR API Forum.

 
=cut

sub get_result {

    #can be simply done by discarding the $self
    # but keeping it like this to allow future maintaince if any
    my ( $params, $raw_request, $result );
    if ( scalar @_ > 1 ) {
        my $self;
        ( $self, $params ) = ( @_ );

        #validate the parameters and get
        $params = $self->_validate( $params );

        #Generate the request
        $raw_request = $self->_generate_request( $params );

        #send the request via gateway
        $result = $self->_process_request( $raw_request );

    } else {
        $params = shift;

        $params = _validate( $params );

        #Generate the request
        $raw_request = _generate_request( $params );

        #send the request via gateway
        $result = _process_request( $raw_request );
    }

    #retun
    return $result // undef;

}

=head2 Sample Ouput success

    {"ParsedResults":[{"TextOverlay":{"Lines":[{"LineText":"Current","Words":[{"WordText":"Current","Left":11.666666030883789,"Top":59.166664123535156,"Height":14.999999046325684,"Width":54.999996185302734}],"MaxHeight":14.999999046325684,"MinTop":59.166664123535156},{"LineText":"59","Words":[{"WordText":"59","Left":32.5,"Top":239.99998474121094,"Height":20.833332061767578,"Width":29.166666030883789}],"MaxHeight":20.833332061767578,"MinTop":239.99998474121094}],"HasOverlay":true,"Message":"Total lines: "2"},"TextOrientation":"0","FileParseExitCode":1,"ParsedText":"Current\t\r\n59\t\r\n","ErrorMessage":"","ErrorDetails":""}],"OCRExitCode":1,"IsErroredOnProcessing":false,"ProcessingTimeInMilliseconds":"437","SearchablePDFURL":""}

=head2 Sample Ouput error

    {"OCRExitCode":99,"IsErroredOnProcessing":true,"ErrorMessage":["Parameter name 'attributes' is invalid. Valid parameters: apikey,url,language,isoverlayrequired,base64image,iscreatesearchablepdf,issearchablepdfhidetextlayer,filetype,addressparsing,scale,detectorientation,istable,ocrengine,detectcheckbox,checkboxtemplate,checkboxtemplateregex","Please check if you need to URL encode the URL passed in request parameters."],"ProcessingTimeInMilliseconds":"0"}

=cut

####################
# internal function
###################
sub _generate_request {
    my $params = ( scalar( @_ ) > 1 ) ? $_[1] : shift;

    my $request_hash = {
        url        => $params->{endpoint},
        body_param => $params->{body_param},
    };

    $request_hash->{file_path} = $params->{file} if ( defined $params->{file} );

    return $request_hash;
}

####################
# internal function
###################
sub _validate {
    my $params = ( scalar( @_ ) > 1 ) ? $_[1] : shift;
    carp "Required parameter `apikey` not passed" unless ( defined $params->{apikey} );
    carp "Required parameter `url or file or base64Image` not passed"
      unless ( defined( $params->{url} || $params->{file} || $params->{base64Image} ) );

    my $valid_params = { endpoint => $params->{ocr_space_url} // $BASE_URL, };
    $valid_params->{url}         = $params->{url}         if ( defined $params->{url} );
    $valid_params->{base64Image} = $params->{base64Image} if ( defined $params->{base64Image} );
    if ( defined $params->{file} ) {
        if ( -f $params->{file} ) {
            $valid_params->{file} = $params->{file};
        } else {
            carp "Unable to open file $params->{file} \n";
        }
    }

    #add optional keys
    foreach (
        qw/
        language                      isOverlayRequired       filetype
        detectOrientation             isCreateSearchablePdf   url
        isSearchablePdfHideTextLayer  scale                   base64Image
        isTable                       OCREngine               apikey/
      )
    {
        $valid_params->{body_param}->{$_} = $params->{$_} if ( defined $params->{$_} );
    }
    return $valid_params;
}

####################
# internal function
###################
sub _process_request {
    my $params = ( scalar( @_ ) > 1 ) ? $_[1] : shift;

    my $file     = $params->{file_path};
    my $endpoint = $params->{url};

    my ( $res, $body, $header, $content );

    if ( defined $params->{body_param} && uc( ref( $params->{body_param} ) ) eq 'HASH' ) {
        foreach ( keys %{ $params->{body_param} } ) {
            push( @$content, ( $_ => $params->{body_param}->{$_} ) );
        }
    }

    if ( $file ) {
        push( @$content, ( file => [$file] ) );
    }

    my $ua = LWP::UserAgent->new();

    $ua->env_proxy;

    if ( defined $params->{header} ) {
        $header = $params->{header};
        $ua->default_header( %$header );
    }

    foreach ( 1 .. 3 ) {
        $res = $ua->post(
            $endpoint,
            Content_Type => 'multipart/form-data',
            Content      => $content,
        );

        if ( $res->is_success ) {
            return $res->content;
        } else {
            return $res->status_line;
        }
    }
}

=head1 AUTHOR

sushrut pajai, C<< <spajai at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ocr-ocrspace at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=OCR-OcrSpace>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc OCR::OcrSpace


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=OCR-OcrSpace>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/OCR-OcrSpace>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/OCR-OcrSpace>

=item * Search CPAN

L<https://metacpan.org/release/OCR-OcrSpace>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by sushrut pajai.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

1;    # End of OCR::OcrSpace

__END__
