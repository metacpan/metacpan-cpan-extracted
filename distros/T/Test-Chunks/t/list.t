use Test::Chunks;

plan tests => 5;

my $chunk1 = [chunks]->[0];
my @values = $chunk1->grocery;
is(scalar(@values), 3, 'check list context');
is_deeply \@values, ['apples', 'oranges', 'beef jerky'], 'list context content';

my $chunk2 = [chunks]->[1];
is_deeply $chunk2->todo, 
[
    'Fix YAML', 
    'Fix Inline', 
    'Fix Test::Chunks',
], 'deep chunk from index';

my $chunk3 = [chunks]->[2];
is($chunk3->perl, 'xxx', 'scalar context');
is_deeply([$chunk3->perl], ['xxx', 'yyy', 'zzz'], 'deep list compare');

__END__

=== One
--- grocery lines chomp
apples
oranges
beef jerky

=== Two
--- todo lines chomp array
Fix YAML
Fix Inline
Fix Test::Chunks

=== Three
--- perl eval
return qw(
    xxx
    yyy
    zzz
)
