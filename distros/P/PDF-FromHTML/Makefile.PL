#!/usr/local/bin/perl

use inc::Module::Install;

name		'PDF-FromHTML';
license         'unrestricted';
all_from        'lib/PDF/FromHTML.pm';
install_script  'script/html2pdf.pl';

requires qw(
    List::Util              0
    XML::Twig               0
    Graphics::ColorNames    0
    LWP::Simple             0
    Image::Size             0
    PDF::Writer             0.05
);

unless (can_use('PDF::API2') or can_use('pdflib_pl')) {
    if ($] >= 5.008) {
        requires 'PDF::API2';
        print << '.';
*** If you cannot install PDF::API2, you may use the pdflib_pl
    module instead, available as a separate download on PDFLib homepage.
.
    }
    else {
        requires 'pdflib_pl';
        print << '.';
*** Perl 5.6.x users needs the pdflib_pl module, available as a
    separate download on PDFLib homepage.  Alternatively, upgrade
    to Perl 5.8 and use PDF::API2 from CPAN.
.
    }
}

unless (can_use('HTML::Tidy') or can_use('XML::Clean')) {
    requires 'HTML::Tidy';
    print << '.';
*** If you cannot install HTML::Tidy, you may use the XML::Clean
    module instead; however, you will run probably run into more
    "XML not well-formed" errors that way.
.
}

auto_install;
auto_provides;
sign; WriteAll;
