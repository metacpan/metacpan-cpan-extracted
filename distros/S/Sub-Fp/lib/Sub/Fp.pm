package Sub::Fp;
use strict;
use warnings;
use Carp;
use POSIX;
use List::Util;
use Data::Dumper qw(Dumper);
use Exporter qw(import);
our @EXPORT_OK = qw(
    incr        reduces  flatten
    drop_right  drop     take_right  take
    assoc       maps     decr        chain
    first       end      subarray    partial
    __          find     filter      some
    none        uniq     bool        spread
    len         to_keys  to_vals     is_array
    is_hash     every    noop        identity
    is_empty    is_sub   flow        eql
    to_pairs    for_each apply       get
    second      range    pops        pushes
    shifts      unshifts once
);

our $VERSION = '0.32';

use constant ARG_PLACE_HOLDER => {};

# -----------------------------------------------------------------------------#

sub __ { ARG_PLACE_HOLDER };

sub noop { return undef }

sub identity {
    my $args = shift // undef;

    return $args;
}

sub once {
    my $func            = shift // \&noop;
    my $was_called_once = 0;
    my $result;

    return sub {
        if ($was_called_once) {
            return $result;
        }

        $was_called_once++;
        $result = $func->(@_);
        return $result;
    }
}

# Forgive me below father, for I have sinned.
# Seriously, I can't figure a simpler way to do this...
# TODO: Please refactor this eventually...
sub range {
    my ($start, $end, $step) = @_;

    if (!defined $start) {
        return [];
    }

    if (!defined $end) {
        return range(0, $start, $start < 0 ? -1 : 1);
    }

    if (!defined $step) {
        return range($start, $end, $end < 0 ? -1 : 1);
    }

    if (_is_nonsense_range($start, $end, $step)) {
        return [];
    }

    my $loop_count = ceil(abs(($end - $start) / ($step || 1)));
    my $list       = [];

    while ($loop_count) {
        push(@{ $list }, $start);

        $start+=$step;
        $loop_count-=1;
    }

    return $list;
}

sub _is_nonsense_range {
    my ($start, $end, $step) = @_;

    if ($start == $end &&
        $end == $step) {
        return 1;
    }

    if ($start > $end &&
        $step >= 0 ) {
        return 1;
    }

    if ($start < $end &&
        $step < 0) {
        return 1;
    }
}

sub get {
    my $coll    = shift // [];
    my $key     = shift // 0;
    my $default = shift;

    if (is_array($coll)) {
        return defined $coll->[$key] ? $coll->[$key] : $default;
    }

    if (is_hash($coll)) {
        return defined $coll->{$key} ? $coll->{$key} : $default;
    }

    my $string_coll = [spread($coll)];

    return defined $string_coll->[$key] ? $string_coll->[$key] : $default;
}

sub apply {
    my $fn   = shift // sub {};
    my $args = shift // [];

    return $fn->(@{$args});
}

sub flow {
    my $funcs = [@_];

    if (ref $funcs->[0] ne 'CODE') {
        return \&noop;
    }

    return sub {
        my $args = [@_];

        return chain(
            sub { first($funcs)->(spread($args)) },
            spread(drop($funcs)),
        );
    }
}

sub is_sub {
    my $sub = shift;

    return bool(eql(ref $sub, 'CODE'));
}

sub is_array {
    my $coll       = shift;
    my $extra_args = [@_];

    if (len($extra_args)) {
        return 0;
    }

    return bool(ref $coll eq 'ARRAY');
}

sub is_hash {
    my $coll = shift;

    return bool(ref $coll eq 'HASH');
}

sub to_pairs {
    my $coll = shift // [];

    if (is_array($coll)) {
        return maps(sub {
            my ($val, $idx) = @_;
            return [$idx, $val]
        }, $coll)
    }

    if (is_hash($coll)) {
        return maps(sub {
            my $key = shift;
            return [$key, $coll->{$key}]
        }, to_keys($coll))
    }

    return maps(sub {
        my ($char, $idx) = @_;
        return [$idx, $char];
    }, to_vals($coll));
}

sub to_vals {
    my $coll = shift // [];

    if (is_array($coll)) {
        return $coll;
    }

    if (is_hash($coll)) {
        return [values %{ $coll }];
    }

    return [spread($coll)];
}

sub to_keys {
    my $coll = shift // [];

    #Backwards compatibility < v5.12
    if (is_array($coll)) {
        return maps(sub {
            my (undef, $idx) = @_;
            return $idx;
        }, $coll);
    }

    if (is_hash($coll)) {
        return [keys %{ $coll }];
    }

    return maps(sub {
        my (undef, $idx) = @_;
        return $idx;
    }, [spread($coll)])
}

sub len {
    my $coll = shift || [];

    if (ref $coll eq 'ARRAY') {
        return scalar spread($coll);
    }

    if (ref $coll eq 'HASH') {
        return scalar (keys %{ $coll });
    }

    return length($coll);
}

sub for_each {
    my ($fn, $coll) = @_;
    my $idx = 0;

    foreach my $val (@{ $coll }) {
        $idx++;
        $fn->($val, $idx - 1, $coll);
    }
}

sub is_empty {
    my $coll = shift;
    return bool(len($coll) == 0);
}

sub uniq {
    my $coll = shift;

    my @vals = do {
        my %seen;
        grep { !$seen{$_}++ } @$coll;
    };

    return [@vals];
}

sub find {
    my $pred = shift;
    my $coll = shift // [];

    return List::Util::first {
        $pred->($_)
    } @$coll;
}

sub filter {
    my $pred  = shift;
    my $coll = shift // [];

    return [grep { $pred->($_) } @$coll];
}

sub some {
    my $pred = shift;
    my $coll = shift // [];

    return bool(find($pred, $coll));
}

sub every {
    my $pred = shift;
    my $coll = shift // [];

    my $bool = List::Util::all {
        $pred->($_);
    } @$coll;

    return bool($bool);
}

sub none {
    my $pred = shift;
    my $coll = shift // [];

    return some($pred, $coll) ? 0 : 1;
}

sub incr {
    my $num = shift;
    return $num + 1;
}

sub decr {
    my $num = shift;
    return $num - 1;
}

sub first {
    my $coll = shift;
    return @$coll[0];
}

sub second {
    my $coll = shift;
    return @$coll[1];
}

sub end {
    my $coll = shift // [];
    my $len = scalar @$coll;

    return @$coll[$len - 1 ];
}

sub flatten {
    my $coll = shift;

    return [
        map {
            ref $_ ? @{$_} : $_;
        } @$coll
    ];
}

sub pops {
    my ($array, $val) = @_;

    return pop @{$array};
}

sub pushes {
    my ($array, $val) = @_;

    return push @{$array}, $val;
}

sub shifts {
    my ($array, $val) = @_;

    return shift @{$array};
}

sub unshifts {
    my ($array, $val) = @_;

    return unshift @{$array}, $val;
}

sub _prepare_args {
    my $args     = [@_];
    my $count    = len($args) > 1 ? $args->[0] : 1;
    my $coll     = len($args) > 1 ? $args->[1] : $args->[0];
    my $coll_len = len($coll);

    return ($coll, $count, $coll_len)
}

sub drop {
    my ($coll, $count, $coll_len) = _prepare_args(@_);

    return [@$coll[$count .. $coll_len - 1]];
}

sub drop_right {
    my ($coll, $count, $coll_len) = _prepare_args(@_);

    return [@$coll[0 .. ($coll_len - ($count + 1))]];
}

sub take {
    my ($coll, $count, $coll_len) = _prepare_args(@_);

    if (!$coll_len) {
        return [];
    }

    if ($count >= $coll_len ) {
        return $coll;
    }

    return [@$coll[0 .. $count - 1]];
}

sub take_right {
    my ($coll, $count, $coll_len) = _prepare_args(@_);

    if (!$coll_len) {
        return [];
    }

    if ($count >= $coll_len ) {
        return $coll;
    }

    return [@$coll[($coll_len - $count) .. ($coll_len - 1)]];
}

sub assoc {
    my ($obj, $key, $item) = @_;

    if (!defined $key) {
        return $obj;
    }

    if (ref $obj eq 'ARRAY') {
        return [
            @{(take($key, $obj))},
            $item,
            @{(drop($key + 1, $obj))},
        ];
    }

    return {
        %{ $obj },
        $key => $item,
    };
}

sub maps {
    my $func = shift;
    my $coll = shift;

    my $idx = 0;

    my @vals = map {
      $idx++;
      $func->($_, $idx - 1, $coll);
    } @$coll;

    return [@vals];
}

sub reduces {
    my $func           = shift;
    my ($accum, $coll) = spread(_get_reduces_args([@_]));

    my $idx = 0;

    return List::Util::reduce {
        my ($accum, $val) = ($a, $b);
        $idx++;
        $func->($accum, $val, $idx - 1, $coll);
    } ($accum, @$coll);
}

sub _get_reduces_args {
    my $args = shift;

    if (eql(len($args), 1)) {
        return chain(
            $args,
            \&flatten,
            sub {
                return [first($_[0]), drop($_[0])]
            }
        )
    }

    return [first($args), flatten(drop($args))];
}

sub partial {
    my $func    = shift;
    my $oldArgs = [@_];

    if (ref $func ne 'CODE') {
        carp("Expected a function as first argument");
    }

    return sub {
        my $newArgs = [@_];
        my $no_placeholder_args = _fill_holders($oldArgs, $newArgs);
        return $func->(@$no_placeholder_args);
    }
}


#Once again, forgive me for I have sinned...
sub _fill_holders {
    my ($old_args, $new_args) = @_;

    my $filled_args  = [];
    my $old_args_len = len($old_args);

    for (my $idx = 0; $idx < $old_args_len; $idx++) {
        my $arg = shift @{ $old_args };

        if (eql($arg, __)) {
            push @{ $filled_args }, (shift @{ $new_args });
        } else {
            push @{ $filled_args }, $arg;
        }

        if ($old_args_len == ($idx + 1)) {
            push @{ $filled_args }, @{ $new_args };
        }
    }

    return $filled_args;
}

sub subarray {
    my $coll  = shift || [];
    my $start = shift;
    my $end   = shift // scalar @$coll;

    if (!$start) {
        return $coll;
    }

    if ($start == $end) {
        return [];
    }

    return [
       @$coll[$start .. ($end - 1)],
    ];
}

sub chain {
    no warnings 'once';
    my ($val, @funcs) = @_;

    return List::Util::reduce {
        my ($accum, $func) = ($a, $b);
        $func->($accum);
    } (ref($val) eq 'CODE' ? $val->() : $val), @funcs;
}

sub eql {
    my $arg1 = shift // '';
    my $arg2 = shift // '';

    if (ref $arg1 ne ref $arg2) {
        return 0;
    }

    if (is_array($arg1) && is_array($arg2) ||
        is_hash($arg1) && is_hash($arg2)) {
        return bool($arg1 == $arg2);
    }

    return bool($arg1 eq $arg2);
}

sub bool {
    my ($val) = @_;

    return $val ? 1 : 0;
}

sub spread {
    my $coll = shift // [];

    if (ref $coll eq 'ARRAY') {
        return @{ $coll };
    }

    if (ref $coll eq 'HASH') {
        return %{ $coll }
    }

    return split('', $coll);
}

=head1 NAME

Sub::Fp - A Clojure / Python Toolz / Lodash inspired Functional Utility Library

=cut

=head1 SYNOPSIS

This library provides numerous functional programming utility methods,
as well as functional varients of native in-built methods, to allow for consistent,
concise code.

=head1 SUBROUTINES/METHODS

=head1 EXPORT

    incr         reduces   flatten
    drop_right  drop      take_right  take
    assoc       maps      decr        chain
    first       end       subarray    partial
    __          find      filter      some
    none        uniq      bool        spread   every
    len         is_array  is_hash     to_keys  to_vals
    noop        identity  is_empty    flow     eql
    is_sub      to_pairs  for_each    apply
    get         second

=cut

=head2 incr

Increments the supplied number by 1

    incr(1)

    # => 2

=cut

=head2 decr

Decrements the supplied number by 1

    decr(2)

    # => 1

=cut

=head2 once

Creates a function that is restricted to invoking func once.
Repeat calls to the function return the value of the first invocation.

    my $times_called = 0;
    my $sub          = once(sub {
        $times_called++;
        return "I was only called $times_called time"
    });

    $sub->(); # "I was only called 1 time"
    $sub->(); # "I was only called 1 time"
    $sub->(); # etc

=cut

=head2 apply

Calls the supplied function with the array of arguments, spreading the
arguments into the function it invokes

    my $sum_all_nums = sub {
        my $num        = shift;
        my $second_num = shift;

        return $num + $second_num;
    };

    apply($sum_all_nums, [100, 200]);
    # same as $sum_all_nums->(100, 200)

    # => 300

=cut

=head2 range

Creates an array of numbers (positive and/or negative) progressing from start up to, but not including, end.
A step of -1 is used if a negative start is specified without an end or step.
If end is not specified, it's set to start with start then set to 0.

    range(10);

    # [1,2,3,4,5,6,7,8,9]


    range(1,10);

    # [1,2,3,4,5,6,7,8,9]

    range(-1, -10);

    # [-1, -2, -3, -4, -5, -6 ,-7, -8, -9]

    range(1, 4, 0);

    # [1, 1, 1]


    #Ranges that "dont make sense" will return empty arrays

    range(-1, -4, 0);

    # []

    range(100, 1, 0)

    # []

    range(0,0,0)

    # []

    range(0, -100, 100)

    # []

    range(0, 100, -100)

    # []

    #etc...

=cut

=head2 for_each

Iterates over elements of collection and invokes iteratee for each element. The iteratee is invoked with three arguments: (value, index|key, collection).


    for_each(sub {
       my $num = shift;
       print $num;
    }, [1,2,3]);


    for_each(sub {
       my ($num, $idx, $coll) = @_;
       print $idx;
    }, [1,2,3])

    # 0 1 2

    for_each(sub {
       my ($num, $idx, $coll) = @_;
       print Dumper $coll;
    }, [1,2,3])

    #   [1,2,3],
    #   [1,2,3],
    #   [1,2,3]

=cut

=head2 maps

Creates an array of values by running each element in collection thru iteratee.
The iteratee is invoked with three arguments:
(value, index|key, collection).

    maps(sub {
        my $num = shift;
        return $num + 1;
    }, [1,1,1]);

    # [2,2,2]

=cut

=head2 reduces

Reduces collection to a value which is the accumulated result of running each element in collection thru iteratee,
where each successive invocation is supplied the return value of the previous.
If accumulator is not given, the first element of collection is used as the initial value.
The iteratee is invoked with four arguments:
(accumulator, value, index|key, collection).

    # Implicit Accumulator

    reduces(sub {
        my ($sum, $num) = @_;

        return $sum + $num;
    }, [1,1,1]);

    # 3


    # Explict Accumulator

    reduces(sub {
        my ($accum, $num) = @_;
        return {
            spread($accum),
            key => $num,
        }
    }, {}, [1,2,3]);

    # {
    #    key => 1,
    #    key => 2,
    #    key => 3,
    # }
=cut

=head2 flatten

Flattens array a single level deep.

    flatten([1,1,1, [2,2,2]]);

    # [1,1,1,2,2,2];

=cut

=head2 pop / pushes / shifts / unshifts

Works the same as builtin pop / push etc etc, with mutations,
except it uses references instead of @ lists.

    my $array = [1,2,3];

    pops($array)

    # 3

    my $array = [1,2,3];

    pushes($array, 4);

    # [1,2,3,4]

=cut

=head2 drop

Creates a slice of array with n elements dropped from the beginning.

    drop([1,2,3])

    # [2,3];

    drop(2, [1,2,3])

    # [3]

    drop(5, [1,2,3])

    # []

    drop(0, [1,2,3])

    # [1,2,3]
=cut



=head2 drop_right

Creates a slice of array with n elements dropped from the end.

    drop_right([1,2,3]);

    # [1,2]

    drop_right(2, [1,2,3])

    # [1]

    drop_right(5, [1,2,3])

    # []

    drop_right(0, [1,2,3])

    #[1,2,3]
=cut

=head2 take

Creates a slice of array with n elements taken from the beginning.

    take([1, 2, 3);

    # [1]

    take(2, [1, 2, 3]);

    # [1, 2]

    take(5, [1, 2, 3]);

    # [1, 2, 3]

    take(0, [1, 2, 3]);

    # []

=cut

=head2 take_right

Creates a slice of array with n elements taken from the end.

    take_right([1, 2, 3]);

    # [3]

    take_right(2, [1, 2, 3]);

    # [2, 3]

    take_right(5, [1, 2, 3]);

    # [1, 2, 3]

    take_right(0, [1, 2, 3]);

    # []

=cut

=head2 second

Returns the second item in an array

    second(["I", "am", "a", "string"])

    # "am"

    second([5,4,3,2,1])

    # 4

=cut

=head2 first

Returns the first item in an array

    first(["I", "am", "a", "string"])

    # "I"

    first([5,4,3,2,1])

    # 5

=cut

=head2 end

Returns the end, or last item in an array

    end(["I", "am", "a", "string"])

    # "string"

    end([5,4,3,2,1])

    # 1

=cut

=head2 len

Returns the length of the collection.
If an array, returns the number of items.
If a hash, the number of key-val pairs.
If a string, the number of chars (following built-in split)

    len([1,2,3,4])

    # 4

    len("Hello")

    # 5

    len({ key => 'val', key2 => 'val'})

    #2

    len([])

    # 0

=cut

=head2 noop

A function that does nothing (like our government), and returns undef

    noop()

    # undef

=cut

=head2 identity

A function that returns its first argument

    identity()

    # undef

    identity(1)

    # 1

    identity([1,2,3])

    # [1,2,3]

=cut

=head2 eql

Returns 0 or 1 if the two values have == equality, with convience wrapping
for different types (no need to use eq vs ==). Follows internal perl rules
on equality following strings vs numbers in perl.

    eql([], [])

    # 1

    eql(1,1)

    # 1


    my $obj = {};

    eql($obj, $obj);

    # 1


    eql("123", 123)

    # 1  'Following perls internal rules on comparing scalars'


    eql({ key => 'val' }, {key => 'val'});

    # 0 'Only identity equality'

=cut

=head2 is_sub

Returns 0 or 1 if the argument is a sub ref

    is_sub()

    # 0

    is_sub(sub {})

    # 1

    my $sub = sub {};
    is_sub($sub)

    # 1

=cut

=head2 is_array

Returns 0 or 1 if the argument is an array

    is_array()

    # 0

    is_array([1,2,3])

    # 1

=cut

=head2 is_hash

Returns 0 or 1 if the argument is a hash

    is_hash()

    # 0

    is_hash({ key => 'val' })

    # 1

=cut

=head2 is_empty

Returns 1 if the argument is 'empty',
0 if not empty. Used on strings, arrays, hashes.

    is_empty()

    # 1

    is_empty([])

    # 1

    is_empty([1,2,3])

    # 0

    is_empty({ key => 'val' })

    # 0

    is_empty("I am a string")

    # 0

=cut

=head2 get

Returns value from hash, string, array based on key/idx provided.
Returns default value if provided key/idx does not exist on collection.
Only works one level deep;

    my $hash = {
        key1 => 'value1',
    };

    get($hash, 'key1');

    # 'value1'


    my $array = [100, 200, 300]

    get($array, 1);

    # 200


    my $string = "Hello";

    get($string, 1);

    # e


    # Also has the ability to supply default-value when key/idx does not exist

    my $hash = {
        key1 => 'value1',
    };

    get($hash, 'key2', "DEFAULT HERE");

    # 'DEFAULT HERE'

=cut

=head2 spread

Destructures an array / hash into non-ref context.
Destructures a string into an array of chars (following in-built split)

    spread([1,2,3,4])

    # 1,2,3,4

    spread({ key => 'val' })

    # key,'val'

    spread("Hello")

    # 'H','e','l','l','o'

=cut

=head2 bool

Returns 0 or 1 based on truthiness of argument, following
internal perl rules based on ternary coercion

    bool([])

    # 1

    bool("hello!")

    # 1

    bool()

    # 0

    bool(undef)

    # 0

=cut

=head2 to_keys

Creates an array of the key names in a hash,
indicies of an array, or chars in a string

    to_keys([1,2,3])

    # [0,1,2]

    to_keys({ key => 'val', key2 => 'val2' })

    # ['key', 'key2']

    to_keys("Hey")

    # [0, 1, 2];

=cut

=head2 to_vals

Creates an array of the values in a hash, of an array, or string.

    to_vals([1,2,3])

    # [0,1,2]

    to_vals({ key => 'val', key2 => 'val2' })

    # ['val', 'val2']

    to_vals("Hey");

    # ['H','e','y'];

=cut

=head2 to_pairs

Creates an array of key-value, or idx-value pairs from arrays, hashes, and strings.
If used on a hash, key-pair order can not be guaranteed;

    to_pairs("I am a string");

    # [
    #  [0, "I"],
    #  [1, "am"],
    #  [2, "a"],
    #  [3, "string"]
    # ]

    to_pairs([100, 101, 102]);

    # [
    #  [0, 100],
    #  [1, 102],
    #  [2, 103],
    # ]

    to_pairs({ key1 => 'value1', key2 => 'value2' });

    # [
    #   [key1, 'value1'],
    #   [key2, 'value2']
    # ]

    to_pairs({ key1 => 'value1', key2 => { nested => 'nestedValue' }});

    # [
    #   [key1, 'value1'],
    #   [key2, { nested => 'nestedValue' }]
    # ]

=cut

=head2 uniq

Creates a duplicate-free version of an array,
in which only the first occurrence of each element is kept.
The order of result values is determined by the order they occur in the array.

    uniq([2,1,2])

    # [2,1]

    uniq(["Hi", "Howdy", "Hi"])

    # ["Hi", "Howdy"]

=cut

=head2 assoc

Returns new hash, or array, with the updated value at index / key.
Shallow updates only

    assoc([1,2,3,4,5,6,7], 0, "item")

    # ["item",2,3,4,5,6,7]

    assoc({ name => 'sally', age => 26}, 'name', 'jimmy')

    # { name => 'jimmy', age => 26}

=cut

=head2 subarray

Returns a subset of the original array, based on
start index (inclusive) and end idx (not-inclusive)

    subarray(["first", "second", "third", "fourth"], 0,2)

    # ["first", "second"]

=cut

=head2 find

Iterates over elements of collection, returning the first element predicate returns truthy for.

    my $people = [
        {
            name => 'john',
            age => 25,
        },
        {
            name => 'Sally',
            age => 25,
        }
    ]

    find(sub {
        my $person = shift;
        return eql($person->{'name'}, 'sally')
    }, $people);

    # { name => 'sally', age => 25 }

=cut

=head2 filter

Iterates over elements of collection, returning only elements the predicate returns truthy for.

    my $people = [
        {
            name => 'john',
            age => 25,
        },
        {
            name => 'Sally',
            age => 25,
        },
        {
            name => 'Old Greg',
            age => 100,
        }
    ]

    filter(sub {
        my $person = shift;
        return $person->{'age'} < 30;
    }, $people);

    # [
    #    {
    #        name => 'john',
    #        age => 25,
    #    },
    #    {
    #        name => 'Sally',
    #        age => 25,
    #    }
    # ]

=cut

=head2 none

If one element is found to return truthy for the given predicate, none returns 0


    my $people = [
        {
            name => 'john',
            age => 25,
        },
        {
            name => 'Sally',
            age => 25,
        },
        {
            name => 'Old Greg',
            age => 100,
        }
    ]

    none(sub {
        my $person = shift;
        return $person->{'age'} > 99;
    }, $people);

    # 0

    none(sub {
        my $person = shift;
        return $person->{'age'} > 101;
    }, $people);

    # 1

=cut

=head2 every

Itterates through each element in the collection, and checks if element makes predicate
return truthy. If all elements cause predicate to return truthy, every returns 1;

    every(sub {
        my $num = shift;
        $num > 0;
    }, [1,2,3,4]);

    # 1

    every(sub {
        my $num = shift;
        $num > 2;
    }, [1,2,3,4]);

    # 0

=cut

=head2 some

Checks if predicate returns truthy for any element of collection.
Iteration is stopped once predicate returns truthy.

    some(sub {
        my $num = shift;
        $num > 0;
    }, [1,2,3,4]);

    # 1

    some(sub {
        my $num = shift;
        $num > 2;
    }, [1,2,3,4]);

    # 1

=cut

=head2 partial

Creates a function that invokes func with partials prepended to the arguments it receives.
(funcRef, args)

    my $add_three_nums = sub {
        my ($a, $b, $c) = @_;

        return $a + $b + $c;
    };

    my $add_two_nums = partial($add_three_nums, 1);

    $add_two_nums->(1,1)

    # 3


    # Can also use __ to act as a placeholder

    my $add_four_strings = sub {
        my ($a, $b, $c, $d) = @_;

        return $a . $b . $c . $d;
    };

    my $add_two_strings = partial($add_four_strings, "first ", __, "third ", __);

    $add_two_strings->("second ", "third ")

    # "first second third fourth"

=cut

=head2 chain

Composes functions, left to right, and invokes them, returning
the result. Accepts an expression as the first argument, to be passed
as the first argument to the proceding function

    chain(
        [1,2,3, [4,5,6]],
        sub {
            my $array = shift;
            return [spread($array), 7]
        },
        \&flatten,
    );

    # [1,2,3,4,5,6,7]


    # Invokes first function, and uses that as start value for next func
    chain(
        sub { [1,2,3, [4,5,6]] },
        sub {
            my $array = shift;
            return [spread($array), 7]
        },
        \&flatten,
    )

    # [1,2,3,4,5,6,7]

=cut

=head2 flow

Creates a function that returns the result of invoking the given functions,
where each successive invocation is supplied the return value of the previous.

    my $addTwo = flow(\&incr, \&incr);

    $addTwo->(1);

    # 3

=cut

=head1 AUTHOR

Kristopher C. Paulsen, C<< <kristopherpaulsen+cpan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sub-fp at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sub-Fp>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sub::Fp


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sub-Fp>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sub-Fp>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sub-Fp>

=item * Search CPAN

L<https://metacpan.org/release/Sub-Fp>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

MIT

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


=cut

1;
