use t::TestConfig;
#use utf8;
use Data::Dumper;
no warnings;

plan tests => 18;
    
my $yaml = <<"YAML";
books:
  1: 
    Match:
      Book: ['Genèse', 'Genese']
      Abbreviation: ['Ge']
    Normalized: 
      Book: Genèse
      Abbreviation: Ge
  2: 
    Match:
      Book: ['Exode']
      Abbreviation: ['Ex']
    Normalized: 
      Book: Exode
      Abbreviation: Ex

YAML

my $c = new Religion::Bible::Regex::Config($yaml); 
my $b = new Religion::Bible::Regex::Builder($c);

run {
    my $block = shift;

    # Initialize two references
    my $r1 = new Religion::Bible::Regex::Reference($c, $b);
    my $r2 = new Religion::Bible::Regex::Reference($c, $b);

    # Parse the references
    $r1->parse($block->min, $block->state);
    $r2->parse($block->max, $block->state);

    # Do the testing
    is($r1->lt($r2), 1, $block->name . ", r1 > r2");
    is($r2->lt($r1), undef, $block->name . ", r2 > r1");
};

__END__

=== min_max LCV, LCV - Ge 1:5, Ex 2:5
--- min chomp
Ge 1:5
--- max chomp
Ex 2:5
=== min_max LC, LC - Ge 1, Ex 2
--- min chomp
Ge 1
--- max chomp
Ex 2
=== min_max LC, LCV - Ge 1, Ex 2:5
--- min chomp
Ge 1
--- max chomp
Ex 2:5
=== min_max LCV, LC - Ge 1:1-2:5
--- min chomp
Ge 1:1
--- max chomp
Ex 2

=== min_max CV, CV - 1:5, 2:5
--- min chomp
1:5
--- max chomp
2:5
=== min_max C, C - 1, 2
--- min chomp
1
--- max chomp
2
--- state chomp
CHAPTER
=== min_max C, CV - 1, 2:5
--- min chomp
1
--- max chomp
2:5
--- state chomp
CHAPTER
=== min_max CV, C - 1:1, 2
--- min chomp
1:1
--- max chomp
2
--- state chomp
CHAPTER

=== min_max V, V - 1, 2
--- min chomp
1
--- max chomp
2
--- state chomp
VERSE
