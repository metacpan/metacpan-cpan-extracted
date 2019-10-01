#!perl
use 5.006;

use strict;
use warnings;

use Test::More;
plan tests => 1;

use Test::Pod::Spelling;
add_stopwords(
    qw(modulino argv init negatable perldoc AnnoCPAN CPAN licensable));

all_pod_files_spelling_ok();

exit;
__END__
