use strict;
use warnings;

use Test::More tests =>3;

use Shipwright::Util;
use File::Spec::Functions qw/catfile/;
my $share_root = share_root;
my $builder = catfile( $share_root, 'bin', 'shipwright-builder' );

my $help = `$^X $builder --help`;
like($help, qr/--advanced-help/, 'usage string' );
like($help, qr/--skip-test/,'usage string');
my $advanced_help = `$^X $builder --advanced-help`;
like($advanced_help, qr/--install-base/, "got some advanced help");
