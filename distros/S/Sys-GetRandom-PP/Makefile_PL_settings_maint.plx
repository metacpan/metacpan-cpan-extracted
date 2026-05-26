use strict;
use warnings;

sub {
    my ($opt) = @_;

    $opt->{dist}{COMPRESS} = q{sh -c '7z a -tgzip -mx=9 -mfb=258 -mpass=15 -sdel -bso0 -bsp0 -- "$$1.gz" "$$1"' 7z-gzip};
}
