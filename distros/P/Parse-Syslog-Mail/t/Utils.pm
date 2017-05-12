use strict;
use File::Basename;
use File::Spec::Functions;

sub my_glob {
    my @files;

    for my $spec (@_) {
        my ($expr, $path) = fileparse($spec, "");
        $expr =~ s/(?:^|[^.])\*/.*/g;
        opendir(DIR, $path) or next;
        push @files, map { catfile($path, $_) } grep { /^$expr$/ } readdir(DIR);
        closedir(DIR);
    }

    return @files
}

1
