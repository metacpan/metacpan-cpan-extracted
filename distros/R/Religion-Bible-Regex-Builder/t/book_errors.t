use t::TestConfig;
use utf8;
use Data::Dumper;
no warnings;

plan tests => 3 * blocks;

run {
    my $block = shift;
    my $c = new Religion::Bible::Regex::Config($block->yaml); 
    my $r = new Religion::Bible::Regex::Builder($c);
    
    # book should return undef if passed undef
    my $result = $r->book(undef);
    my $expected = undef;
    chomp $expected;
    is_deeply($result, $expected, $block->name . ": with the abbreviation");

    # book should return undef if passed an invalid key
    $result = $r->book($block->key);
    $expected = undef;
    chomp $expected;
    is_deeply($result, $expected, $block->name . ": asking with the canonical book name");


    # book should return undef if passed an invalid abbreviation
    $result = $r->book($block->abbreviation);
    $expected = undef;
    chomp $expected;
    is_deeply($result, $expected, $block->name . ": asking with the canonical book name");

};


__END__

=== many books
--- yaml
---
books:
  1: 
    Match:
      Book: ['Genèse', 'Genese']
      Abbreviation: ['Ge']
    Normalized: 
      Book: Genèse
      Abbreviation: Ge
--- key
2
--- book_error
Exode
--- abbreviation
Ex
