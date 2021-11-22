package SelectPdf::PdfMergeClient;

use JSON;
use SelectPdf::ApiClient;
use SelectPdf::AsyncJobClient;
use strict;
our @ISA = qw(SelectPdf::ApiClient);

=head1 NAME

SelectPdf::PdfMergeClient - Pdf Merge with SelectPdf Online API.

=head1 SYNOPSIS

Merge PDFs from local disk or public url and save result into a file on disk.

    use SelectPdf;
    print "This is SelectPdf-$SelectPdf::VERSION\n";

    my $test_url = "https://selectpdf.com/demo/files/selectpdf.pdf";
    my $test_pdf = "Input.pdf";
    my $local_file = "Result.pdf";
    my $apiKey = "Your API key here";

    eval {
        my $client = new SelectPdf::PdfMergeClient($apiKey);

        # set parameters - see full list at https://selectpdf.com/pdf-merge-api/
        $client
            # specify the pdf files that will be merged (order will be preserved in the final pdf)

            ->addFile($test_pdf) # add PDF from local file
            ->addUrlFile($test_url) # add PDF From public url
            #->addFileWithPassword($test_pdf, "pdf_password") # add PDF (that requires a password) from local file
            #->addUrlFileWithPassword($test_url, "pdf_password") # add PDF (that requires a password) from public url
        ;

        print "Starting pdf merge ...\n";

        # merge pdfs to local file
        $client->saveToFile($local_file);

        # merge pdfs to memory
        # my $pdf = $client->save();

        print "Finished! Number of pages: " . $client->getNumberOfPages() . ".\n";

        # get API usage
        my $usageClient = new SelectPdf::UsageClient($apiKey);
        my $usage = $usageClient->getUsage(0);
        print("Usage: " . encode_json($usage) . "\n");
        print("Conversions remained this month: ". $usage->{"available"});
    };

    if ($@) {
        print "An error occurred: $@\n";  
    }

For more details and full list of parameters see L<Pdf Merge API|https://selectpdf.com/pdf-merge-api/>.

=head1 METHODS

=head2 new( $apiKey )

Construct the Pdf Merge Client.

    my $client = SelectPdf::PdfMergeClient->new($apiKey);

Parameters:

- $apiKey: API Key.
=cut
sub new {
    my $type = shift;
    my $self = $type->SUPER::new;

    # API endpoint
    $self->{apiEndpoint} = "https://selectpdf.com/api2/pdfmerge/";

    $self->{fileIdx} = 0;

    $self->{parameters}{"key"} = shift;

    bless $self, $type;
    return $self;
}

=head2 addFile( $inputPdf )

Add local PDF document to the list of input files.

    my $client = new SelectPdf::PdfMergeClient($apiKey);
    $client->addFile($inputPdf);

Parameters:

- $inputPdf: Path to a local PDF file.

Returns:

- Reference to the current object.
=cut
sub addFile($) {
    my($self, $inputPdf) = @_;

    $self->{fileIdx} = $self->{fileIdx} + 1;

    $self->{files}{"file_" . $self->{fileIdx}} = $inputPdf;
    $self->{parameters}{"url_" . $self->{fileIdx}} = "";
    $self->{parameters}{"password_" . $self->{fileIdx}} = "";

    return $self;
}

=head2 addFileWithPassword( $inputPdf, $userPassword )

Add local PDF document to the list of input files.

    my $client = new SelectPdf::PdfMergeClient($apiKey);
    $client->addFileWithPassword($inputPdf, $userPassword);

Parameters:

- $inputPdf: Path to a local PDF file.

- $userPassword: User password for the PDF document.

Returns:

- Reference to the current object.
=cut
sub addFileWithPassword($,$) {
    my($self, $inputPdf, $userPassword) = @_;

    $self->{fileIdx} = $self->{fileIdx} + 1;

    $self->{files}{"file_" . $self->{fileIdx}} = $inputPdf;
    $self->{parameters}{"url_" . $self->{fileIdx}} = "";
    $self->{parameters}{"password_" . $self->{fileIdx}} = $userPassword;

    return $self;
}

=head2 addUrlFile( $inputUrl )

Add remote PDF document to the list of input files.

    my $client = new SelectPdf::PdfMergeClient($apiKey);
    $client->addUrlFile($inputUrl);

Parameters:

- $inputUrl: Url of a remote PDF file.

Returns:

- Reference to the current object.
=cut
sub addUrlFile($) {
    my($self, $inputUrl) = @_;

    $self->{fileIdx} = $self->{fileIdx} + 1;

    $self->{files}{"file_" . $self->{fileIdx}} = "";
    $self->{parameters}{"url_" . $self->{fileIdx}} = $inputUrl;
    $self->{parameters}{"password_" . $self->{fileIdx}} = "";

    return $self;
}

=head2 addUrlFileWithPassword( $inputUrl, $userPassword )

Add remote PDF document to the list of input files.

    my $client = new SelectPdf::PdfMergeClient($apiKey);
    $client->addUrlFileWithPassword($inputUrl, $userPassword);

Parameters:

- $inputUrl: Url of a remote PDF file.

- $userPassword: User password for the PDF document.

Returns:

- Reference to the current object.
=cut
sub addUrlFileWithPassword($,$) {
    my($self, $inputUrl, $userPassword) = @_;

    $self->{fileIdx} = $self->{fileIdx} + 1;

    $self->{files}{"file_" . $self->{fileIdx}} = "";
    $self->{parameters}{"url_" . $self->{fileIdx}} = $inputUrl;
    $self->{parameters}{"password_" . $self->{fileIdx}} = $userPassword;

    return $self;
}

=head2 save

Merge all specified input pdfs and return the resulted PDF.

    my $client = new SelectPdf::PdfMergeClient($apiKey);
    $client->addFile($inputPdf1);
    $client->addFile($inputPdf2);
    $content = $client->save();

Returns:

- Byte array containing the resulted PDF.
=cut
sub save() {
    my($self) = @_;

    $self->{parameters}{"async"} = "False";
    $self->{parameters}{"files_no"} = $self->{fileIdx};

    my $result = $self->SUPER::performPostAsMultipartFormData();

    $self->{fileIdx} = 0;
    $self->{files} = {};

    return $result;
}

=head2 saveToFile( $filePath )

Merge all specified input pdfs and writes the resulted PDF to a local file.

    my $client = new SelectPdf::PdfMergeClient($apiKey);
    $client->addFile($inputPdf1);
    $client->addFile($inputPdf2);
    $client->saveToFile($filePath);

Parameters:

- $filePath: Local file including path if necessary.

Returns:

- Byte array containing the resulted PDF.
=cut
sub saveToFile($) {
    my($self, $filePath) = @_;

    my $result = $self->save();

    my $file = IO::File->new( $filePath, '>' ) or die "Unable to open output file - $!\n";
    $file->binmode;
    $file->print( $result );
    $file->close;
}

=head2 saveAsync

Merge all specified input pdfs and return the resulted PDF.

    my $client = new SelectPdf::PdfMergeClient($apiKey);
    $client->addFile($inputPdf1);
    $client->addFile($inputPdf2);
    $content = $client->saveAsync();

Returns:

- Byte array containing the resulted PDF. An asynchronous call is used.
=cut
sub saveAsync() {
    my($self) = @_;

    $self->{parameters}{"files_no"} = $self->{fileIdx};

    my $JobID = $self->SUPER::startAsyncJobMultipartFormData() or die "An error occurred launching the asynchronous call.";

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

            $self->{fileIdx} = 0;
            $self->{files} = {};

            return $result;
        }

    } while ($noPings <= $self->{AsyncCallsMaxPings});

    $self->{fileIdx} = 0;
    $self->{files} = {};

    die "Asynchronous call did not finish in expected timeframe.";

}

=head2 saveToFileAsync( $filePath )

Merge all specified input pdfs and writes the resulted PDF to a local file. An asynchronous call is used.

    my $client = new SelectPdf::PdfMergeClient($apiKey);
    $client->addFile($inputPdf1);
    $client->addFile($inputPdf2);
    $client->saveToFileAsync($filePath);

Parameters:

- $filePath: Local file including path if necessary.

Returns:

- Byte array containing the resulted PDF.
=cut
sub saveToFileAsync($) {
    my($self, $filePath) = @_;

    my $result = $self->saveAsync();

    my $file = IO::File->new( $filePath, '>' ) or die "Unable to open output file - $!\n";
    $file->binmode;
    $file->print( $result );
    $file->close;
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

=head2 setTimeout( $timeout )

Set the maximum amount of time (in seconds) for this job.
The default value is 30 seconds. 
Use a larger value (up to 120 seconds allowed) for pages that take a long time to load.

Parameters:

- $timeout:  Timeout in seconds.

Returns:

- Reference to the current object.
=cut
sub setTimeout($) {
    my($self, $timeout) = @_;

    $self->{parameters}{"timeout"} = $timeout;
    return $self;
}

1;