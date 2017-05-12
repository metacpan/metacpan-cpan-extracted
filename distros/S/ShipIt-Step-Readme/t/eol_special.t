use strict;
use Test::More;

BEGIN {
    unless ( $ENV{RELEASE_TESTING} ) {
        plan( skip_all => "Author tests not required for installation" );
    }

    eval "use Test::EOL";
    plan skip_all => 'Test::EOL required for testing EOL' if $@;
}

for my $filename (qw~Changes MANIFEST MANIFEST.SKIP META.yml README TODO~) {
    unless (-f $filename) {
        diag "$filename does not exist";
        next;
    }
    eol_unix_ok     $filename,  "$filename is ok";
}


done_testing;
