package t::Util;

use strict;
use warnings;
use utf8;

use File::Basename qw/dirname/;
use lib dirname(__FILE__).'/../lib';

use Exporter 'import';

use Test::More;
use Test::Deep;
use Test::Deep::Matcher;
use Test::Exception;

our @EXPORT = (
    @Test::More::EXPORT,
    @Test::Deep::EXPORT,
    @Test::Deep::Matcher::EXPORT,
    @Test::Exception::EXPORT,
);

1;
