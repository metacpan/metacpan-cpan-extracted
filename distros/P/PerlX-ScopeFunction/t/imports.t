use Test2::V0;

# Dont `use`, to avoid calling `import` function
require PerlX::ScopeFunction;

subtest "as-is", sub {
    my $import_as = PerlX::ScopeFunction::__parse_imports("foo", "bar");
    is $import_as, hash {
        field "foo" => "foo";
        field "bar" => "bar";
        end;
    };
};

subtest "A as B", sub {
    my $import_as = PerlX::ScopeFunction::__parse_imports(
        "foo" => { -as => "foooo" },
        "bar" => { -as => "barrr" },
    );

    is $import_as, hash {
        field "foo" => "foooo";
        field "bar" => "barrr";
        end;
    };
};

subtest "mixed", sub {
    my $import_as = PerlX::ScopeFunction::__parse_imports(
        "qux",
        "foo" => { -as => "foooo" },
        "baz",
        "bar" => { -as => "barrr" },
    );

    is $import_as, hash {
        field "foo" => "foooo";
        field "bar" => "barrr";
        field "baz" => "baz";
        field "qux" => "qux";
        end;
    };
};

subtest "noise in the input are ignored", sub {
    my $import_as = PerlX::ScopeFunction::__parse_imports(
        "qux",
        "foo" => ["XXX"],
        { -as => "barrr" },
        "baz",
        [],
        { cat  => "dog" },
        { -as  => "dog" },
        undef,
        "bar" => { -as => "barrr" },
        undef,
    );

    is $import_as, hash {
        field "foo" => "barrr";
        field "bar" => "barrr";
        field "baz" => "baz";
        field "qux" => "qux";
        end;
    }
};



done_testing;
