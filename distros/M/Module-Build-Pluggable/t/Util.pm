package t::Util;
use strict;
use warnings;
use utf8;

use parent qw(Exporter);

our @EXPORT = qw(spew);

sub spew {
    my ($fname, $content) = @_;
    open my $fh, '>', $fname
        or die "Cannot open '$fname' for writing: $!";
    print {$fh} $content;
}

1;

