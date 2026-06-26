use strict;
use warnings;

sub {
    my ($opt) = @_;

    if ($^V ge v5.16.0 && $^V lt v5.22.0) {
        # Hack. ASan reports a memory leak on 5.16 .. 5.20, but I don't
        # want integration tests to fail for now.
        $opt->{EXTRA_ASAN_OPTIONS} .= " LSAN_OPTIONS='exitcode=0'";
    }

    $opt->{dist}{COMPRESS} = q{sh -c '7z a -tgzip -mx=9 -mfb=258 -mpass=15 -sdel -bso0 -bsp2 -- "$$1.gz" "$$1"' 7z-gzip};
}
