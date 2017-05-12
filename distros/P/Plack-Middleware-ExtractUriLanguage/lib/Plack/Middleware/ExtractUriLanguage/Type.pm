#
# This file is part of Plack-Middleware-ExtractUriLanguage
#
# This software is Copyright (c) 2013 by BURNERSK.
#
# This is free software, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#
package Plack::Middleware::ExtractUriLanguage::Type;
use strict;
use warnings FATAL => 'all';
use utf8;

use base 'Exporter';

BEGIN {
  our @EXPORT_OK = qw(
    $PATH_INFO_FIELD
    $DEFAULT_PATH_INFO_ORIG_FIELD
    $DEFAULT_LANGUAGE_TAG_FIELD
  );
  our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );
}

use Const::Fast 'const';

############################################################################

const our $PATH_INFO_FIELD              => 'PATH_INFO';
const our $DEFAULT_PATH_INFO_ORIG_FIELD => 'extracturilanguage.path_info';
const our $DEFAULT_LANGUAGE_TAG_FIELD   => 'extracturilanguage.language';

############################################################################
1;
