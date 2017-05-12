use Test::More 'no_plan';
use strict;
use warnings;

BEGIN { use_ok("Religion::Bible::Reference"); }

{
	my $bibref = bibref("Jn 1:10-11,20-21,23");
	is(
		$bibref->stringify,
		"John 1:10-11, 20-21, 23",
		"Jn 1:10-11,20-21,23 stringification"
	);

  { # iterate scalarly
    my $iterator = $bibref->iterator;

    isa_ok($iterator, 'Religion::Bible::Reference::Iterator', '->iterator');

    my @verses = (10, 11, 20, 21, 23);

    while (my $verse = $iterator->next) {
      is($verse, (shift @verses), "iterator result scalar context");
    }
  }

  { # iterate listwise
    my $iterator = $bibref->iterator;

    isa_ok($iterator, 'Religion::Bible::Reference::Iterator', '->iterator');

    my @verses = (10, 11, 20, 21, 23);

    while (my @verse = $iterator->next) {
      is_deeply(
        \@verse,
        [ 'John', 1, (shift @verses) ],
        "iterator result list context"
      );
    }
  }

	is(
		$bibref->stringify,
		"John 1:10-11, 20-21, 23",
		"Jn 1:10-11,20-21,23 stringification -- unchanged"
	);
}

{
    my $bibref = bibref("Jn 1");
    my $iterator = $bibref->iterator;
    isa_ok($iterator, 'Religion::Bible::Reference::Iterator', '->iterator');

    my $count; $count++ while $iterator->next;
    is($count, 51, "Iterating whole chapters works");
}

