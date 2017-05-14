use strict;
use warnings;
use Test::More tests => 6;
use Ref::Util qw<is_arrayref is_hashref>;

my $array_func = \&is_arrayref;
my $hash_func = \&is_hashref;

is(prototype($array_func), '$', 'is_arrayref has "$" prototype');
is(prototype($hash_func), '$', 'is_hashref has "$" prototype');

# We have to use string eval for this, because when the custom op is being
# used, we expect the direct calls to fail at compile time
my @cases = (
    [is_arrayref => 'is_arrayref([], 17)',
     'direct array call with too many arguments'],
    [is_arrayref => '$array_func->([], 17)',
     'array call through coderef with too many arguments'],
    [is_hashref => 'is_hashref([], 17)',
     'direct hash call with too many arguments'],
    [is_hashref => '$hash_func->([], 17)',
     'hash call through coderef with too many arguments'],
);

for my $case (@cases) {
    my ($name, $code, $desc) = @$case;
    scalar eval $code;
    my $exn = $@;
    my @all_names =
        ($name, map "$_\::$name", qw<Ref::Util Ref::Util::PP Ref::Util::XS>);
    my $rx = join '|', (
        (map "Too many arguments for $_\\b", @all_names),
        (map "Usage: $_\\(ref\\)", @all_names),
    );
    like($exn, qr/^(?:$rx)/, $desc);
}
