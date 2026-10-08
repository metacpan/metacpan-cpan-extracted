# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl SelectPdf.t'

#########################

# These tests do not call the SelectPdf API (no network access, no API key needed).

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('SelectPdf');
    use_ok('SelectPdf::ApiClient');
    use_ok('SelectPdf::ApiEnums');
    use_ok('SelectPdf::AsyncJobClient');
    use_ok('SelectPdf::DemoExceptions');
    use_ok('SelectPdf::HtmlToPdfClient');
    use_ok('SelectPdf::InvoiceClient');
    use_ok('SelectPdf::PdfMergeClient');
    use_ok('SelectPdf::PdfToTextClient');
    use_ok('SelectPdf::UsageClient');
    use_ok('SelectPdf::WebElementsClient');
};

#########################

is($SelectPdf::VERSION, '1.6.0', 'version');

# constants
is(SelectPdf::PdfStandard::PdfA3A, 'PdfA3A', 'PdfStandard::PdfA3A');
is(SelectPdf::PdfStandard::PdfSiqQ_B, 'PdfSiqQ_B', 'PdfStandard::PdfSiqQ_B');
is(SelectPdf::ZugferdProfile::En16931, 'En16931', 'ZugferdProfile::En16931');
is(SelectPdf::ZugferdProfile::Basic_WL, 'Basic_WL', 'ZugferdProfile::Basic_WL');
is(SelectPdf::ZugferdRelationship::Alternative, 'Alternative', 'ZugferdRelationship::Alternative');
is(SelectPdf::ZugferdSchema::FacturX10, 'FacturX10', 'ZugferdSchema::FacturX10');
is(SelectPdf::RenderingEngine::Chromium, 'Chromium', 'RenderingEngine::Chromium');
is(SelectPdf::PageNumbersAlignment::Center, 2, 'PageNumbersAlignment::Center');

# production / demo mode selection
my $paid = SelectPdf::HtmlToPdfClient->new('not-a-real-key');
is($paid->isDemoMode(), 0, 'API key -> production mode');
is($paid->{apiEndpoint}, 'https://selectpdf.com/api2/convert/', 'API key -> production endpoint');

for my $key (undef, '', 'demo', 'Demo') {
    my $client = SelectPdf::HtmlToPdfClient->new($key);
    ok($client->isDemoMode() && $client->{apiEndpoint} eq 'https://selectpdf.com/api2/convert/demo/' && !exists($client->{parameters}{key}),
        'demo key ' . (defined($key) ? "'$key'" : 'undef') . ' -> keyless demo endpoint');
}

# new parameters
$paid
    ->setTagged(1)
    ->setPdfStandard(SelectPdf::PdfStandard::PdfA3B)
    ->setDocumentLanguage('en-US')
    ->setWebPageFixedSize('true')
    ->setAuthUsername('user')
    ->setAuthPassword('password')
    ->setRenderingEngine('Chromium')
;
is($paid->{parameters}{tagged}, 'True', 'tagged');
is($paid->{parameters}{pdf_standard}, 'PdfA3B', 'pdf_standard');
is($paid->{parameters}{doc_language}, 'en-US', 'doc_language');
is($paid->{parameters}{web_page_fixed_size}, 'True', 'web_page_fixed_size');
is($paid->{parameters}{auth_username}, 'user', 'auth_username');
is($paid->{parameters}{auth_password}, 'password', 'auth_password');
is($paid->{parameters}{engine}, 'Chromium', 'engine');
eval { $paid->setPdfStandard('PdfZ'); };
like("$@", qr/Allowed values for Pdf Standard/, 'setPdfStandard validates');

# demo guards
my $demo = SelectPdf::HtmlToPdfClient->new();
eval { $demo->setUserPassword('x'); };
ok(ref($@) && $@->isa('SelectPdf::DemoUnsupportedException') && $@->field() eq 'user_password', 'demo setUserPassword -> DemoUnsupportedException');
eval { $demo->setOwnerPassword('x'); };
ok(ref($@) && $@->isa('SelectPdf::DemoUnsupportedException') && $@->field() eq 'owner_password', 'demo setOwnerPassword -> DemoUnsupportedException');
eval { $demo->convertHtmlStringAsync('x'); };
ok(ref($@) && $@->isa('SelectPdf::DemoUnsupportedException') && $@->field() eq 'async', 'demo async -> DemoUnsupportedException');
is($demo->isDemoResponse(), 0, 'no response yet -> not a demo response');
is(scalar(@{ $demo->getDroppedFields() }), 0, 'no dropped fields yet');

# invoice client
eval { SelectPdf::InvoiceClient->new('demo'); };
like("$@", qr/An API key is required to create electronic invoices/, 'InvoiceClient needs an API key');
my $invoice = SelectPdf::InvoiceClient->new('not-a-real-key');
isa_ok($invoice, 'SelectPdf::HtmlToPdfClient');
is($invoice->{apiEndpoint}, 'https://selectpdf.com/api2/invoice/', 'invoice endpoint');
is($invoice->{parameters}{pdf_standard}, 'PdfA3A', 'invoice carrier defaults to PdfA3A');
eval { $invoice->createFromHtmlString('<p>x</p>'); };
like("$@", qr/The invoice XML was not specified/, 'invoice requires XML');
$invoice->setInvoiceXml('<xml/>')->setZugferdProfile('En16931')->setZugferdRelationship('Data')->setZugferdSchema('Zugferd20');
is($invoice->{binaryData}{zugferd_xml}, '<xml/>', 'invoice XML from memory');
is($invoice->{parameters}{zugferd_profile}, 'En16931', 'zugferd_profile');
is($invoice->{parameters}{zugferd_relationship}, 'Data', 'zugferd_relationship');
is($invoice->{parameters}{zugferd_schema}, 'Zugferd20', 'zugferd_schema');
$invoice->setInvoiceXmlFile('factur-x.xml');
ok(!exists($invoice->{binaryData}{zugferd_xml}) && $invoice->{files}{zugferd_xml} eq 'factur-x.xml', 'invoice XML from file replaces XML from memory');

# demo error bodies
my $e = SelectPdf::DemoException->fromResponse(429, '{"error":"rate_limited","reason":"per_ip","upgrade":"https://selectpdf.com/pricing/"}', '3600');
ok(ref($e) && $e->isa('SelectPdf::DemoRateLimitException') && $e->reason() eq 'per_ip' && $e->retryAfter() == 3600 && $e->statusCode() == 429, 'rate_limited -> DemoRateLimitException');
$e = SelectPdf::DemoException->fromResponse(400, '{"error":"unsafe_url","field":"url","reason":"private_ip"}', undef);
ok(ref($e) && $e->isa('SelectPdf::DemoSafetyException') && $e->field() eq 'url' && $e->reason() eq 'private_ip', 'unsafe_url -> DemoSafetyException');
$e = SelectPdf::DemoException->fromResponse(400, '{"error":"unsupported_in_demo","field":"user_password","upgrade":"https://selectpdf.com/pricing/"}', undef);
ok(ref($e) && $e->isa('SelectPdf::DemoUnsupportedException') && $e->field() eq 'user_password' && $e->upgradeUrl() eq 'https://selectpdf.com/pricing/', 'unsupported_in_demo -> DemoUnsupportedException');
like("$e", qr/^\(400\) Feature 'user_password' is not available in demo mode/, 'exception stringifies to its message');
$e = SelectPdf::DemoException->fromResponse(413, '{"error":"body_too_large","max_bytes":1048576,"upgrade":"https://selectpdf.com/pricing/"}', undef);
like($e, qr/^\(413\) Demo request body exceeds the demo cap/, 'body_too_large -> error message');
is(SelectPdf::DemoException->fromResponse(500, 'Internal error', undef), undef, 'non-JSON body -> undef');

done_testing();
