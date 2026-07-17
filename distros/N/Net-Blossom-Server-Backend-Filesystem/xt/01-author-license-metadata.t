use strictures 2;

use FindBin;
use Test::More;

plan skip_all => 'AUTHOR_TESTING is not set'
    unless $ENV{AUTHOR_TESTING};

open my $fh, '<', "$FindBin::Bin/../Makefile.PL"
    or die "Unable to read Makefile.PL: $!";
my $makefile = do { local $/; <$fh> };

like(
    $makefile,
    qr/LICENSE\s*=>\s*'gpl_3'/,
    'Makefile.PL declares GPL-3 license metadata',
);

my $license = "$FindBin::Bin/../LICENSE";
ok(-f $license, 'LICENSE ships with the distribution');
if (-f $license) {
    open my $license_fh, '<', $license
        or die "Unable to read LICENSE: $!";
    my $license_text = do { local $/; <$license_fh> };

    like($license_text, qr/GNU GENERAL PUBLIC LICENSE/, 'LICENSE contains GPL text');
    like($license_text, qr/Version 3, 29 June 2007/, 'LICENSE contains GPL version 3 text');
}

open my $manifest_fh, '<', "$FindBin::Bin/../MANIFEST"
    or die "Unable to read MANIFEST: $!";
my $manifest = do { local $/; <$manifest_fh> };
like($manifest, qr/^LICENSE$/m, 'MANIFEST includes LICENSE');

done_testing;
