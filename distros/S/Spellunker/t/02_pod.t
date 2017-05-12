use strict;
use warnings;
use utf8;
use Test::More;
use Data::Dumper; # for diag
BEGIN { $ENV{PERL_SPELLUNKER_NO_USER_DICT} = 1 }

use Spellunker::Pod;

subtest 'ok' => sub {
    my $sp = Spellunker::Pod->new();
    my @ret = $sp->check_file('t/dat/ok.pod');
    is(0+@ret, 0) or diag Dumper(\@ret);
};

subtest 'fail' => sub {
    my $sp = Spellunker::Pod->new();
    my @ret = $sp->check_file('t/dat/fail.pod');
    is(0+@ret, 3);
    is_deeply( \@ret, [
            [ 3, 'I gah foo', ['gah']],
            [ 6, 'gah!', ['gah']],
            [ 8, 'aaaaaaaaaaaaaaaaaaa', ['aaaaaaaaaaaaaaaaaaa']],
            ] )
        or diag(Dumper(\@ret));
};

done_testing;

