package SMOP::Embed;
BEGIN {
  $SMOP::Embed::VERSION = '0.6';
}

use 5.010000;
use strict;
use warnings;


require XSLoader;
XSLoader::load('SMOP::Embed');

1;
