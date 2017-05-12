use t::TestConfig;
use utf8;
use Data::Dumper;
no warnings;

plan tests => 3 * blocks;

run {
    my $block = shift;
    my $c = new Religion::Bible::Regex::Config($block->yaml); 
    my $r = new Religion::Bible::Regex::Builder($c);
    
    # Given a key return the abbreviation
    my $result = $r->abbreviation(undef);
    my $expected = undef;
    chomp $expected;
    is_deeply($result, $expected, $block->name . ": with the abbreviation");

    # Given a book return the abbreviation
    $result = $r->abbreviation($block->book);
    $expected = undef;
    chomp $expected;
    is_deeply($result, $expected, $block->name . ": asking with the canonical book name");

    # book should return undef if passed an invalid key
    $result = $r->abbreviation($block->key);
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
