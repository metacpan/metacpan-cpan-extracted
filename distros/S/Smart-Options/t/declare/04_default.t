use strict;
use warnings;
use Smart::Options::Declare;
use Test::More;
use Test::Exception;

is default(),            99;
is default_as_coderef(), 99;

done_testing;

exit;

sub default {
    opts my $p => { isa => 'Int', default => 99 };
    return $p;
}

sub default_as_coderef {
    opts my $x => { isa => 'Int', default => sub { 99 } };
    return $x;
}
