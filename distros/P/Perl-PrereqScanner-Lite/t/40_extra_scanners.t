use strict;
use warnings;
use utf8;
use Perl::PrereqScanner::Lite;

use Test::More;

subtest 'extra_scanners which is constructor option must be array reference' => sub {
    eval {
        Perl::PrereqScanner::Lite->new({
            extra_scanners => "+Perl::PrereqScanner::Lite::Scanner::Moose",
        });
    };
    like $@, qr/\A'extra_scanners' option must be array reference/;
};

done_testing;

