use strict;
use warnings;
use Test::More 0.88;
use Path::Tiny;
use File::Temp;
use File::pushd qw/tempd/;
use MooseX::Types::Path::Tiny qw/Paths AbsPaths/;

{
    my %tests = (
        "path('foo')"       => path('foo'),
        'foo'               => 'foo',
        "[ path('foo') ]"   => [ path('foo') ],
        "[ 'foo' ]"         => [ 'foo' ],
    );

    foreach my $test (keys %tests)
    {
        ok(is_Paths(to_Paths($tests{$test})), 'can coerce ' . $test . ' to Paths');
    }
}

{
    my $wd = tempd;
    my $tf = File::Temp->new;

    my %tests = (
        'path($filename)'       => path($tf),
        '$filename'             => $tf,
        '[ path($filename) ]'   => [ path($tf) ],
        '[ $filename ]'         => [ $tf ],
    );

    foreach my $test (keys %tests)
    {
        ok(is_AbsPaths(to_AbsPaths($tests{$test})), 'can coerce ' . $test . ' to AbsPaths');
    }
}

done_testing;
