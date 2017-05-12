use Test::Chunks;

plan tests => 8;

my $test = Test::Chunks->new;

my @chunks = $test->filters('chomp')->spec_file('t/spec1')->chunks;

is($chunks[0]->foo, '42'); 
is($chunks[0]->bar, '44'); 
is($chunks[1]->xxx, '123'); 
is($chunks[1]->yyy, '321'); 

@chunks = Test::Chunks->new->delimiters('^^^', '###')->chunks;

is($chunks[0]->foo, "42\n"); 
is($chunks[0]->bar, "44\n"); 
is($chunks[1]->xxx, "123\n"); 
is($chunks[1]->yyy, "321\n"); 

__END__
^^^ Test one

### foo
42

### bar
44

^^^ Test two

### xxx
123
### yyy
321
