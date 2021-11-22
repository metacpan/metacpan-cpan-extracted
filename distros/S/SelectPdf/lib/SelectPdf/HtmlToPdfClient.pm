package SelectPdf::HtmlToPdfClient;

use SelectPdf::ApiClient;
use SelectPdf::AsyncJobClient;
use SelectPdf::WebElementsClient;
use strict;
our @ISA = qw(SelectPdf::ApiClient);

=head1 NAME

SelectPdf::HtmlToPdfClient - Html To Pdf Conversion with SelectPdf Online API.

=head1 SYNOPSIS

Convert URL to PDF and save result into a file on disk.

    use SelectPdf;
    print "This is SelectPdf-$SelectPdf::VERSION\n";

    my $url = "https://selectpdf.com/";
    my $local_file = "Test.pdf";
    my $apiKey = "Your API key here";

    eval {
        my $client = new HtmlToPdfClient($apiKey);

        $client
            ->setPageSize("A4")
            ->setMargins(0)
            ->setShowPageNumbers('False')
            ->setPageBreaksEnhancedAlgorithm('True')
        ;

        $client->convertUrlToFile($url, $local_file);
    };

    if ($@) {
        print "An error occurred: $@\n";  
    }

Convert raw HTML string to PDF and save result into a file on disk.

    use SelectPdf;
    print "This is SelectPdf-$SelectPdf::VERSION\n";

    my $html = "This is a <b>test HTML</b>.";
    my $local_file = "Test.pdf";
    my $apiKey = "Your API key here";

    eval {
        my $client = new HtmlToPdfClient($apiKey);

        $client
            ->setPageSize("A4")
            ->setMargins(0)
            ->setShowPageNumbers('False')
            ->setPageBreaksEnhancedAlgorithm('True')
        ;

        $client->convertHtmlStringToFile($html, $local_file);
    };

    if ($@) {
        print "An error occurred: $@\n";  
    }

For more details and full list of parameters see L<Html To Pdf API|https://selectpdf.com/html-to-pdf-api/>.

=head1 METHODS

=head2 new( $apiKey )

Construct the Html To Pdf Client.

    my $client = SelectPdf::HtmlToPdfClient->new($apiKey);

Parameters:

- $apiKey API Key.
=cut
sub new {
    my $type = shift;
    my $self = $type->SUPER::new;

    # API endpoint
    $self->{apiEndpoint} = "https://selectpdf.com/api2/convert/";

    $self->{parameters}{"key"} = shift;

    bless $self, $type;
    return $self;
}

=head2 convertUrl( $url )

Convert the specified url to PDF.
SelectPdf online API can convert http:// and https:// publicly available urls.

    $content = $client->convertUrl($url);

Parameters:

- $url Address of the web page being converted.

Returns:

- Byte array containing the resulted PDF.
=cut
sub convertUrl($) {
    my($self, $url) = @_;

    $self->{parameters}{"url"} = $url;
    $self->{parameters}{"async"} = "False";
    $self->{parameters}{"html"} = "";
    $self->{parameters}{"base_url"} = "";

    return $self->SUPER::performPost();
}

=head2 convertUrl( $url, $filePath )

Convert the specified url to PDF and writes the resulted PDF to a local file.
SelectPdf online API can convert http:// and https:// publicly available urls.

    $client->convertUrlToFile($url, $filePath);

Parameters:

- $url Address of the web page being converted.

- $filePath Local file including path if necessary.
=cut
sub convertUrlToFile($;$) {
    my($self, $url, $filePath) = @_;

    my $content = $self->convertUrl($url);

    my $file = IO::File->new( $filePath, '>' ) or die "Unable to open output file - $!\n";
    $file->binmode;
    $file->print( $content );
    $file->close;
}

=head2 convertUrlAsync( $url )

Convert the specified url to PDF using an asynchronous call.
SelectPdf online API can convert http:// and https:// publicly available urls.

    $content = $client->convertUrlAsync($url);

Parameters:

- $url Address of the web page being converted.

Returns:

- Byte array containing the resulted PDF.
=cut
sub convertUrlAsync($) {
    my($self, $url) = @_;

    $self->{parameters}{"url"} = $url;
    $self->{parameters}{"html"} = "";
    $self->{parameters}{"base_url"} = "";

    my $JobID = $self->SUPER::startAsyncJob() or die "An error occurred launching the asynchronous call.";

    my $noPings = 0;

    do
    {
        $noPings++;

        # sleep for a few seconds before next ping
        sleep($self->{AsyncCallsPingInterval});

        my $asyncJobClient = new SelectPdf::AsyncJobClient($self->{parameters}{"key"}, $JobID);
        $asyncJobClient->setApiEndpoint($self->{apiAsyncEndpoint});

        my $result = $asyncJobClient->getResult();

        if ($asyncJobClient->finished)
        {
            $self->{numberOfPages} = $asyncJobClient->getNumberOfPages();

            return $result;
        }

    } while ($noPings <= $self->{AsyncCallsMaxPings});

    die "Asynchronous call did not finish in expected timeframe.";

}

=head2 convertUrlToFileAsync( $url, $filePath )

Convert the specified url to PDF using an asynchronous call and writes the resulted PDF to a local file.
SelectPdf online API can convert http:// and https:// publicly available urls.

    $client->convertUrlToFileAsync($url, $filePath);

Parameters:

- $url Address of the web page being converted.

- $filePath Local file including path if necessary.
=cut
sub convertUrlToFileAsync($;$) {
    my($self, $url, $filePath) = @_;

    my $content = $self->convertUrlAsync($url);

    my $file = IO::File->new( $filePath, '>' ) or die "Unable to open output file - $!\n";
    $file->binmode;
    $file->print( $content );
    $file->close;
}

=head2 convertHtmlStringWithBaseUrl( $htmlString, $baseUrl )

Convert the specified HTML string to PDF. Use a base url to resolve relative paths to resources.

    $content = $client->convertHtmlStringWithBaseUrl($htmlString, $baseUrl);

Parameters:

- $htmlString HTML string with the content being converted.

- $baseUrl Base url used to resolve relative paths to resources (css, images, javascript, etc). Must be a http:// or https:// publicly available url.

Returns:

- Byte array containing the resulted PDF.
=cut
sub convertHtmlStringWithBaseUrl($,$) {
    my($self, $htmlString, $baseUrl) = @_;

    $self->{parameters}{"url"} = "";
    $self->{parameters}{"async"} = "False";
    $self->{parameters}{"html"} = $htmlString;
    $self->{parameters}{"base_url"} = $baseUrl;

    return $self->SUPER::performPost();
}

=head2 convertHtmlStringWithBaseUrlToFile( $htmlString, $baseUrl, $filePath )

Convert the specified HTML string to PDF and writes the resulted PDF to a local file. Use a base url to resolve relative paths to resources.

    $client->convertHtmlStringWithBaseUrlToFile($htmlString, $baseUrl, $filePath);

Parameters:

- $htmlString HTML string with the content being converted.

- $baseUrl Base url used to resolve relative paths to resources (css, images, javascript, etc). Must be a http:// or https:// publicly available url.

- $filePath: Local file including path if necessary.

=cut
sub convertHtmlStringWithBaseUrlToFile($,$,$) {
    my($self, $htmlString, $baseUrl, $filePath) = @_;

    my $content = $self->convertHtmlStringWithBaseUrl($htmlString, $baseUrl);

    my $file = IO::File->new( $filePath, '>' ) or die "Unable to open output file - $!\n";
    $file->binmode;
    $file->print( $content );
    $file->close;
}

=head2 convertHtmlStringWithBaseUrlAsync( $htmlString, $baseUrl )

Convert the specified HTML string to PDF with an asynchronous call. Use a base url to resolve relative paths to resources.

    $content = $client->convertHtmlStringWithBaseUrlAsync($htmlString, $baseUrl);

Parameters:

- $htmlString HTML string with the content being converted.

- $baseUrl Base url used to resolve relative paths to resources (css, images, javascript, etc). Must be a http:// or https:// publicly available url.

Returns:

- Byte array containing the resulted PDF.
=cut
sub convertHtmlStringWithBaseUrlAsync($,$) {
    my($self, $htmlString, $baseUrl) = @_;

    $self->{parameters}{"url"} = "";
    $self->{parameters}{"async"} = "False";
    $self->{parameters}{"html"} = $htmlString;
    $self->{parameters}{"base_url"} = $baseUrl;

    my $JobID = $self->SUPER::startAsyncJob() or die "An error occurred launching the asynchronous call.";

    my $noPings = 0;

    do
    {
        $noPings++;

        # sleep for a few seconds before next ping
        sleep($self->{AsyncCallsPingInterval});

        my $asyncJobClient = new SelectPdf::AsyncJobClient($self->{parameters}{"key"}, $JobID);
        $asyncJobClient->setApiEndpoint($self->{apiAsyncEndpoint});

        my $result = $asyncJobClient->getResult();

        if ($asyncJobClient->finished)
        {
            $self->{numberOfPages} = $asyncJobClient->getNumberOfPages();

            return $result;
        }

    } while ($noPings <= $self->{AsyncCallsMaxPings});

    die "Asynchronous call did not finish in expected timeframe.";

}

=head2 convertHtmlStringWithBaseUrlToFileAsync( $htmlString, $baseUrl, $filePath )

Convert the specified HTML string to PDF with an asynchronous call and writes the resulted PDF to a local file. Use a base url to resolve relative paths to resources.

    $client->convertHtmlStringWithBaseUrlToFileAsync($htmlString, $baseUrl, $filePath);

Parameters:

- $htmlString HTML string with the content being converted.

- $baseUrl Base url used to resolve relative paths to resources (css, images, javascript, etc). Must be a http:// or https:// publicly available url.

- $filePath: Local file including path if necessary.

=cut
sub convertHtmlStringWithBaseUrlToFileAsync($,$,$) {
    my($self, $htmlString, $baseUrl, $filePath) = @_;

    my $content = $self->convertHtmlStringWithBaseUrlAsync($htmlString, $baseUrl);

    my $file = IO::File->new( $filePath, '>' ) or die "Unable to open output file - $!\n";
    $file->binmode;
    $file->print( $content );
    $file->close;
}

=head2 convertHtmlString( $htmlString )

Convert the specified HTML string to PDF.

    $content = $client->convertHtmlString($htmlString);

Parameters:

- $htmlString HTML string with the content being converted.

Returns:

- Byte array containing the resulted PDF.
=cut
sub convertHtmlString($) {
    my($self, $htmlString) = @_;

    return $self->convertHtmlStringWithBaseUrl($htmlString, "");
}

=head2 convertHtmlStringToFile( $htmlString, $filePath )

Convert the specified HTML string to PDF and writes the resulted PDF to a local file.

    $client->convertHtmlStringToFile($htmlString, $filePath);

Parameters:

- $htmlString HTML string with the content being converted.

- $filePath: Local file including path if necessary.

=cut
sub convertHtmlStringToFile($,$) {
    my($self, $htmlString, $filePath) = @_;

    $self->convertHtmlStringWithBaseUrlToFile($htmlString, "", $filePath);
}

=head2 convertHtmlStringAsync( $htmlString )

Convert the specified HTML string to PDF with an asynchronous call.

    $content = $client->convertHtmlStringAsync($htmlString);

Parameters:

- $htmlString HTML string with the content being converted.

Returns:

- Byte array containing the resulted PDF.
=cut
sub convertHtmlStringAsync($) {
    my($self, $htmlString) = @_;

    return $self->convertHtmlStringWithBaseUrlAsync($htmlString, "");
}

=head2 convertHtmlStringToFileAsync( $htmlString, $filePath )

Convert the specified HTML string to PDF with an asynchronous call and writes the resulted PDF to a local file.

    $client->convertHtmlStringToFileAsync($htmlString, $filePath);

Parameters:

- $htmlString HTML string with the content being converted.

- $filePath: Local file including path if necessary.

=cut
sub convertHtmlStringToFileAsync($,$) {
    my($self, $htmlString, $filePath) = @_;

    $self->convertHtmlStringWithBaseUrlToFileAsync($htmlString, "", $filePath);
}

=head2 setPageSize( $pageSize )

Set PDF page size. Default value is A4. If page size is set to Custom, use setPageWidth and setPageHeight methods to set the custom width/height of the PDF pages.

Parameters:

- $pageSize: PDF page size. Possible values: Custom, A0, A1, A2, A3, A4, A5, A6, A7, A8, Letter, HalfLetter, Ledger, Legal.

Returns:

- Reference to the current object.
=cut
sub setPageSize($) {
    my($self, $pageSize) = @_;

    if ($pageSize !~ m/^(Custom|A0|A1|A2|A3|A4|A5|A6|A7|A8|Letter|HalfLetter|Ledger|Legal)$/i) {
        die ("Allowed values for Page Size: Custom, A0, A1, A2, A3, A4, A5, A6, A7, A8, Letter, HalfLetter, Ledger, Legal.");
    }

    $self->{parameters}{"page_size"} = $pageSize;
    return $self;
}

=head2 setPageWidth( $pageWidth )

Set PDF page width in points. Default value is 595pt (A4 page width in points). 1pt = 1/72 inch. 
This is taken into account only if page size is set to Custom using setPageSize method.

Parameters:

- $pageWidth: Page width in points.

Returns:

- Reference to the current object.
=cut
sub setPageWidth($) {
    my($self, $pageWidth) = @_;

    $self->{parameters}{"page_width"} = $pageWidth;
    return $self;
}

=head2 setPageHeight( $pageHeight )

Set PDF page height in points. Default value is 842pt (A4 page height in points). 1pt = 1/72 inch. 
This is taken into account only if page size is set to Custom using setPageSize method.

Parameters:

- $pageHeight: Page height in points.

Returns:

- Reference to the current object.
=cut
sub setPageHeight($) {
    my($self, $pageHeight) = @_;

    $self->{parameters}{"page_height"} = $pageHeight;
    return $self;
}

=head2 setPageOrientation( $pageOrientation )

Set PDF page orientation. Default value is Portrait.

Parameters:

- $pageOrientation: PDF page orientation. Possible values: Portrait, Landscape.

Returns:

- Reference to the current object.
=cut
sub setPageOrientation($) {
    my($self, $pageOrientation) = @_;

    if ($pageOrientation !~ m/^(Portrait|Landscape)$/i) {
        die ("Allowed values for Page Orientation: Portrait, Landscape.");
    }

    $self->{parameters}{"page_orientation"} = $pageOrientation;
    return $self;
}

=head2 setMarginTop( $marginTop )

Set top margin of the PDF pages. Default value is 5pt.

Parameters:

- $marginTop: Margin value in points. 1pt = 1/72 inch.

Returns:

- Reference to the current object.
=cut
sub setMarginTop($) {
    my($self, $marginTop) = @_;

    $self->{parameters}{"margin_top"} = $marginTop;
    return $self;
}

=head2 setMarginRight( $marginRight )

Set right margin of the PDF pages. Default value is 5pt.

Parameters:

- $marginRight: Margin value in points. 1pt = 1/72 inch.

Returns:

- Reference to the current object.
=cut
sub setMarginRight($) {
    my($self, $marginRight) = @_;

    $self->{parameters}{"margin_right"} = $marginRight;
    return $self;
}

=head2 setMarginBottom( $marginBottom )

Set bottom margin of the PDF pages. Default value is 5pt.

Parameters:

- $marginBottom: Margin value in points. 1pt = 1/72 inch.

Returns:

- Reference to the current object.
=cut
sub setMarginBottom($) {
    my($self, $marginBottom) = @_;

    $self->{parameters}{"margin_bottom"} = $marginBottom;
    return $self;
}

=head2 setMarginLeft( $marginLeft )

Set left margin of the PDF pages. Default value is 5pt.

Parameters:

- $marginLeft: Margin value in points. 1pt = 1/72 inch.

Returns:

- Reference to the current object.
=cut
sub setMarginLeft($) {
    my($self, $marginLeft) = @_;

    $self->{parameters}{"margin_left"} = $marginLeft;
    return $self;
}

=head2 setMargins( $margin )

Set all margins of the PDF pages to the same value. Default value is 5pt.

Parameters:

- $margin: Margin value in points. 1pt = 1/72 inch.

Returns:

- Reference to the current object.
=cut
sub setMargins($) {
    my($self, $margin) = @_;

    return $self->setMarginTop($margin)->setMarginRight($margin)->setMarginBottom($margin)->setMarginLeft($margin);
}

=head2 setPdfName( $pdfName )

Specify the name of the pdf document that will be created. The default value is Document.pdf.

Parameters:

- $pdfName: Name of the generated PDF document.

Returns:

- Reference to the current object.
=cut
sub setPdfName($) {
    my($self, $pdfName) = @_;

    $self->{parameters}{"pdf_name"} = $pdfName;
    return $self;
}

=head2 setRenderingEngine( $renderingEngine )

Set the rendering engine used for the HTML to PDF conversion. Default value is WebKit.

Parameters:

- $renderingEngine: HTML rendering engine. Possible values: WebKit, Restricted, Blink.

Returns:

- Reference to the current object.
=cut
sub setRenderingEngine($) {
    my($self, $renderingEngine) = @_;

    if ($renderingEngine !~ m/^(WebKit|Restricted|Blink)$/i) {
        die ("Allowed values for Rendering Engine: WebKit, Restricted, Blink.");
    }

    $self->{parameters}{"engine"} = $renderingEngine;
    return $self;
}

=head2 setUserPassword( $userPassword )

Set PDF user password.

Parameters:

- $userPassword: PDF user password.

Returns:

- Reference to the current object.
=cut
sub setUserPassword($) {
    my($self, $userPassword) = @_;

    $self->{parameters}{"user_password"} = $userPassword;
    return $self;
}

=head2 setOwnerPassword( $ownerPassword )

Set PDF owner password.

Parameters:

- $ownerPassword: PDF owner password.

Returns:

- Reference to the current object.
=cut
sub setOwnerPassword($) {
    my($self, $ownerPassword) = @_;

    $self->{parameters}{"owner_password"} = $ownerPassword;
    return $self;
}

=head2 setWebPageWidth( $webPageWidth )

Set the width used by the converter's internal browser window in pixels. The default value is 1024px.

Parameters:

- $webPageWidth: Browser window width in pixels.

Returns:

- Reference to the current object.
=cut
sub setWebPageWidth($) {
    my($self, $webPageWidth) = @_;

    $self->{parameters}{"web_page_width"} = $webPageWidth;
    return $self;
}

=head2 setWebPageHeight( $webPageHeight )

Set the height used by the converter's internal browser window in pixels. 
The default value is 0px and it means that the page height is automatically calculated by the converter.

Parameters:

- $webPageHeight: Browser window height in pixels. Set it to 0px to automatically calculate page height.

Returns:

- Reference to the current object.
=cut
sub setWebPageHeight($) {
    my($self, $webPageHeight) = @_;

    $self->{parameters}{"web_page_height"} = $webPageHeight;
    return $self;
}

=head2 setMinLoadTime( $minLoadTime )

Introduce a delay (in seconds) before the actual conversion to allow the web page to fully load. This method is an alias for setConversionDelay. 
The default value is 1 second. Use a larger value if the web page has content that takes time to render when it is displayed in the browser.

Parameters:

- $minLoadTime:  Delay in seconds.

Returns:

- Reference to the current object.
=cut
sub setMinLoadTime($) {
    my($self, $minLoadTime) = @_;

    $self->{parameters}{"min_load_time"} = $minLoadTime;
    return $self;
}

=head2 setConversionDelay( $delay )

Introduce a delay (in seconds) before the actual conversion to allow the web page to fully load. This method is an alias for setMinLoadTime. 
The default value is 1 second. Use a larger value if the web page has content that takes time to render when it is displayed in the browser.

Parameters:

- $delay:  Delay in seconds.

Returns:

- Reference to the current object.
=cut
sub setConversionDelay($) {
    my($self, $delay) = @_;

    return $self->setMinLoadTime($delay);
}

=head2 setMaxLoadTime( $maxLoadTime )

Set the maximum amount of time (in seconds) that the convert will wait for the page to load. This method is an alias for setNavigationTimeout. 
A timeout error is displayed when this time elapses. The default value is 30 seconds. 
Use a larger value (up to 120 seconds allowed) for pages that take a long time to load.

Parameters:

- $maxLoadTime:  Timeout in seconds.

Returns:

- Reference to the current object.
=cut
sub setMaxLoadTime($) {
    my($self, $maxLoadTime) = @_;

    $self->{parameters}{"max_load_time"} = $maxLoadTime;
    return $self;
}

=head2 setNavigationTimeout( $timeout )

Set the maximum amount of time (in seconds) that the convert will wait for the page to load. This method is an alias for setMaxLoadTime. 
A timeout error is displayed when this time elapses. The default value is 30 seconds. 
Use a larger value (up to 120 seconds allowed) for pages that take a long time to load.

Parameters:

- $timeout:  Timeout in seconds.

Returns:

- Reference to the current object.
=cut
sub setNavigationTimeout($) {
    my($self, $timeout) = @_;

    return $self->setMaxLoadTime($timeout);
}

=head2 setSecureProtocol( $secureProtocol )

Set the protocol used for secure (HTTPS) connections. Set this only if you have an older server that only works with older SSL connections.

Parameters:

- $secureProtocol: Secure protocol. Possible values: 0 (TLS 1.1 or newer), 1 (TLS 1.0), 2 (SSL v3 only).

Returns:

- Reference to the current object.
=cut
sub setSecureProtocol($) {
    my($self, $secureProtocol) = @_;

    if ($secureProtocol ne 0 and $secureProtocol ne 1 and $secureProtocol ne 2) {
        die ("Allowed values for Secure Protocol: 0 (TLS 1.1 or newer), 1 (TLS 1.0), 2 (SSL v3 only).");
    }

    $self->{parameters}{"protocol"} = $secureProtocol;
    return $self;
}

=head2 setUseCssPrint( $useCssPrint )

Specify if the CSS Print media type is used instead of the Screen media type. The default value is False.

Parameters:

- $useCssPrint:  Use CSS Print media or not.

Returns:

- Reference to the current object.
=cut
sub setUseCssPrint($) {
    my($self, $useCssPrint) = @_;

    $self->{parameters}{"use_css_print"} = $self->SUPER::serializeBoolean($useCssPrint);
    return $self;
}

=head2 setBackgroundColor( $backgroundColor )

Specify the background color of the PDF page in RGB html format. The default is #FFFFFF.

Parameters:

- $backgroundColor: Background color in #RRGGBB format.

Returns:

- Reference to the current object.
=cut
sub setBackgroundColor($) {
    my($self, $backgroundColor) = @_;

    if ($backgroundColor !~ m/^#?[0-9a-fA-F]{6}$/) {
        die ("Color value must be in #RRGGBB format.");
    }

    $self->{parameters}{"background_color"} = $backgroundColor;
    return $self;
}

=head2 setDrawHtmlBackground( $drawHtmlBackground )

Set a flag indicating if the web page background is rendered in PDF. The default value is True.

Parameters:

- $drawHtmlBackground: Draw the HTML background or not.

Returns:

- Reference to the current object.
=cut
sub setDrawHtmlBackground($) {
    my($self, $drawHtmlBackground) = @_;

    $self->{parameters}{"draw_html_background"} = $self->SUPER::serializeBoolean($drawHtmlBackground);
    return $self;
}

=head2 setDisableJavascript( $disableJavascript )

Do not run JavaScript in web pages. The default value is False and javascript is executed.

Parameters:

- $disableJavascript: Disable javascript or not.

Returns:

- Reference to the current object.
=cut
sub setDisableJavascript($) {
    my($self, $disableJavascript) = @_;

    $self->{parameters}{"disable_javascript"} = $self->SUPER::serializeBoolean($disableJavascript);
    return $self;
}

=head2 setDisableInternalLinks( $disableInternalLinks )

Do not create internal links in the PDF. The default value is False and internal links are created.

Parameters:

- $disableInternalLinks: Disable internal links or not.

Returns:

- Reference to the current object.
=cut
sub setDisableInternalLinks($) {
    my($self, $disableInternalLinks) = @_;

    $self->{parameters}{"disable_internal_links"} = $self->SUPER::serializeBoolean($disableInternalLinks);
    return $self;
}

=head2 setDisableExternalLinks( $disableExternalLinks )

Do not create external links in the PDF. The default value is False and external links are created.

Parameters:

- $disableExternalLinks: Disable external links or not.

Returns:

- Reference to the current object.
=cut
sub setDisableExternalLinks($) {
    my($self, $disableExternalLinks) = @_;

    $self->{parameters}{"disable_external_links"} = $self->SUPER::serializeBoolean($disableExternalLinks);
    return $self;
}

=head2 setRenderOnTimeout( $renderOnTimeout )

Try to render the PDF even in case of the web page loading timeout. The default value is False and an exception is raised in case of web page navigation timeout.

Parameters:

- $renderOnTimeout: Render in case of timeout or not.

Returns:

- Reference to the current object.
=cut
sub setRenderOnTimeout($) {
    my($self, $renderOnTimeout) = @_;

    $self->{parameters}{"render_on_timeout"} = $self->SUPER::serializeBoolean($renderOnTimeout);
    return $self;
}

=head2 setKeepImagesTogether( $keepImagesTogether )

Avoid breaking images between PDF pages. The default value is False and images are split between pages if larger.

Parameters:

- $keepImagesTogether: Try to keep images on same page or not.

Returns:

- Reference to the current object.
=cut
sub setKeepImagesTogether($) {
    my($self, $keepImagesTogether) = @_;

    $self->{parameters}{"keep_images_together"} = $self->SUPER::serializeBoolean($keepImagesTogether);
    return $self;
}

=head2 setDocTitle( $docTitle )

Set the PDF document title.

Parameters:

- $docTitle: Document title.

Returns:

- Reference to the current object.
=cut
sub setDocTitle($) {
    my($self, $docTitle) = @_;

    $self->{parameters}{"doc_title"} = $docTitle;
    return $self;
}

=head2 setDocSubject( $docSubject )

Set the PDF document subject.

Parameters:

- $docSubject: Document subject.

Returns:

- Reference to the current object.
=cut
sub setDocSubject($) {
    my($self, $docSubject) = @_;

    $self->{parameters}{"doc_subject"} = $docSubject;
    return $self;
}

=head2 setDocKeywords( $docKeywords )

Set the PDF document keywords.

Parameters:

- $docKeywords: Document keywords.

Returns:

- Reference to the current object.
=cut
sub setDocKeywords($) {
    my($self, $docKeywords) = @_;

    $self->{parameters}{"doc_keywords"} = $docKeywords;
    return $self;
}

=head2 setDocAuthor( $docAuthor )

Set the PDF document author.

Parameters:

- $docAuthor: Document author.

Returns:

- Reference to the current object.
=cut
sub setDocAuthor($) {
    my($self, $docAuthor) = @_;

    $self->{parameters}{"doc_author"} = $docAuthor;
    return $self;
}

=head2 setDocAddCreationDate( $docAddCreationDate )

Add the date and time when the PDF document was created to the PDF document information. The default value is False.

Parameters:

- $docAddCreationDate: Add creation date to the document metadata or not.

Returns:

- Reference to the current object.
=cut
sub setDocAddCreationDate($) {
    my($self, $docAddCreationDate) = @_;

    $self->{parameters}{"doc_add_creation_date"} = $self->SUPER::serializeBoolean($docAddCreationDate);
    return $self;
}

=head2 setViewerPageLayout( $pageLayout )

Set the page layout to be used when the document is opened in a PDF viewer. The default value is 1 - OneColumn.

Parameters:

- $pageLayout: Page layout. Possible values: 0 (Single Page), 1 (One Column), 2 (Two Column Left), 3 (Two Column Right).

Returns:

- Reference to the current object.
=cut
sub setViewerPageLayout($) {
    my($self, $pageLayout) = @_;

    if ($pageLayout ne 0 and $pageLayout ne 1 and $pageLayout ne 2 and $pageLayout ne 3) {
        die ("Allowed values for Page Layout: 0 (Single Page), 1 (One Column), 2 (Two Column Left), 3 (Two Column Right).");
    }

    $self->{parameters}{"viewer_page_layout"} = $pageLayout;
    return $self;
}

=head2 setViewerPageMode( $pageMode )

Set the document page mode when the pdf document is opened in a PDF viewer. The default value is 0 - UseNone.

Parameters:

- $pageMode: Page mode. Possible values: 0 (Use None), 1 (Use Outlines), 2 (Use Thumbs), 3 (Full Screen), 4 (Use OC), 5 (Use Attachments).

Returns:

- Reference to the current object.
=cut
sub setViewerPageMode($) {
    my($self, $pageMode) = @_;

    if ($pageMode ne 0 and $pageMode ne 1 and $pageMode ne 2 and $pageMode ne 3 and $pageMode ne 4 and $pageMode ne 5) {
        die ("Allowed values for Page Mode: 0 (Use None), 1 (Use Outlines), 2 (Use Thumbs), 3 (Full Screen), 4 (Use OC), 5 (Use Attachments).");
    }

    $self->{parameters}{"viewer_page_mode"} = $pageMode;
    return $self;
}

=head2 setViewerCenterWindow( $viewerCenterWindow )

Set a flag specifying whether to position the document's window in the center of the screen. The default value is False.

Parameters:

- $viewerCenterWindow: Center window or not.

Returns:

- Reference to the current object.
=cut
sub setViewerCenterWindow($) {
    my($self, $viewerCenterWindow) = @_;

    $self->{parameters}{"viewer_center_window"} = $self->SUPER::serializeBoolean($viewerCenterWindow);
    return $self;
}

=head2 setViewerDisplayDocTitle( $viewerDisplayDocTitle )

Set a flag specifying whether the window's title bar should display the document title taken from document information. The default value is False.

Parameters:

- $viewerDisplayDocTitle: Display title or not.

Returns:

- Reference to the current object.
=cut
sub setViewerDisplayDocTitle($) {
    my($self, $viewerDisplayDocTitle) = @_;

    $self->{parameters}{"viewer_display_doc_title"} = $self->SUPER::serializeBoolean($viewerDisplayDocTitle);
    return $self;
}

=head2 setViewerFitWindow( $viewerFitWindow )

Set a flag specifying whether to resize the document's window to fit the size of the first displayed page. The default value is False.

Parameters:

- $viewerFitWindow: Fit window or not.

Returns:

- Reference to the current object.
=cut
sub setViewerFitWindow($) {
    my($self, $viewerFitWindow) = @_;

    $self->{parameters}{"viewer_fit_window"} = $self->SUPER::serializeBoolean($viewerFitWindow);
    return $self;
}

=head2 setViewerHideMenuBar( $viewerHideMenuBar )

Set a flag specifying whether to hide the pdf viewer application's menu bar when the document is active. The default value is False.

Parameters:

- $viewerHideMenuBar: Hide menu bar or not.

Returns:

- Reference to the current object.
=cut
sub setViewerHideMenuBar($) {
    my($self, $viewerHideMenuBar) = @_;

    $self->{parameters}{"viewer_hide_menu_bar"} = $self->SUPER::serializeBoolean($viewerHideMenuBar);
    return $self;
}

=head2 setViewerHideToolbar( $viewerHideToolbar )

Set a flag specifying whether to hide the pdf viewer application's tool bars when the document is active. The default value is False.

Parameters:

- $viewerHideToolbar: Hide tool bars or not.

Returns:

- Reference to the current object.
=cut
sub setViewerHideToolbar($) {
    my($self, $viewerHideToolbar) = @_;

    $self->{parameters}{"viewer_hide_toolbar"} = $self->SUPER::serializeBoolean($viewerHideToolbar);
    return $self;
}

=head2 setViewerHideWindowUI( $viewerHideWindowUI )

Set a flag specifying whether to hide user interface elements in the document's window (such as scroll bars and navigation controls), 
leaving only the document's contents displayed.

Parameters:

- $viewerHideWindowUI: Hide window UI or not.

Returns:

- Reference to the current object.
=cut
sub setViewerHideWindowUI($) {
    my($self, $viewerHideWindowUI) = @_;

    $self->{parameters}{"viewer_hide_window_ui"} = $self->SUPER::serializeBoolean($viewerHideWindowUI);
    return $self;
}

=head2 setShowHeader( $showHeader )

Control if a custom header is displayed in the generated PDF document. The default value is False.

Parameters:

- $showHeader:  Show header or not.

Returns:

- Reference to the current object.
=cut
sub setShowHeader($) {
    my($self, $showHeader) = @_;

    $self->{parameters}{"show_header"} = $self->SUPER::serializeBoolean($showHeader);
    return $self;
}

=head2 setHeaderHeight( $height )

The height of the pdf document header. This height is specified in points. 1 point is 1/72 inch. The default value is 50.

Parameters:

- $height: Header height.

Returns:

- Reference to the current object.
=cut
sub setHeaderHeight($) {
    my($self, $height) = @_;

    $self->{parameters}{"header_height"} = $height;
    return $self;
}

=head2 setHeaderUrl( $url )

Set the url of the web page that is converted and rendered in the PDF document header.

Parameters:

- $url: The url of the web page that is converted and rendered in the pdf document header.

Returns:

- Reference to the current object.
=cut
sub setHeaderUrl($) {
    my($self, $url) = @_;

    $self->{parameters}{"header_url"} = $url;
    return $self;
}

=head2 setHeaderHtml( $html )

Set the raw html that is converted and rendered in the pdf document header.

Parameters:

- $html: The raw html that is converted and rendered in the pdf document header.

Returns:

- Reference to the current object.
=cut
sub setHeaderHtml($) {
    my($self, $html) = @_;

    $self->{parameters}{"header_html"} = $html;
    return $self;
}

=head2 setHeaderBaseUrl( $baseUrl )

Set an optional base url parameter can be used together with the header HTML to resolve relative paths from the html string.

Parameters:

- $baseUrl: Header base url.

Returns:

- Reference to the current object.
=cut
sub setHeaderBaseUrl($) {
    my($self, $baseUrl) = @_;

    $self->{parameters}{"header_base_url"} = $baseUrl;
    return $self;
}

=head2 setHeaderDisplayOnFirstPage( $displayOnFirstPage )

Control the visibility of the header on the first page of the generated pdf document. The default value is True.

Parameters:

- $displayOnFirstPage:  Display header on the first page or not. 

Returns:

- Reference to the current object.
=cut
sub setHeaderDisplayOnFirstPage($) {
    my($self, $displayOnFirstPage) = @_;

    $self->{parameters}{"header_display_on_first_page"} = $self->SUPER::serializeBoolean($displayOnFirstPage);
    return $self;
}

=head2 setHeaderDisplayOnOddPages( $displayOnOddPages )

Control the visibility of the header on the odd numbered pages of the generated pdf document. The default value is True.

Parameters:

- $displayOnOddPages:  Display header on odd pages or not.

Returns:

- Reference to the current object.
=cut
sub setHeaderDisplayOnOddPages($) {
    my($self, $displayOnOddPages) = @_;

    $self->{parameters}{"header_display_on_odd_pages"} = $self->SUPER::serializeBoolean($displayOnOddPages);
    return $self;
}

=head2 setHeaderDisplayOnEvenPages( $displayOnEvenPages )

Control the visibility of the header on the even numbered pages of the generated pdf document. The default value is True.

Parameters:

- $displayOnEvenPages:  Display header on even pages or not.

Returns:

- Reference to the current object.
=cut
sub setHeaderDisplayOnEvenPages($) {
    my($self, $displayOnEvenPages) = @_;

    $self->{parameters}{"header_display_on_even_pages"} = $self->SUPER::serializeBoolean($displayOnEvenPages);
    return $self;
}

=head2 setHeaderWebPageWidth( $headerWebPageWidth )

Set the width in pixels used by the converter's internal browser window during the conversion of the header content. The default value is 1024px.

Parameters:

- $headerWebPageWidth: Browser window width in pixels.

Returns:

- Reference to the current object.
=cut
sub setHeaderWebPageWidth($) {
    my($self, $headerWebPageWidth) = @_;

    $self->{parameters}{"header_web_page_width"} = $headerWebPageWidth;
    return $self;
}

=head2 setHeaderWebPageHeight( $headerWebPageHeight )

Set the height in pixels used by the converter's internal browser window during the conversion of the header content. 
The default value is 0px and it means that the page height is automatically calculated by the converter.

Parameters:

- $headerWebPageHeight: Browser window height in pixels. Set it to 0px to automatically calculate page height.

Returns:

- Reference to the current object.
=cut
sub setHeaderWebPageHeight($) {
    my($self, $headerWebPageHeight) = @_;

    $self->{parameters}{"header_web_page_height"} = $headerWebPageHeight;
    return $self;
}



=head2 setShowFooter( $showFooter )

Control if a custom footer is displayed in the generated PDF document. The default value is False.

Parameters:

- $showFooter:  Show footer or not.

Returns:

- Reference to the current object.
=cut
sub setShowFooter($) {
    my($self, $showFooter) = @_;

    $self->{parameters}{"show_footer"} = $self->SUPER::serializeBoolean($showFooter);
    return $self;
}

=head2 setFooterHeight( $height )

The height of the pdf document footer. This height is specified in points. 1 point is 1/72 inch. The default value is 50.

Parameters:

- $height: Footer height.

Returns:

- Reference to the current object.
=cut
sub setFooterHeight($) {
    my($self, $height) = @_;

    $self->{parameters}{"footer_height"} = $height;
    return $self;
}

=head2 setFooterUrl( $url )

Set the url of the web page that is converted and rendered in the PDF document footer.

Parameters:

- $url: The url of the web page that is converted and rendered in the pdf document footer.

Returns:

- Reference to the current object.
=cut
sub setFooterUrl($) {
    my($self, $url) = @_;

    $self->{parameters}{"footer_url"} = $url;
    return $self;
}

=head2 setFooterHtml( $html )

Set the raw html that is converted and rendered in the pdf document footer.

Parameters:

- $html: The raw html that is converted and rendered in the pdf document footer.

Returns:

- Reference to the current object.
=cut
sub setFooterHtml($) {
    my($self, $html) = @_;

    $self->{parameters}{"footer_html"} = $html;
    return $self;
}

=head2 setFooterBaseUrl( $baseUrl )

Set an optional base url parameter can be used together with the footer HTML to resolve relative paths from the html string.

Parameters:

- $baseUrl: Footer base url.

Returns:

- Reference to the current object.
=cut
sub setFooterBaseUrl($) {
    my($self, $baseUrl) = @_;

    $self->{parameters}{"footer_base_url"} = $baseUrl;
    return $self;
}

=head2 setFooterDisplayOnFirstPage( $displayOnFirstPage )

Control the visibility of the footer on the first page of the generated pdf document. The default value is True.

Parameters:

- $displayOnFirstPage: Display footer on the first page or not. 

Returns:

- Reference to the current object.
=cut
sub setFooterDisplayOnFirstPage($) {
    my($self, $displayOnFirstPage) = @_;

    $self->{parameters}{"footer_display_on_first_page"} = $self->SUPER::serializeBoolean($displayOnFirstPage);
    return $self;
}

=head2 setFooterDisplayOnOddPages( $displayOnOddPages )

Control the visibility of the footer on the odd numbered pages of the generated pdf document. The default value is True.

Parameters:

- $displayOnOddPages: Display footer on odd pages or not.

Returns:

- Reference to the current object.
=cut
sub setFooterDisplayOnOddPages($) {
    my($self, $displayOnOddPages) = @_;

    $self->{parameters}{"footer_display_on_odd_pages"} = $self->SUPER::serializeBoolean($displayOnOddPages);
    return $self;
}

=head2 setFooterDisplayOnEvenPages( $displayOnEvenPages )

Control the visibility of the footer on the even numbered pages of the generated pdf document. The default value is True.

Parameters:

- $displayOnEvenPages: Display footer on even pages or not.

Returns:

- Reference to the current object.
=cut
sub setFooterDisplayOnEvenPages($) {
    my($self, $displayOnEvenPages) = @_;

    $self->{parameters}{"footer_display_on_even_pages"} = $self->SUPER::serializeBoolean($displayOnEvenPages);
    return $self;
}

=head2 setFooterDisplayOnLastPage( $displayOnLastPage )

Add a special footer on the last page of the generated pdf document only. The default value is False. 
Use setFooterUrl or setFooterHtml and setFooterBaseUrl to specify the content of the last page footer. 
Use setFooterHeight to specify the height of the special last page footer.

Parameters:

- $displayOnLastPage: Display special footer on the last page or not.

Returns:

- Reference to the current object.
=cut
sub setFooterDisplayOnLastPage($) {
    my($self, $displayOnLastPage) = @_;

    $self->{parameters}{"footer_display_on_last_page"} = $self->SUPER::serializeBoolean($displayOnLastPage);
    return $self;
}

=head2 setFooterWebPageWidth( $footerWebPageWidth )

Set the width in pixels used by the converter's internal browser window during the conversion of the footer content. The default value is 1024px.

Parameters:

- $footerWebPageWidth: Browser window width in pixels.

Returns:

- Reference to the current object.
=cut
sub setFooterWebPageWidth($) {
    my($self, $footerWebPageWidth) = @_;

    $self->{parameters}{"footer_web_page_width"} = $footerWebPageWidth;
    return $self;
}

=head2 setFooterWebPageHeight( $footerWebPageHeight )

Set the height in pixels used by the converter's internal browser window during the conversion of the footer content. 
The default value is 0px and it means that the page height is automatically calculated by the converter.

Parameters:

- $footerWebPageHeight: Browser window height in pixels. Set it to 0px to automatically calculate page height.

Returns:

- Reference to the current object.
=cut
sub setFooterWebPageHeight($) {
    my($self, $footerWebPageHeight) = @_;

    $self->{parameters}{"footer_web_page_height"} = $footerWebPageHeight;
    return $self;
}


=head2 setShowPageNumbers( $showPageNumbers )

Show page numbers. Default value is True. Page numbers will be displayed in the footer of the PDF document.

Parameters:

- $showPageNumbers: Show page numbers or not.

Returns:

- Reference to the current object.
=cut
sub setShowPageNumbers($) {
    my($self, $showPageNumbers) = @_;

    $self->{parameters}{"page_numbers"} = $self->SUPER::serializeBoolean($showPageNumbers);
    return $self;
}

=head2 setPageNumbersFirst( $firstPageNumber )

Control the page number for the first page being rendered. The default value is 1.

Parameters:

- $firstPageNumber: First page number.

Returns:

- Reference to the current object.
=cut
sub setPageNumbersFirst($) {
    my($self, $firstPageNumber) = @_;

    $self->{parameters}{"page_numbers_first"} = $firstPageNumber;
    return $self;
}

=head2 setPageNumbersOffset( $totalPagesOffset )

Control the total number of pages offset in the generated pdf document. The default value is 0.

Parameters:

- $totalPagesOffset: Offset for the total number of pages in the generated pdf document.

Returns:

- Reference to the current object.
=cut
sub setPageNumbersOffset($) {
    my($self, $totalPagesOffset) = @_;

    $self->{parameters}{"page_numbers_offset"} = $totalPagesOffset;
    return $self;
}

=head2 setPageNumbersTemplate( $template )

Set the text that is used to display the page numbers. It can contain the placeholder {page_number} for the current page number and {total_pages}
for the total number of pages. The default value is "Page: {page_number} of {total_pages}".

Parameters:

- $template: Page numbers template.

Returns:

- Reference to the current object.
=cut
sub setPageNumbersTemplate($) {
    my($self, $template) = @_;

    $self->{parameters}{"page_numbers_template"} = $template;
    return $self;
}

=head2 setPageNumbersFontName( $fontName )

Set the font used to display the page numbers text. The default value is "Helvetica".

Parameters:

- $fontName: The font used to display the page numbers text.

Returns:

- Reference to the current object.
=cut
sub setPageNumbersFontName($) {
    my($self, $fontName) = @_;

    $self->{parameters}{"page_numbers_font_name"} = $fontName;
    return $self;
}

=head2 setPageNumbersFontSize( $fontSize )

Set the size of the font used to display the page numbers. The default value is 10 points.

Parameters:

- $fontSize: The size in points of the font used to display the page numbers.

Returns:

- Reference to the current object.
=cut
sub setPageNumbersFontSize($) {
    my($self, $fontSize) = @_;

    $self->{parameters}{"page_numbers_font_size"} = $fontSize;
    return $self;
}

=head2 setPageNumbersAlignment( $alignment )

Set the alignment of the page numbers text. The default value is "2" - Right.

Parameters:

- $alignment: The alignment of the page numbers text. Possible values: 1 (Left), 2 (Center), 3 (Right).

Returns:

- Reference to the current object.
=cut
sub setPageNumbersAlignment($) {
    my($self, $alignment) = @_;

    if ($alignment ne 1 and $alignment ne 2 and $alignment ne 3) {
        die ("Allowed values for Page Numbers Alignment: 1 (Left), 2 (Center), 3 (Right).");
    }

    $self->{parameters}{"page_numbers_alignment"} = $alignment;
    return $self;
}

=head2 setPageNumbersColor( $color )

Specify the color of the page numbers text in #RRGGBB html format. The default value is #333333.

Parameters:

- $color: Page numbers color.

Returns:

- Reference to the current object.
=cut
sub setPageNumbersColor($) {
    my($self, $color) = @_;

    if ($color !~ m/^#?[0-9a-fA-F]{6}$/) {
        die ("Color value must be in #RRGGBB format.");
    }

    $self->{parameters}{"page_numbers_color"} = $color;
    return $self;
}

=head2 setPageNumbersVerticalPosition( $position )

Specify the position in points on the vertical where the page numbers text is displayed in the footer. The default value is 10 points.

Parameters:

- $position: Page numbers Y position in points.

Returns:

- Reference to the current object.
=cut
sub setPageNumbersVerticalPosition($) {
    my($self, $position) = @_;

    $self->{parameters}{"page_numbers_pos_y"} = $position;
    return $self;
}

=head2 setPdfBookmarksSelectors( $selectors )

Generate automatic bookmarks in pdf. The elements that will be bookmarked are defined using CSS selectors. 
For example, the selector for all the H1 elements is "H1", the selector for all the elements with the CSS class name 'myclass' is "*.myclass" and 
the selector for the elements with the id 'myid' is "*#myid". 
Read more about CSS selectors <a href="http://www.w3schools.com/cssref/css_selectors.asp" target="_blank">here</a>.

Parameters:

- $selectors: CSS selectors used to identify HTML elements, comma separated.

Returns:

- Reference to the current object.
=cut
sub setPdfBookmarksSelectors($) {
    my($self, $selectors) = @_;

    $self->{parameters}{"pdf_bookmarks_selectors"} = $selectors;
    return $self;
}

=head2 setPdfHideElements( $selectors )

Exclude page elements from the conversion. The elements that will be excluded are defined using CSS selectors.  
For example, the selector for all the H1 elements is "H1", the selector for all the elements with the CSS class name 'myclass' is "*.myclass" and 
the selector for the elements with the id 'myid' is "*#myid". 
Read more about CSS selectors <a href="http://www.w3schools.com/cssref/css_selectors.asp" target="_blank">here</a>.

Parameters:

- $selectors: CSS selectors used to identify HTML elements, comma separated.

Returns:

- Reference to the current object.
=cut
sub setPdfHideElements($) {
    my($self, $selectors) = @_;

    $self->{parameters}{"pdf_hide_elements"} = $selectors;
    return $self;
}

=head2 setPdfShowOnlyElementID( $elementID )

Convert only a specific section of the web page to pdf. The section that will be converted to pdf is specified by the html element ID. 
The element can be anything (image, table, table row, div, text, etc).

Parameters:

- $elementID: HTML element ID.

Returns:

- Reference to the current object.
=cut
sub setPdfShowOnlyElementID($) {
    my($self, $elementID) = @_;

    $self->{parameters}{"pdf_show_only_element_id"} = $elementID;
    return $self;
}

=head2 setPdfWebElementsSelectors( $selectors )

Get the locations of page elements from the conversion. The elements that will have their locations retrieved are defined using CSS selectors.  
For example, the selector for all the H1 elements is "H1", the selector for all the elements with the CSS class name 'myclass' is "*.myclass" and 
the selector for the elements with the id 'myid' is "*#myid". 
Read more about CSS selectors <a href="http://www.w3schools.com/cssref/css_selectors.asp" target="_blank">here</a>.

Parameters:

- $selectors: CSS selectors used to identify HTML elements, comma separated.

Returns:

- Reference to the current object.
=cut
sub setPdfWebElementsSelectors($) {
    my($self, $selectors) = @_;

    $self->{parameters}{"pdf_web_elements_selectors"} = $selectors;
    return $self;
}

=head2 setStartupMode( $startupMode )

Set converter startup mode. The default value is Automatic and the conversion is started immediately. 
By default this is set to Automatic and the conversion is started as soon as the page loads (and conversion delay set with setConversionDelay elapses). 
If set to Manual, the conversion is started only by a javascript call to SelectPdf.startConversion() from within the web page.

Parameters:

- $startupMode: Converter startup mode. Possible values: Automatic, Manual.

Returns:

- Reference to the current object.
=cut
sub setStartupMode($) {
    my($self, $startupMode) = @_;

    if ($startupMode !~ m/^(Automatic|Manual)$/i) {
        die ("Allowed values for Startup Mode: Automatic, Manual.");
    }

    $self->{parameters}{"startup_mode"} = $startupMode;
    return $self;
}

=head2 setSkipDecoding( $skipDecoding )

Internal use only.

Parameters:

- $skipDecoding: The default value is True.

Returns:

- Reference to the current object.
=cut
sub setSkipDecoding($) {
    my($self, $skipDecoding) = @_;

    $self->{parameters}{"skip_decoding"} = $self->SUPER::serializeBoolean($skipDecoding);
    return $self;
}

=head2 setScaleImages( $scaleImages )

Set a flag indicating if the images from the page are scaled during the conversion process. The default value is False and images are not scaled.

Parameters:

- $scaleImages: Scale images or not.

Returns:

- Reference to the current object.
=cut
sub setScaleImages($) {
    my($self, $scaleImages) = @_;

    $self->{parameters}{"scale_images"} = $self->SUPER::serializeBoolean($scaleImages);
    return $self;
}

=head2 setSinglePagePdf( $generateSinglePagePdf )

Generate a single page PDF. The converter will automatically resize the PDF page to fit all the content in a single page. 
The default value of this property is False and the PDF will contain several pages if the content is large.

Parameters:

- $generateSinglePagePdf: Generate a single page PDF or not.

Returns:

- Reference to the current object.
=cut
sub setSinglePagePdf($) {
    my($self, $generateSinglePagePdf) = @_;

    $self->{parameters}{"single_page_pdf"} = $self->SUPER::serializeBoolean($generateSinglePagePdf);
    return $self;
}

=head2 setPageBreaksEnhancedAlgorithm( $enableEnhancedPageBreaksAlgorithm )

Get or set a flag indicating if an enhanced custom page breaks algorithm is used. 
The enhanced algorithm is a little bit slower but it will prevent the appearance of hidden text in the PDF when custom page breaks are used. 
The default value for this property is False.

Parameters:

- $enableEnhancedPageBreaksAlgorithm: Enable enhanced page breaks algorithm or not.

Returns:

- Reference to the current object.
=cut
sub setPageBreaksEnhancedAlgorithm($) {
    my($self, $enableEnhancedPageBreaksAlgorithm) = @_;

    $self->{parameters}{"page_breaks_enhanced_algorithm"} = $self->SUPER::serializeBoolean($enableEnhancedPageBreaksAlgorithm);
    return $self;
}

=head2 setCookies( $cookies )

Set HTTP cookies for the web page being converted.

Parameters:

- $cookies: Dictionary with HTTP cookies that will be sent to the page being converted.

Returns:

- Reference to the current object.
=cut
sub setCookies($) {
    my($self, $cookies) = @_;

    my $url = URI->new('', 'http');
    $url->query_form(%$cookies);
    my $cookiesString = $url->query;

    $self->{parameters}{"cookies_string"} = $cookiesString;
    return $self;
}

=head2 setCustomParameter( $parameterName, $parameterValue )

Set a custom parameter. Do not use this method unless advised by SelectPdf.

Parameters:

- $parameterName: Parameter name.

- $parameterValue: Parameter value.

Returns:

- Reference to the current object.
=cut
sub setCustomParameter($,$) {
    my($self, $parameterName, $parameterValue) = @_;

    $self->{parameters}{$parameterName} = $parameterValue;
    return $self;
}

=head2 getWebElements

Get the locations of certain web elements. This is retrieved if pdf_web_elements_selectors parameter is set and elements were found to match the selectors.

Returns:

- Json with web elements locations.
=cut
sub getWebElements {
    my($self) = @_;

    my $webElementsClient = SelectPdf::WebElementsClient->new($self->{parameters}{"key"}, $self->{jobId});
    $webElementsClient->setApiEndpoint($self->{apiWebElementsEndpoint});
    
    return $webElementsClient->getWebElements();
}



1;