#!/usr/bin/perl
# $Id: 00-basic.t 4092 2009-02-24 17:46:48Z andrew $

use Test::More tests => 4;

BEGIN {
    use_ok( 'Pod::POM' );
    use_ok( 'Pod::POM::View::Text' );
    use_ok( 'Pod::POM::View::HTML' );
    use_ok( 'Pod::POM::View::Pod' );
}
