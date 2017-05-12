#!usr/bin/perl -w

use Pod::Pdf;
pod2pdf(
    '--paper=usletter',
    'podfilename'
);

exit 0;
