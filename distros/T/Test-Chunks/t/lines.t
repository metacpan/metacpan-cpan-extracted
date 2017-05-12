use Test::Chunks;

plan tests => 6;

my @lines1 = [chunks]->[0]->text1;
ok(@lines1 == 3);
is_deeply 
\@lines1,
[
    "One\n",
    "Two\n",
    "Three \n",
];

my @lines2 = [chunks]->[0]->text2;
ok(@lines2 == 3);
is_deeply
\@lines2,
[
    "Three",
    "Two",
    "One",
];

is(ref([chunks]->[0]->text3), 'ARRAY');
is(scalar(@{[chunks]->[0]->text3}), 0);

__END__
=== One
--- text1 lines
One
Two
Three 
--- text2 lines chomp
Three
Two
One
--- text3 lines array
