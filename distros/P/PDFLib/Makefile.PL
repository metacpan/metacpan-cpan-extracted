# $Id: Makefile.PL,v 1.3 2001/06/04 13:38:11 matt Exp $

use ExtUtils::MakeMaker;

eval {
    require pdflib_pl;
    die unless $pdflib_pl::VERSION >= 4.0;
};
if ($@) {
    die <<DEATH;

PDFLib requires the pdflib package from http://www.pdflib.com/ version
4.0 or higher to be installed, and the perl interface "pdflib_pl.pm"
enabled to be able to work properly. Please install that before trying
to install this module.

DEATH
}

WriteMakefile(
    'NAME'	=> 'PDFLib',
    'VERSION_FROM' => 'PDFLib.pm', # finds $VERSION
    'PREREQ_PM' => { pdflib_pl => 4.0 },
);
