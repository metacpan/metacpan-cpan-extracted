[![Build Status](https://travis-ci.org/karupanerura/Test-Deep-Fuzzy.svg?branch=master)](https://travis-ci.org/karupanerura/Test-Deep-Fuzzy) [![Coverage Status](http://codecov.io/github/karupanerura/Test-Deep-Fuzzy/coverage.svg?branch=master)](https://codecov.io/github/karupanerura/Test-Deep-Fuzzy?branch=master)
# NAME

Test::Deep::Fuzzy - fuzzy number comparison with Test::Deep

# SYNOPSIS

```perl
use Test::Deep;
use Test::Deep::Fuzzy;

my $range = 0.001;

cmp_deeply({
    number => 0.0078125,
}, {
    number => is_fuzzy_num(0.008, $range),
}, 'number is collect');
```

# DESCRIPTION

Test::Deep::Fuzzy provides fuzzy number comparison with [Test::Deep](https://metacpan.org/pod/Test::Deep).

# FUNCTIONS

- **is\_fuzzy\_num** EXPECTED, RANGE

    Rounds the values before comparing the values.
    The RANGE is used for `Math::Round::nearest()` to compare the values.

# SEE ALSO

[Math::Round](https://metacpan.org/pod/Math::Round)
[Test::Deep](https://metacpan.org/pod/Test::Deep)
[Test::Number::Delta](https://metacpan.org/pod/Test::Number::Delta)

# LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

karupanerura <karupa@cpan.org>
