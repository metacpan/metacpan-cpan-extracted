#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib 'lib';
use MzML::Parser;

plan tests => 5;

my $p = MzML::Parser->new();
my $res = $p->parse("t/miape_sample.mzML");

cmp_ok( $res->run->spectrumList->spectrum->[47]->precursorList->precursor->[0]->spectrumRef, 'eq', "controllerType=0 controllerNumber=1 scan=43", "precursor spectrumRef" );

cmp_ok( $res->run->spectrumList->spectrum->[47]->precursorList->precursor->[0]->selectedIonList->selectedIon->[0]->cvParam->[0]->value, 'eq', "882.53999999999996", "selectedionlist cvparam value" );

cmp_ok( $res->run->spectrumList->spectrum->[47]->binaryDataArrayList->binaryDataArray->[0]->encodedLength, '==', "3048", "binary encoded length" );

cmp_ok ( $res->run->chromatogramList->chromatogram->[0]->binaryDataArrayList->binaryDataArray->[0]->encodedLength, '==', '272', "chromatogram encoded length");

cmp_ok ( $res->run->chromatogramList->chromatogram->[0]->binaryDataArrayList->binaryDataArray->[0]->binary, 'eq', "eJwBwAA//8i1oTsFYQE8Gs03PHUXuzyEDQ89xCVHPVKjfT13oZk9fU+fPe9Npj0aRL49IaPWPWsO8D1mJAU+/uQSPhHsFT5gWRk+91AlPuiHMT5dIz8+/YJNPi/NWj7X8l0+51phPnSDbj5vnno+JrKEPoeaiz7fKpI+e+qTPgF/mz7gnKE+pjSoPo6Srz71lLc+Ig25PivBuj7gzsA+MQDHPuvNzT4jjNQ+K2LbPjvP3T6rhd8+M4rlPi3P6z6aOvI+Fnf5PuVxVHM=", "chromatogram binary" ); 
