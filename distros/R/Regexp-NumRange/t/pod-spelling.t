#!perl

use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    my $msg = 'Author test.  Set $ENV{RELEASE_TESTING} to a true value to run.';
    plan( skip_all => $msg );
}

eval "use Test::Spelling";
exit if $@;
add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__END__
Rideout
CPAN
AnnoCPAN
github
