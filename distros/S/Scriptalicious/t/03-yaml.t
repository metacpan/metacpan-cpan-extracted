# -*- perl -*-

use Test::More;

BEGIN {
    eval { require YAML; YAML->import };
    if ($@) {
        plan skip_all => "YAML not installed";
    }
    else {
        plan tests => 9;
    }
}

BEGIN {
    use_ok( 'Scriptalicious', -progname => "myscript" );
}

getconf_f
    ("t/eg.conf",
     ( "something|s" => \$foo,
       "invertable1|I!" => \$invertable1,
       "invertable2|J!" => \$invertable2,
       "integer|i=i" => \$integer,
       "string|s=s" => \$string,
       "list1|1=s@" => \@list1,
       "list2|2=s@" => \@list2,
       "hash|H=s%" => \%hash,
     )
    );

is($foo, 1, "plain string");
is($invertable1, 1, "boolean - on");
is($invertable2, 0, "boolean - off");
is($integer, 7, "integer");
is($string, "anything", "string");
is_deeply(\@list1, [qw(one two three)], "list 1 (flow)");
is_deeply(\@list2, [qw(one two three)], "list 2 (inline)");
is_deeply(\%hash, {foo=>"bar",baz=>"cheese"}, "hash");
