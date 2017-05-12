#! /usr/bin/env perl

use strict;
use warnings;

use Test::More ();

BEGIN {
    # Ensure XML::LibXML doesn't load; force the XML::XPath implementation.
    unshift @INC, sub {
            die if $_[1] eq "XML/LibXML.pm";
            undef;
    };

    eval { require XML::XPath; 1 }
        or 
    import Test::More skip_all => "XML::XPath not available";
}

use File::Basename qw( dirname );
do(dirname($0)."/tagselect.pl");
