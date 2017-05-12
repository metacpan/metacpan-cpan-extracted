[![Build Status](https://travis-ci.org/mihyaeru21/p5-Test-Deep-ArrayEachNotEmpty.svg?branch=master)](https://travis-ci.org/mihyaeru21/p5-Test-Deep-ArrayEachNotEmpty)
# NAME

Test::Deep::ArrayEachNotEmpty - an alternative to Test::Deep::ArrayEach

# SYNOPSIS

    use Test::Deep;
    use Test::Deep::ArrayEachNotEmpty;

    my $empty = [];
    my $array = [{ foo => 1 }];

    cmp_deeply $empty, array_each({ foo => 1 });
    # => pass

    cmp_deeply $array, array_each({ foo => 1 });
    # => pass

    cmp_deeply $empty, array_each_not_empty({ foo => 1 });
    # => fail

    cmp_deeply $array, array_each_not_empty({ foo => 1 });
    # => pass

# DESCRIPTION

Test::Deep::ArrayEachNotEmpty is a sub class of Test::Deep::ArrayEach
which forbid an empty array.

# LICENSE

Copyright (C) Mihyaeru/mihyaeru21.

Released under the MIT license.

See `LICENSE` file.

# AUTHOR

Mihyaeru <mihyaeru21@gmail.com>
