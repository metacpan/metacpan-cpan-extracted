#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 2;

sub _slurp {
    my $filename = shift;

    open my $in, '<:encoding(utf-8)', $filename
      or die "Cannot open '$filename' for slurping - $!";

    local $/;
    my $contents = <$in>;

    close($in);

    return $contents;
}

use File::Spec ();

{
    my $text = _slurp(
        File::Spec->catfile(
            File::Spec->curdir, split m#/#, "lib/Pod/Weaver/PluginBundle/SHLOMIF.pm"
        )
    );

    my $ver;

    ($ver) = $text =~ m#\$[A-Za-z0-9_:]*?VERSION\s*=\s*'([0-9\.]+)'#ms;

    # TEST
    ok( defined($ver), 'VERSION was matched' );

    # TEST
    cmp_ok( $ver, '>', 0.001, 'VERSION is sane - more than the minimal value' );
}
