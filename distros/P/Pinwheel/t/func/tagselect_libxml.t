#! /usr/bin/env perl

use strict;
use warnings;

use Test::More ();

BEGIN {
    # Ensure XML::XPath doesn't load; force the XML::LibXML implementation.
    unshift @INC, sub {
            die if $_[1] eq "XML/XPath.pm";
            undef;
    };

    eval 'use XML::LibXML 1.61; 1'
        or 
    import Test::More skip_all => "XML::LibXML >= 1.61 not available";
}

use File::Basename qw( dirname );
do(dirname($0)."/tagselect.pl");
