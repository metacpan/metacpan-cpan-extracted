package t::Util;

use strict;
use warnings;

use base qw(Exporter);
our @EXPORT = qw(p);

use IO::File;
use File::Temp qw(tempfile);
use Data::Dumper;

sub p(@) { ## no critic
    local $Data::Dumper::Indent    = 1;
    local $Data::Dumper::Deepcopy  = 1;
    local $Data::Dumper::Sortkeys  = 1;
    local $Data::Dumper::Terse     = 1;
    local $Data::Dumper::Useqq     = 0;
    local $Data::Dumper::Quotekeys = 0;
    my $d =  Dumper(\@_);
    $d =~ s/\\x\{([0-9a-z]+)\}/chr(hex($1))/ge;
    print STDERR $d;
}

sub create_tempfile {
    my %p = @_;
    my($fh, $filename) = tempfile(UNLINK => 1);
    $fh->autoflush(1);

    if ($p{size} && $p{size} > 0) {
        print {$fh} "X"x$p{size};
        seek $fh, 0, SEEK_SET;
        my $buf = do { local $/; <$fh> };
    }

    return ($fh, $filename);
}

1;

__END__

# for Emacsen
# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# cperl-close-paren-offset: -4
# cperl-indent-parens-as-block: t
# indent-tabs-mode: nil
# coding: utf-8
# End:

# vi: set ts=4 sw=4 sts=0 et ft=perl fenc=utf-8 :
