use strict;
use warnings;

use Test::More tests => 3;

use_ok('Pistachio::Supported', qw(supported_languages supported_styles));

my @langs = &supported_languages;
ok("@langs" eq 'Perl5', "Pistachio::Supported::supported_languages()");

my @styles = &supported_styles;
ok("@styles" eq 'Github', "Pistachio::Supported::supported_styles()");

done_testing;
