use strict;
use warnings;
use Test::More;
use File::Find;
use Path::Tiny;

my @pm_files;
find(
    sub {
        push @pm_files, $File::Find::name if /\.pm$/ && -f $_;
    },
    'lib'
);

plan tests => scalar @pm_files;

for my $file (@pm_files) {
    my $content = path($file)->slurp_utf8();
    like(
        $content,
        qr/use\s+namespace::autoclean;/,
        "$file should use namespace::autoclean"
    );
}

done_testing();

