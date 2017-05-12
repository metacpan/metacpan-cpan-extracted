#! perl
#
# Testing basic functions of paginator.

use strict;
use warnings;
use Test::More;

use Template::Flute::Paginator;

my @test_specs = ({count => 50, page_size => 10},
    {count => 31, page_size => 10});

plan tests => 4 + 3 * scalar @test_specs;

# basic tests
my ($cart, $iter);

$cart = [{isbn => '978-0-2016-1622-4', title => 'The Pragmatic Programmer',
          quantity => 1},
         {isbn => '978-1-4302-1833-3',
          title => 'Pro Git', quantity => 1},
 		];

$iter = Template::Flute::Paginator->new($cart);

isa_ok($iter, 'Template::Flute::Paginator')
    || diag "Failed to create iterator: $@";

ok($iter->count == 2);

isa_ok($iter->next, 'HASH');

$iter->seed({isbn => '978-0-9779201-5-0', title => 'Modern Perl',
             quantity => 10});

ok($iter->count == 1);

# computed tests
my ($count, $expected);

for my $spec (@test_specs) {
    $iter = Template::Flute::Paginator->new(generate_iterator($spec->{count}),
                                            page_size => $spec->{page_size});

    ok($iter->count == $spec->{count});

    # test calculation of page count
    $count = $iter->pages;
    $expected = int($spec->{count} / $spec->{page_size});
    if ($spec->{count} % $spec->{page_size}) {
        $expected++;
    }
    
    ok($count == $expected, 
       "Page count with $spec->{count} items and $spec->{page_size} per page.")
        || diag "Page count $count instead of $expected.";
    
    $count = count_exhausted($iter);
    $expected = $spec->{page_size};

    ok($count == $expected, 
       "Exhausted count with $spec->{count} items and $spec->{page_size} per page.")
        || diag "Exhausted count $count instead of $expected.";
}

# creates iterator with $count items
sub generate_iterator {
    my $count = shift;
    my @arr;
    
    for (1 .. $count) {
        push @arr, {value => $_};
    }

    return \@arr;
}

# counts iteration until iterator is exhausted
sub count_exhausted {
    my $iter = shift;
    my $count = 0;
    
    while ($iter->next) {
        $count++;
    }

    return $count;
}
