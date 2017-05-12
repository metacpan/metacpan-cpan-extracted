# perl -T
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl POOF.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;

eval "use POOF::Example::SyntaxError;";
#warn $@;
ok
(
    #Bareword "asdf" not allowed while "strict subs" in use at  [C:/Perl/site/lib/POOF/Example/SyntaxError.pm] line 29.
    ($@ =~ /Bareword "asdf"/ && $@ =~ m!/Example/SyntaxError\.pm\] line 29\.!)
        ? 1
        : 0
    , 'Handling of diagnostic information during a die'
);

exit;

