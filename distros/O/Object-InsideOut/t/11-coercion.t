use strict;
use warnings;

use Test::More 'tests' => 35;

my  %global_hash;
my  @global_array;
sub  global_sub {}

my  %global_hash2;
my  @global_array2;
sub  global_sub2 {}

# Test basic coercions...
package BaseClass; {
    use Object::InsideOut;

    sub as_str    : STRINGIFY  { return 'hello world' }
    sub as_num    : NUMERIFY   { return 42 }
    sub as_bool   : BOOLIFY    { return }

    sub as_code   : CODIFY     { return \&::global_sub    }
    sub as_glob   : GLOBIFY    { return \*::global_glob   }
    sub as_hash   : HASHIFY    { return \%global_hash   }
    sub as_array  : ARRAYIFY   { return \@global_array  }
}

# Test inheritance without change...
package DerClass; {
    use Object::InsideOut qw(BaseClass);
}

# Test inheritance with change...
package DerClass2; {
    use Object::InsideOut qw(BaseClass);

    sub as_str    : STRINGIFY  { return 'goodbye world' }
    sub as_num    : NUMERIFY   { return 86 }
    sub as_bool   : BOOLIFY    { return 1 }

    sub as_code   : CODIFY     { return \&::global_sub2    }
    sub as_glob   : GLOBIFY    { return \*::global_glob2   }
    sub as_hash   : HASHIFY    { return \%global_hash2     }
    sub as_array  : ARRAYIFY   { return \@global_array2    }
}

# Test inheritance with change and they don't re-specify the coercions
package DerClass3; {
    use Object::InsideOut qw(BaseClass);

    sub as_str     { return 'goodbye world' }
    sub as_num     { return 86 }
    sub as_bool    { return 1 }

    sub as_code    { return \&::global_sub2    }
    sub as_glob    { return \*::global_glob2   }
    sub as_hash    { return \%global_hash2     }
    sub as_array   { return \@global_array2    }
}

# Test inheritance with changing the subs used for the coercions
package DerClass4; {
    use Object::InsideOut qw(BaseClass);

    sub as_str_changed    : STRINGIFY { return 'goodbye world' }
    sub as_num_changed    : NUMERIFY  { return 86 }
    sub as_bool_changed   : BOOLIFY   { return 1 }

    sub as_code_changed   : CODIFY    { return \&::global_sub2    }
    sub as_glob_changed   : GLOBIFY   { return \*::global_glob2   }
    sub as_hash_changed   : HASHIFY   { return \%global_hash2     }
    sub as_array_changed  : ARRAYIFY  { return \@global_array2    }
}


package main;

MAIN:
{
    my $obj;

    # Basic coercions...

    $obj = BaseClass->new();

    ok !$obj                            => 'Base Boolean coercion';
    is 0+$obj, 42                       => 'Base Numeric coercion';
    is "$obj", 'hello world'            => 'Base String coercion';

    is \&{$obj}, \&global_sub           => 'Base Code coercion';
    is \*{$obj}, \*global_glob          => 'Base Glob coercion';
    is \%{$obj}, \%global_hash          => 'Base Hash coercion';
    is \@{$obj}, \@global_array         => 'Base Array coercion';


    # Inheriting coercions...

    $obj = DerClass->new();

    ok !$obj                            => 'Der Boolean coercion';
    is 0+$obj, 42                       => 'Der Numeric coercion';
    is "$obj", 'hello world'            => 'Der String coercion';

    is \&{$obj}, \&global_sub           => 'Der Code coercion';
    is \*{$obj}, \*global_glob          => 'Der Glob coercion';
    is \%{$obj}, \%global_hash          => 'Der Hash coercion';
    is \@{$obj}, \@global_array         => 'Der Array coercion';


    # Redefining coercions on inheritance...

    $obj = DerClass2->new();

    ok $obj                             => 'Der2 Boolean coercion';
    is 0+$obj, 86                       => 'Der2 Numeric coercion';
    is "$obj", 'goodbye world'          => 'Der2 String coercion';

    is \&{$obj}, \&global_sub2          => 'Der2 Code coercion';
    is \*{$obj}, \*global_glob2         => 'Der2 Glob coercion';
    is \%{$obj}, \%global_hash2         => 'Der2 Hash coercion';
    is \@{$obj}, \@global_array2        => 'Der2 Array coercion';


    # Inheritance with change and they don't re-specify the coercions

    $obj = DerClass3->new();

    ok $obj                             => 'Der3 Boolean coercion';
    is 0+$obj, 86                       => 'Der3 Numeric coercion';
    is "$obj", 'goodbye world'          => 'Der3 String coercion';

    is \&{$obj}, \&global_sub2          => 'Der3 Code coercion';
    is \*{$obj}, \*global_glob2         => 'Der3 Glob coercion';
    is \%{$obj}, \%global_hash2         => 'Der3 Hash coercion';
    is \@{$obj}, \@global_array2        => 'Der3 Array coercion';


    # Inheritance with changing the subs used for the coercions

    $obj = DerClass4->new();

    ok $obj                             => 'Der4 Boolean coercion';
    is 0+$obj, 86                       => 'Der4 Numeric coercion';
    is "$obj", 'goodbye world'          => 'Der4 String coercion';

    is \&{$obj}, \&global_sub2          => 'Der4 Code coercion';
    is \*{$obj}, \*global_glob2         => 'Der4 Glob coercion';
    is \%{$obj}, \%global_hash2         => 'Der4 Hash coercion';
    is \@{$obj}, \@global_array2        => 'Der4 Array coercion';
}

exit(0);

# EOF
