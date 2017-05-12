use Test::More;
use File::Spec::Functions qw/catfile catdir/;
use File::Basename qw( dirname );

my $manifest = catdir( dirname(__FILE__), '..', 'MANIFEST' );
plan skip_all => 'MANIFEST does not exist' unless -e $manifest;
open FH, '<', $manifest;

my @pms = map { s|^lib/||; chomp; $_ } grep { m|^lib/.*pm$| } <FH>;

plan tests => scalar @pms;
for my $pm (@pms) {
    $pm =~ s|\.pm$||;
    $pm =~ s|/|::|g;

    use_ok($pm);
}
