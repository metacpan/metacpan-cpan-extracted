#!/usr/bin/env -S perl -0777 -pi
BEGIN {
    $config = '';
    my $sep = '### Config';
    local $/ = $sep;
    if ( open my $in, '< lib/Reply/Plugin/Prompt.pm' ) {
        <$in>;
        $config = <$in>;
    }
    $config =~ s/^\s*//;
    $config =~ s/(\n###)/```\n$1/g;
    $config =~ s/(### .*\n\n)/$1```perl\n/g;
    $config =~ s/my //g;
    $config =~ s/$sep//;

    $build = '';
    $sep   = '      - ';
    local $/ = $sep;
    if ( open my $in, '< .github/workflows/main.yml' ) {
        while (<$in>) {
            if (/name: Build/) {
                s/$sep//;
                s/.*run: \|//s;
                s/^\s*//gm;
                $build = "```bash\n$_```\n";
            }
        }
    }
}
s/(## Build\n\n)(?:.*)(\n## Configure)/$1$build$2/s;
s/(## Configure\n\n)(?:.*)(### Configuration File)/$1$config$2/s;
