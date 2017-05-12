#!usr/bin/perl -w

use Pod::Pdf;
pod2pdf(
    '--paper=usletter',
    '--verbose=2',
    '--podfile=podfilename'
);

exit 0;
