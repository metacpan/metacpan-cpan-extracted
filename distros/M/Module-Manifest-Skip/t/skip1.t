use strict;
use lib -e 't' ? 't' : 'test';
use TestModuleManifestSkip;

use Test::More tests => 1;
# use XXX; use Test::Differences; *is = \&eq_or_diff;

use Module::Manifest::Skip;

my $mms = Module::Manifest::Skip->new;

is $mms->text, $TEMPLATE,
    'Default MANIFEST.SKIP text is ok';
