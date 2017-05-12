use Test::Chunks;

eval { require YAML; 1 } or
plan skip_all => 'Requires YAML';
plan tests => 1 * chunks;

filters {
    data1 => 'yaml',
    data2 => 'eval',
};

run_is_deeply 'data1', 'data2';

__END__
=== YAML Hashes
--- data1
foo: xxx
bar: [ 1, 2, 3]
--- data2
+{
    foo => 'xxx',
    bar => [1,2,3],
}


=== YAML Arrays
--- data1
- foo
- bar
- {x: y}
--- data2
[
    'foo',
    'bar',
    { x => 'y' },
]


=== YAML Scalar
--- data1
--- |
    sub foo {
        print "bar\n";
    }
--- data2
<<'END';
sub foo {
    print "bar\n";
}
END
