use strict;
use warnings;

package PCNTest;
use Path::Tiny;
use File::Temp;

use Exporter;
our @ISA    = qw/Exporter/;
our @EXPORT = qw/make_tree unixify/;

sub make_tree {
    my $td = File::Temp->newdir;
    for (@_) {
        if (/\/$/) {
            path( $td, $_ )->mkpath;
        }
        else {
            my $item = path( $td, $_ );
            $item->parent->mkpath;
            $item->touch;
        }
    }
    return $td;
}

sub unixify {
    my ( $arg, $td ) = @_;
    my $pc = path($arg);
    return $pc->relative($td)->stringify;
}

1;

