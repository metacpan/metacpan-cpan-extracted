#!perl -T

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Ref::List qw(list);

# dereferncing undef
my $undef;
my @undefref = list $undef;
is ($undefref[0], undef, 'dereferencing undef');

# dereferncing an array
my $arrayref = [ qw(foo bar baz) ];
my @arrayref = list $arrayref;
is($arrayref[0], 'foo', 'dereferncing an array');

# dereferncing a hash
my $hashref = { color => 'green', side => 'other' };
my %hashref = list $hashref;
is($hashref{color}, 'green', 'dereferncing a hash');

# dereferencing an invalid argument
my $subref = sub { return };
dies_ok { list $subref } 'dereferencing an invalid argument';

done_testing();
