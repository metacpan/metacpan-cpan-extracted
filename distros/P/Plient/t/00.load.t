use Test::More;
use File::Spec::Functions qw/catfile catdir/;
use File::Basename qw( dirname );

use File::Find;
my @pms;

find(
    sub {
        return unless -f && /\.pm$/;
        my $name = $File::Find::name;
        $name =~ s!.*lib[/\\]!!;
        $name =~ s![/\\]!::!g;
        $name =~ s/\.pm$//;
        push @pms, $name;
    },
    'lib'
);

plan tests => scalar @pms;
for my $pm (@pms) {
    use_ok($pm);
}
