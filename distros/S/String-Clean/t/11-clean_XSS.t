#!/usr/bin/perl;
use strict;
use warnings;

use Test::More qw{no_plan};
use String::Clean::XSS;

my $string = '<script>bad stuff</script>';

is( 
   convert_XSS($string),
   '&lt;script&gt;bad stuff&lt;/script&gt;',
   q{convert},
);

is(
   $string,
   '<script>bad stuff</script>',
   q{test string is not modified},
);

is(
   clean_XSS($string),
   'scriptbad stuff/script',
   q{clean},
);

is(
   $string,
   '<script>bad stuff</script>',
   q{test string is still not modified},
);

is (
   clean_XSS('just normal text'),
   q{just normal text},
   q{properly ignores normal stuff},
);

