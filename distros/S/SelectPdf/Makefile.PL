use 5.020001;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'SelectPdf',
    VERSION_FROM      => 'lib/SelectPdf.pm', 
    PREREQ_PM         => {
				'LWP::UserAgent' => 0,
				'HTTP::Request::Common' => 0,
				'HTTP::Status' => 0,
				'JSON' => 0				
			 }, 
    ABSTRACT          => 'SelectPdf Online REST API Perl Client (HTML to PDF, PDF merge, PDF to text, search PDF)', 
    AUTHOR            => 'SelectPdf <support@selectpdf.com>',
    LICENSE           => 'perl',
    META_ADD => {
        provides => {
            'SelectPdf' => {
                file => 'lib/SelectPdf.pm',
                version => '1.4.0',
            },
            'SelectPdf::ApiClient' => {
                file => 'lib/SelectPdf/ApiClient.pm',
                version => '1.4.0',
            },
            'SelectPdf::AsyncJobClient' => {
                file => 'lib/SelectPdf/AsyncJobClient.pm',
                version => '1.4.0',
            },
            'SelectPdf::HtmlToPdfClient' => {
                file => 'lib/SelectPdf/HtmlToPdfClient.pm',
                version => '1.4.0',
            },
            'SelectPdf::UsageClient' => {
                file => 'lib/SelectPdf/UsageClient.pm',
                version => '1.4.0',
            },
            'SelectPdf::WebElementsClient' => {
                file => 'lib/SelectPdf/WebElementsClient.pm',
                version => '1.4.0',
            },
            'SelectPdf::PdfMergeClient' => {
                file => 'lib/SelectPdf/PdfMergeClient.pm',
                version => '1.4.0',
            },
            'SelectPdf::PdfToTextClient' => {
                file => 'lib/SelectPdf/PdfToTextClient.pm',
                version => '1.4.0',
            },
        },
    }
);
