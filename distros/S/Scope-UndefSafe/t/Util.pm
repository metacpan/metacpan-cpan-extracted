package t::Util;

use strict;
use warnings FATAL => 'all';
use utf8;

use File::Basename qw/dirname/;
use lib dirname(__FILE__).'/../lib';

use Exporter qw/import/;

use Test::More;

our @EXPORT = (
    @Test::More::EXPORT,
);

1;
