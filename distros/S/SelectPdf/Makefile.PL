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
    ABSTRACT          => 'SelectPdf Online REST API Perl Client (HTML to PDF, electronic invoices, PDF merge, PDF to text, search PDF)', 
    AUTHOR            => 'SelectPdf <support@selectpdf.com>',
    LICENSE           => 'perl',
    META_ADD => {
        provides => {
            'SelectPdf' => {
                file => 'lib/SelectPdf.pm',
                version => '1.6.0',
            },
            'SelectPdf::ApiClient' => {
                file => 'lib/SelectPdf/ApiClient.pm',
                version => '1.6.0',
            },
            'SelectPdf::ApiEnums' => {
                file => 'lib/SelectPdf/ApiEnums.pm',
                version => '1.6.0',
            },
            'SelectPdf::PageSize' => {
                file => 'lib/SelectPdf/ApiEnums.pm',
            },
            'SelectPdf::PageOrientation' => {
                file => 'lib/SelectPdf/ApiEnums.pm',
            },
            'SelectPdf::RenderingEngine' => {
                file => 'lib/SelectPdf/ApiEnums.pm',
            },
            'SelectPdf::SecureProtocol' => {
                file => 'lib/SelectPdf/ApiEnums.pm',
            },
            'SelectPdf::PageLayout' => {
                file => 'lib/SelectPdf/ApiEnums.pm',
            },
            'SelectPdf::PageMode' => {
                file => 'lib/SelectPdf/ApiEnums.pm',
            },
            'SelectPdf::PageNumbersAlignment' => {
                file => 'lib/SelectPdf/ApiEnums.pm',
            },
            'SelectPdf::StartupMode' => {
                file => 'lib/SelectPdf/ApiEnums.pm',
            },
            'SelectPdf::TextLayout' => {
                file => 'lib/SelectPdf/ApiEnums.pm',
            },
            'SelectPdf::OutputFormat' => {
                file => 'lib/SelectPdf/ApiEnums.pm',
            },
            'SelectPdf::PdfStandard' => {
                file => 'lib/SelectPdf/ApiEnums.pm',
            },
            'SelectPdf::ZugferdProfile' => {
                file => 'lib/SelectPdf/ApiEnums.pm',
            },
            'SelectPdf::ZugferdRelationship' => {
                file => 'lib/SelectPdf/ApiEnums.pm',
            },
            'SelectPdf::ZugferdSchema' => {
                file => 'lib/SelectPdf/ApiEnums.pm',
            },
            'SelectPdf::AsyncJobClient' => {
                file => 'lib/SelectPdf/AsyncJobClient.pm',
                version => '1.6.0',
            },
            'SelectPdf::DemoException' => {
                file => 'lib/SelectPdf/DemoExceptions.pm',
                version => '1.6.0',
            },
            'SelectPdf::DemoRateLimitException' => {
                file => 'lib/SelectPdf/DemoExceptions.pm',
            },
            'SelectPdf::DemoSafetyException' => {
                file => 'lib/SelectPdf/DemoExceptions.pm',
            },
            'SelectPdf::DemoUnsupportedException' => {
                file => 'lib/SelectPdf/DemoExceptions.pm',
            },
            'SelectPdf::HtmlToPdfClient' => {
                file => 'lib/SelectPdf/HtmlToPdfClient.pm',
                version => '1.6.0',
            },
            'SelectPdf::InvoiceClient' => {
                file => 'lib/SelectPdf/InvoiceClient.pm',
                version => '1.6.0',
            },
            'SelectPdf::UsageClient' => {
                file => 'lib/SelectPdf/UsageClient.pm',
                version => '1.6.0',
            },
            'SelectPdf::WebElementsClient' => {
                file => 'lib/SelectPdf/WebElementsClient.pm',
                version => '1.6.0',
            },
            'SelectPdf::PdfMergeClient' => {
                file => 'lib/SelectPdf/PdfMergeClient.pm',
                version => '1.6.0',
            },
            'SelectPdf::PdfToTextClient' => {
                file => 'lib/SelectPdf/PdfToTextClient.pm',
                version => '1.6.0',
            },
        },
    }
);
