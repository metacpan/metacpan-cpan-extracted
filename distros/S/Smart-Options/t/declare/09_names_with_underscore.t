use strict;
use warnings;
use Smart::Options::Declare;
use Test::More;
use Test::Exception;

@ARGV = qw(--p-foo=3);
is foo(), 3;

@ARGV = qw(--p_foo=3);
is foo(), 3;


@ARGV = qw(--p-foo=3);
is with_alias(), 3;

@ARGV = qw(--p_foo=3);
is with_alias(), 3;

@ARGV = qw(--bar=3);
is with_alias(), 3;

done_testing;
exit;

sub foo {
    opts my $p_foo => { isa => 'Int' };
    return $p_foo;
}

sub with_alias {
    opts my $p_foo => { isa => 'Int', alias => 'bar' };
    return $p_foo;
}
