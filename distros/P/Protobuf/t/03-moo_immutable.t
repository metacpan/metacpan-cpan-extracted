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
    'blib'
);

my @moo_modules;
for my $file (@pm_files) {
    next if $file =~ m{lib/TSE/Artifact/Role/};
    my $content = path($file)->slurp_utf8();
    if ($content =~ /use\s+Moo;/ && !($content =~ /use\s+Moo::Role;/)) {
        push @moo_modules, $file;
    }
}

if (!@moo_modules) {
    plan skip_all => 'No Moo modules found to test';
}else{
    plan tests => scalar @moo_modules;
}

for my $file (@moo_modules) {
    my $content = path($file)->slurp_utf8();
    like(
        $content,
        qr/__PACKAGE__->meta->make_immutable;\s+1;/,
        "$file should be made immutable"
    );
}

done_testing();
