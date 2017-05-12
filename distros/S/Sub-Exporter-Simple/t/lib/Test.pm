use strict;
use warnings;

package Test;

use lib '../../lib';

use Sub::Exporter::Simple qw( test test2 );

sub test { 'test' }

sub test2 { 'test2' }

1;
