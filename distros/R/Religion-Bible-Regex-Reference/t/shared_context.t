use t::TestConfig;
use utf8;
use Data::Dumper;
no warnings;

plan tests => 11;
    
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
  3: 
    Match:
      Book: ['Lévitique', 'Levitique']
      Abbreviation: ['Lé']
    Normalized: 
      Book: Lévitique
      Abbreviation: Lé
  4: 
    Match:
      Book: ['Nombres']
      Abbreviation: ['No']
    Normalized: 
      Book: Nombres
      Abbreviation: No
  5: 
    Match:
      Book: ['Deutéronome', 'Deuteronome']
      Abbreviation: ['De', 'Dt']
    Normalized: 
      Book: Deutéronome
      Abbreviation: De
reference:
  intervale: -
regex:
  intervale: (?:-|–|−|à)
  chapitre_mots: (?:voir aussi|voir|\\(|voir chapitre|\\bde\\b)
  verset_mots: (?:vv?\.|voir aussi v\.)
  livres_avec_un_chapitre: (?:Ab|Abdias|2Jn|2Jean|Phm|Philemon|Philémon|Jud|Jude|3Jn|3Jean)

YAML

my $c = new Religion::Bible::Regex::Config($yaml); 
my $b = new Religion::Bible::Regex::Builder($c);

run {
    my $block = shift;
    my $r1 = new Religion::Bible::Regex::Reference($c, $b);	
    my $r2 = new Religion::Bible::Regex::Reference($c, $b);	
    
    $r1->parse($block->ref1, $block->ref1state);    
    $r2->parse($block->ref2, $block->ref2state);    
    my $i = $r1->shared_state($r2);

    is($r1->shared_state($r2), $block->result, $block->name);
};

__END__


=== combine Exode 2; 3
--- ref1 chomp
Exode 2
--- ref2 chomp
Exode 3
--- result chomp
CHAPTER

=== combine És 2.10-21; Es 13.6-22
--- ref1 chomp
És 2.10-21
--- ref2 chomp
Es 13.6-22
--- result chomp
CHAPTER

=== combine LCV,CV - Ge 4:5, 8:15
--- ref1 chomp
Ge 4:5
--- ref2 chomp
voir 8:15
--- result eval

=== combine LCV,LCV - Ge 4:5, Ge 4:5
--- ref1 chomp
Ge 4:5
--- ref2 chomp
Ge 4:5
--- result eval

=== combine LCV,LCV - Ge 12:5, Ge 12:9
--- ref1 chomp
Ge 12:5
--- ref2 chomp
Ge 12:9
--- result chomp
VERSE

=== combine LCV,LCV - Ge 4:5, Ge 12:9
--- ref1 chomp
Ge 4:5
--- ref2 chomp
Ge 12:9
--- result chomp
CHAPTER

=== combine LCV,LCV - Ge 4:5, Ex 12:9
--- ref1 chomp
Ge 4:5
--- ref2 chomp
Ex 12:9
--- result chomp
BOOK

=== combine LC,LCV - Ge 12, Ge 4:5
--- ref1 chomp
Ge 12
--- ref2 chomp
Ge 4:5
--- result chomp
CHAPTER

=== combine LCV,CCV - Ge 4:5, 12-13:5
--- ref1 chomp
Ge 4:5
--- ref2 chomp
12-13:5
--- result eval

=== combine CCV,CCV - 12-13:5, 12-13:5
--- ref1 chomp
12-13:5
--- ref2 chomp
12-13:5
--- result eval

=== combine CC,CCV - 10-11, 12-13:5
--- ref1 chomp
10-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
12-13:5
--- result chomp
CHAPTER
