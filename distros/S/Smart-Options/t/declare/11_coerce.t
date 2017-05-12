use strict;
use warnings;
use Smart::Options::Declare;
use Test::More;
use Test::Exception;

opts_coerce 'Upper' => 'Str', sub { uc($_[0]) };

@ARGV = ('--foo=a,b,c');
is_deeply foo(), [qw/a b c/];

@ARGV = ('--foo=a,b,c', '--foo=d');
is_deeply foo(), [qw/a b c d/];

@ARGV = qw(--bar=hoge);
is bar(), 'HOGE';

done_testing;

sub foo {
    opts my $foo => 'Multiple';

    return $foo;
}

sub bar {
    opts my $bar => 'Upper';

    return $bar;
}
