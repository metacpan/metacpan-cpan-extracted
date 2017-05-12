#!/usr/bin/env perl -w
use strict;
use Test;
BEGIN { plan tests => 4 }

use Pod::MultiLang; ok(1);
use Pod::MultiLang::Dict; ok(1);
use Pod::MultiLang::Dict::ja; ok(1);
use Pod::MultiLang::Html; ok(1);

exit;
__END__
