#!perl -T

use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

eval "use Test::CheckManifest 0.9";
plan skip_all => "Test::CheckManifest 0.9 required" if $@;

sub read_manifest_skip {
    return [] unless -f q{MANIFEST.SKIP};
    open my $mskip, q{MANIFEST.SKIP}
      or die qq{Error opening MANIFEST.SKIP: $!.\n};
    my @skip = map { chomp; qr{$_} } <$mskip>;
    close $mskip or die qq{Error closing MANIFEST.SKIP: $!.\n};
    return \@skip;
}

ok_manifest( { filter => read_manifest_skip } );
