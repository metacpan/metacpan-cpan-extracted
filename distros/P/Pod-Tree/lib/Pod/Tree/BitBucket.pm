package Pod::Tree::BitBucket;
use strict;
use warnings;

our $VERSION = '1.25';

sub new { bless {}, shift }
sub AUTOLOAD {shift}

1;

