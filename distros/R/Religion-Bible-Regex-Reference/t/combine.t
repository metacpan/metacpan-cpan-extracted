use t::TestConfig;
use utf8;
use Data::Dumper;
no warnings;

plan tests => 349;
    
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

regex:
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

    is($r1->combine($r2)->formatted_normalize, $block->result, $block->name);
};

__END__
=== combine LCV,CV - Ge 4:5, 8:15
--- ref1 chomp
Ge 4:5
--- ref2 chomp
voir 8:15
--- result chomp
voir Ge 8:15

=== combine LCV,LCV - Ge 4:5, Ge 4:5, BOOK
--- ref1 chomp
Ge 4:5
--- ref2 chomp
Ge 4:5
--- result chomp
Ge 4:5

=== combine LCV,LCV - Ge 4:5, Ge 12:9, CHAPTER
--- ref1 chomp
Ge 4:5
--- ref2 chomp
Ge 12:9
--- result chomp
Ge 12:9

=== combine LCV,LCV - Ge 4:5, Ex 12:9, VERSE
--- ref1 chomp
Ge 4:5
--- ref2 chomp
Ex 12:9
--- result chomp
Ex 12:9

=== combine LC,LCV - Ge 12, Ge 4:5
--- ref1 chomp
Ge 12
--- ref2 chomp
Ge 4:5
--- result chomp
Ge 4:5

=== combine LCV,CCV - Ge 4:5, 12-13:5
--- ref1 chomp
Ge 4:5
--- ref2 chomp
12-13:5
--- result chomp
Ge 12-13:5


=== combine CCV,CCV - 12-13:5, 12-13:5
--- ref1 chomp
12-13:5
--- ref2 chomp
12-13:5
--- result chomp
12-13:5

=== combine CC,CCV - 10-11, 12-13:5
--- ref1 chomp
10-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
12-13:5
--- result chomp
12-13:5

=== combine CVCV,CCV - 1:5-3:11, 12-13:5
--- ref1 chomp
1:5-3:11
--- ref2 chomp
12-13:5
--- result chomp
12-13:5

=== combine CVV,CCV - 9:5-11, 12-13:5
--- ref1 chomp
9:5-11
--- ref2 chomp
12-13:5
--- result chomp
12-13:5

=== combine CV,CCV - 8:15, 12-13:5
--- ref1 chomp
8:15
--- ref2 chomp
12-13:5
--- result chomp
12-13:5

=== combine C,CCV - 7, 12-13:5
--- ref1 chomp
7
--- ref1state chomp
CHAPTER
--- ref2 chomp
12-13:5
--- result chomp
12-13:5

=== combine VV,CCV - 8-14, 12-13:5
--- ref1 chomp
8-14
--- ref1state chomp
VERSE
--- ref2 chomp
12-13:5
--- result chomp
12-13:5

=== combine V,CCV - 3, 12-13:5
--- ref1 chomp
3
--- ref1state chomp
VERSE
--- ref2 chomp
12-13:5
--- result chomp
12-13:5



=== combine LCVLCV,LCVLCV - Ge 2:5-Ex 6:7, Ge 2:5-Ex 6:7
--- ref1 chomp
Ge 2:5-Ex 6:7
--- ref2 chomp
Ge 2:5-Ex 6:7
--- result chomp
Ge 2:5-Ex 6:7

=== combine LCVLC,LCVLCV - Ge 2:5-Ex 6, Ge 2:5-Ex 6:7
--- ref1 chomp
Ge 2:5-Ex 6
--- ref2 chomp
Ge 2:5-Ex 6:7
--- result chomp
Ge 2:5-Ex 6:7

=== combine LCLCV,LCVLCV - Ge 2-Ex 6:7, Ge 2:5-Ex 6:7
--- ref1 chomp
Ge 2-Ex 6:7
--- ref2 chomp
Ge 2:5-Ex 6:7
--- result chomp
Ge 2:5-Ex 6:7

=== combine LCLC,LCVLCV - Ge 2-Ex 6, Ge 2:5-Ex 6:7
--- ref1 chomp
Ge 2-Ex 6
--- ref2 chomp
Ge 2:5-Ex 6:7
--- result chomp
Ge 2:5-Ex 6:7

=== combine LCCV,LCVLCV - Ge 2-6:4, Ge 2:5-Ex 6:7
--- ref1 chomp
Ge 2-6:4
--- ref2 chomp
Ge 2:5-Ex 6:7
--- result chomp
Ge 2:5-Ex 6:7

=== combine LCC,LCVLCV - Ge 3-9, Ge 2:5-Ex 6:7
--- ref1 chomp
Ge 3-9
--- ref2 chomp
Ge 2:5-Ex 6:7
--- result chomp
Ge 2:5-Ex 6:7

=== combine LCVCV,LCVLCV - Ge 2:8-6:4, Ge 2:5-Ex 6:7
--- ref1 chomp
Ge 2:8-6:4
--- ref2 chomp
Ge 2:5-Ex 6:7
--- result chomp
Ge 2:5-Ex 6:7

=== combine LCVV,LCVLCV - Ge 2:8-10, Ge 2:5-Ex 6:7
--- ref1 chomp
Ge 2:8-10
--- ref2 chomp
Ge 2:5-Ex 6:7
--- result chomp
Ge 2:5-Ex 6:7

=== combine LCV,LCVLCV - Ge 4:5, Ge 2:5-Ex 6:7
--- ref1 chomp
Ge 4:5
--- ref2 chomp
Ge 2:5-Ex 6:7
--- result chomp
Ge 2:5-Ex 6:7

=== combine LC,LCVLCV - Ge 12, Ge 2:5-Ex 6:7
--- ref1 chomp
Ge 12
--- ref2 chomp
Ge 2:5-Ex 6:7
--- result chomp
Ge 2:5-Ex 6:7

=== combine CCV,LCVLCV - 12-13:5, Ge 2:5-Ex 6:7
--- ref1 chomp
12-13:5
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2:5-Ex 6:7
--- result chomp
Ge 2:5-Ex 6:7

=== combine CC,LCVLCV - 10-11, Ge 2:5-Ex 6:7
--- ref1 chomp
10-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2:5-Ex 6:7
--- result chomp
Ge 2:5-Ex 6:7

=== combine CVCV,LCVLCV - 1:5-3:11, Ge 2:5-Ex 6:7
--- ref1 chomp
1:5-3:11
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2:5-Ex 6:7
--- result chomp
Ge 2:5-Ex 6:7

=== combine CVV,LCVLCV - 9:5-11, Ge 2:5-Ex 6:7
--- ref1 chomp
9:5-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2:5-Ex 6:7
--- result chomp
Ge 2:5-Ex 6:7

=== combine CV,LCVLCV - 8:15, Ge 2:5-Ex 6:7
--- ref1 chomp
8:15
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2:5-Ex 6:7
--- result chomp
Ge 2:5-Ex 6:7

=== combine C,LCVLCV - 7, Ge 2:5-Ex 6:7
--- ref1 chomp
7
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2:5-Ex 6:7
--- result chomp
Ge 2:5-Ex 6:7

=== combine VV,LCVLCV - 8-14, Ge 2:5-Ex 6:7
--- ref1 chomp
8-14
--- ref1state chomp
VERSE
--- ref2 chomp
Ge 2:5-Ex 6:7
--- result chomp
Ge 2:5-Ex 6:7

=== combine V,LCVLCV - 3, Ge 2:5-Ex 6:7
--- ref1 chomp
3
--- ref1state chomp
VERSE
--- ref2 chomp
Ge 2:5-Ex 6:7
--- result chomp
Ge 2:5-Ex 6:7





 
=== combine LCVLCV,LCVLC - Ge 2:5-Ex 6:7, Ge 2:5-Ex 6
--- ref1 chomp
Ge 2:5-Ex 6:7
--- ref2 chomp
Ge 2:5-Ex 6
--- result chomp
Ge 2:5-Ex 6

=== combine LCVLC,LCVLC - Ge 2:5-Ex 6, Ge 2:5-Ex 6
--- ref1 chomp
Ge 2:5-Ex 6
--- ref2 chomp
Ge 2:5-Ex 6
--- result chomp
Ge 2:5-Ex 6

=== combine LCLCV,LCVLC - Ge 2-Ex 6:7, Ge 2:5-Ex 6
--- ref1 chomp
Ge 2-Ex 6:7
--- ref2 chomp
Ge 2:5-Ex 6
--- result chomp
Ge 2:5-Ex 6

=== combine LCLC,LCVLC - Ge 2-Ex 6, Ge 2:5-Ex 6
--- ref1 chomp
Ge 2-Ex 6
--- ref2 chomp
Ge 2:5-Ex 6
--- result chomp
Ge 2:5-Ex 6

=== combine LCCV,LCVLC - Ge 2-6:4, Ge 2:5-Ex 6
--- ref1 chomp
Ge 2-6:4
--- ref2 chomp
Ge 2:5-Ex 6
--- result chomp
Ge 2:5-Ex 6

=== combine LCC,LCVLC - Ge 3-9, Ge 2:5-Ex 6
--- ref1 chomp
Ge 3-9
--- ref2 chomp
Ge 2:5-Ex 6
--- result chomp
Ge 2:5-Ex 6

=== combine LCVCV,LCVLC - Ge 2:8-6:4, Ge 2:5-Ex 6
--- ref1 chomp
Ge 2:8-6:4
--- ref2 chomp
Ge 2:5-Ex 6
--- result chomp
Ge 2:5-Ex 6

=== combine LCVV,LCVLC - Ge 2:8-10, Ge 2:5-Ex 6
--- ref1 chomp
Ge 2:8-10
--- ref2 chomp
Ge 2:5-Ex 6
--- result chomp
Ge 2:5-Ex 6

=== combine LCV,LCVLC - Ge 4:5, Ge 2:5-Ex 6
--- ref1 chomp
Ge 4:5
--- ref2 chomp
Ge 2:5-Ex 6
--- result chomp
Ge 2:5-Ex 6

=== combine LC,LCVLC - Ge 12, Ge 2:5-Ex 6
--- ref1 chomp
Ge 12
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2:5-Ex 6
--- result chomp
Ge 2:5-Ex 6

=== combine CCV,LCVLC - 12-13:5, Ge 2:5-Ex 6
--- ref1 chomp
12-13:5
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2:5-Ex 6
--- result chomp
Ge 2:5-Ex 6

=== combine CC,LCVLC - 10-11, Ge 2:5-Ex 6
--- ref1 chomp
10-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2:5-Ex 6
--- result chomp
Ge 2:5-Ex 6

=== combine CVCV,LCVLC - 1:5-3:11, Ge 2:5-Ex 6
--- ref1 chomp
1:5-3:11
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2:5-Ex 6
--- result chomp
Ge 2:5-Ex 6

=== combine CVV,LCVLC - 9:5-11, Ge 2:5-Ex 6
--- ref1 chomp
9:5-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2:5-Ex 6
--- result chomp
Ge 2:5-Ex 6

=== combine CV,LCVLC - 8:15, Ge 2:5-Ex 6
--- ref1 chomp
8:15
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2:5-Ex 6
--- result chomp
Ge 2:5-Ex 6

=== combine C,LCVLC - 7, Ge 2:5-Ex 6
--- ref1 chomp
7
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2:5-Ex 6
--- result chomp
Ge 2:5-Ex 6

=== combine VV,LCVLC - 8-14, Ge 2:5-Ex 6
--- ref1 chomp
8-14
--- ref1state chomp
VERSE
--- ref2 chomp
Ge 2:5-Ex 6
--- result chomp
Ge 2:5-Ex 6

=== combine V,LCVLC - 3, Ge 2:5-Ex 6
--- ref1 chomp
3
--- ref1state chomp
VERSE
--- ref2 chomp
Ge 2:5-Ex 6
--- result chomp
Ge 2:5-Ex 6




=== combine LCLCV,LCLCV - Ge 2-Ex 6:7, Ge 2-Ex 6:7
--- ref1 chomp
Ge 2-Ex 6:7
--- ref2 chomp
Ge 2-Ex 6:7
--- result chomp
Ge 2-Ex 6:7

=== combine LCLC,LCLCV - Ge 2-Ex 6, Ge 2-Ex 6:7
--- ref1 chomp
Ge 2-Ex 6
--- ref2 chomp
Ge 2-Ex 6:7
--- result chomp
Ge 2-Ex 6:7

=== combine LCCV,LCLCV - Ge 2-6:4, Ge 2-Ex 6:7
--- ref1 chomp
Ge 2-6:4
--- ref2 chomp
Ge 2-Ex 6:7
--- result chomp
Ge 2-Ex 6:7

=== combine LCC,LCLCV - Ge 3-9, Ge 2-Ex 6:7
--- ref1 chomp
Ge 3-9
--- ref2 chomp
Ge 2-Ex 6:7
--- result chomp
Ge 2-Ex 6:7

=== combine LCVCV,LCLCV - Ge 2:8-6:4, Ge 2-Ex 6:7
--- ref1 chomp
Ge 2:8-6:4
--- ref2 chomp
Ge 2-Ex 6:7
--- result chomp
Ge 2-Ex 6:7

=== combine LCVV,LCLCV - Ge 2:8-10, Ge 2-Ex 6:7
--- ref1 chomp
Ge 2:8-10
--- ref2 chomp
Ge 2-Ex 6:7
--- result chomp
Ge 2-Ex 6:7

=== combine LCV,LCLCV - Ge 4:5, Ge 2-Ex 6:7
--- ref1 chomp
Ge 4:5
--- ref2 chomp
Ge 2-Ex 6:7
--- result chomp
Ge 2-Ex 6:7

=== combine LC,LCLCV - Ge 12, Ge 2-Ex 6:7
--- ref1 chomp
Ge 12
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2-Ex 6:7
--- result chomp
Ge 2-Ex 6:7

=== combine CCV,LCLCV - 12-13:5, Ge 2-Ex 6:7
--- ref1 chomp
12-13:5
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2-Ex 6:7
--- result chomp
Ge 2-Ex 6:7

=== combine CC,LCLCV - 10-11, Ge 2-Ex 6:7
--- ref1 chomp
10-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2-Ex 6:7
--- result chomp
Ge 2-Ex 6:7

=== combine CVCV,LCLCV - 1:5-3:11, Ge 2-Ex 6:7
--- ref1 chomp
1:5-3:11
--- ref2 chomp
Ge 2-Ex 6:7
--- result chomp
Ge 2-Ex 6:7

=== combine CVV,LCLCV - 9:5-11, Ge 2-Ex 6:7
--- ref1 chomp
9:5-11
--- ref2 chomp
Ge 2-Ex 6:7
--- result chomp
Ge 2-Ex 6:7

=== combine CV,LCLCV - 8:15, Ge 2-Ex 6:7
--- ref1 chomp
8:15
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2-Ex 6:7
--- result chomp
Ge 2-Ex 6:7

=== combine C,LCLCV - 7, Ge 2-Ex 6:7
--- ref1 chomp
7
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2-Ex 6:7
--- result chomp
Ge 2-Ex 6:7

=== combine VV,LCLCV - 8-14, Ge 2-Ex 6:7
--- ref1 chomp
8-14
--- ref1state chomp
VERSE
--- ref2 chomp
Ge 2-Ex 6:7
--- result chomp
Ge 2-Ex 6:7

=== combine V,LCLCV - 3, Ge 2-Ex 6:7
--- ref1 chomp
3
--- ref1state chomp
VERSE
--- ref2 chomp
Ge 2-Ex 6:7
--- result chomp
Ge 2-Ex 6:7


=== combine LCVLCV,LCLC - Ge 2:5-Ex 6, Ge 2-Ex 6
--- ref1 chomp
Ge 2:5-Ex 6
--- ref2 chomp
Ge 2-Ex 6
--- result chomp
Ge 2-Ex 6

=== combine LCVLC,LCLC - Ge 2:5-Ex 6, Ge 2-Ex 6
--- ref1 chomp
Ge 2:5-Ex 6
--- ref2 chomp
Ge 2-Ex 6
--- result chomp
Ge 2-Ex 6

=== combine LCLCV,LCLC - Ge 2-Ex 6, Ge 2-Ex 6
--- ref1 chomp
Ge 2-Ex 6
--- ref2 chomp
Ge 2-Ex 6
--- result chomp
Ge 2-Ex 6

=== combine LCLC,LCLC - Ge 2-Ex 6, Ge 2-Ex 6
--- ref1 chomp
Ge 2-Ex 6
--- ref2 chomp
Ge 2-Ex 6
--- result chomp
Ge 2-Ex 6

=== combine LCCV,LCLC - Ge 2-6:4, Ge 2-Ex 6
--- ref1 chomp
Ge 2-6:4
--- ref2 chomp
Ge 2-Ex 6
--- result chomp
Ge 2-Ex 6

=== combine LCC,LCLC - Ge 3-9, Ge 2-Ex 6
--- ref1 chomp
Ge 3-9
--- ref2 chomp
Ge 2-Ex 6
--- result chomp
Ge 2-Ex 6

=== combine LCVCV,LCLC - Ge 2:8-6:4, Ge 2-Ex 6
--- ref1 chomp
Ge 2:8-6:4
--- ref2 chomp
Ge 2-Ex 6
--- result chomp
Ge 2-Ex 6

=== combine LCVV,LCLC - Ge 2:8-10, Ge 2-Ex 6
--- ref1 chomp
Ge 2:8-10
--- ref2 chomp
Ge 2-Ex 6
--- result chomp
Ge 2-Ex 6

=== combine LCV,LCLC - Ge 4:5, Ge 2-Ex 6
--- ref1 chomp
Ge 4:5
--- ref2 chomp
Ge 2-Ex 6
--- result chomp
Ge 2-Ex 6

=== combine LC,LCLC - Ge 12, Ge 2-Ex 6
--- ref1 chomp
Ge 12
--- ref2 chomp
Ge 2-Ex 6
--- result chomp
Ge 2-Ex 6

=== combine CCV,LCLC - 12-13:5, Ge 2-Ex 6
--- ref1 chomp
12-13:5
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2-Ex 6
--- result chomp
Ge 2-Ex 6

=== combine CC,LCLC - 10-11, Ge 2-Ex 6
--- ref1 chomp
10-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2-Ex 6
--- result chomp
Ge 2-Ex 6

=== combine CVCV,LCLC - 1:5-3:11, Ge 2-Ex 6
--- ref1 chomp
1:5-3:11
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2-Ex 6
--- result chomp
Ge 2-Ex 6

=== combine CVV,LCLC - 9:5-11, Ge 2-Ex 6
--- ref1 chomp
9:5-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2-Ex 6
--- result chomp
Ge 2-Ex 6

=== combine CV,LCLC - 8:15, Ge 2-Ex 6
--- ref1 chomp
8:15
--- ref2 chomp
Ge 2-Ex 6
--- result chomp
Ge 2-Ex 6

=== combine C,LCLC - 7, Ge 2-Ex 6
--- ref1 chomp
7
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2-Ex 6
--- result chomp
Ge 2-Ex 6

=== combine VV,LCLC - 8-14, Ge 2-Ex 6
--- ref1 chomp
8-14
--- ref1state chomp
VERSE
--- ref2 chomp
Ge 2-Ex 6
--- result chomp
Ge 2-Ex 6

=== combine V,LCLC - 3, Ge 2-Ex 6
--- ref1 chomp
3
--- ref1state chomp
VERSE
--- ref2 chomp
Ge 2-Ex 6
--- result chomp
Ge 2-Ex 6

 
 



 
=== combine LCVLCV,LCLCV - Ge 2:5-Ex 6:7, Ge 2-Ex 6:7
--- ref1 chomp
Ge 2:5-Ex 6:7
--- ref2 chomp
Ge 2-Ex 6:7
--- result chomp
Ge 2-Ex 6:7

=== combine LCVLC,LCLCV - Ge 2:5-Ex 6, Ge 2-Ex 6:7
--- ref1 chomp
Ge 2:5-Ex 6
--- ref2 chomp
Ge 2-Ex 6:7
--- result chomp
Ge 2-Ex 6:7

=== combine LCVLCV,LCCV - Ge 2:5-Ex 6:7, Ge 2-6:4
--- ref1 chomp
Ge 2:5-Ex 6:7
--- ref2 chomp
Ge 2-6:4
--- result chomp
Ge 2-6:4

=== combine LCVLC,LCCV - Ge 2:5-Ex 6, Ge 2-6:4
--- ref1 chomp
Ge 2:5-Ex 6
--- ref2 chomp
Ge 2-6:4
--- result chomp
Ge 2-6:4

=== combine LCLCV,LCCV - Ge 2-Ex 6:7, Ge 2-6:4
--- ref1 chomp
Ge 2-Ex 6:7
--- ref2 chomp
Ge 2-6:4
--- result chomp
Ge 2-6:4

=== combine LCLC,LCCV - Ge 2-Ex 6, Ge 2-6:4
--- ref1 chomp
Ge 2-Ex 6
--- ref2 chomp
Ge 2-6:4
--- result chomp
Ge 2-6:4

=== combine LCCV,LCCV - Ge 2-6:4, Ge 2-6:4
--- ref1 chomp
Ge 2-6:4
--- ref2 chomp
Ge 2-6:4
--- result chomp
Ge 2-6:4

=== combine LCC,LCCV - Ge 3-9, Ge 2-6:4
--- ref1 chomp
Ge 3-9
--- ref2 chomp
Ge 2-6:4
--- result chomp
Ge 2-6:4

=== combine LCVCV,LCCV - Ge 2:8-6:4, Ge 2-6:4
--- ref1 chomp
Ge 2:8-6:4
--- ref2 chomp
Ge 2-6:4
--- result chomp
Ge 2-6:4

=== combine LCVV,LCCV - Ge 2:8-10, Ge 2-6:4
--- ref1 chomp
Ge 2:8-10
--- ref2 chomp
Ge 2-6:4
--- result chomp
Ge 2-6:4

=== combine LCV,LCCV - Ge 4:5, Ge 2-6:4
--- ref1 chomp
Ge 4:5
--- ref2 chomp
Ge 2-6:4
--- result chomp
Ge 2-6:4

=== combine LC,LCCV - Ge 12, Ge 2-6:4
--- ref1 chomp
Ge 12
--- ref2 chomp
Ge 2-6:4
--- result chomp
Ge 2-6:4

=== combine CCV,LCCV - 12-13:5, Ge 2-6:4
--- ref1 chomp
12-13:5
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2-6:4
--- result chomp
Ge 2-6:4

=== combine CC,LCCV - 10-11, Ge 2-6:4
--- ref1 chomp
10-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2-6:4
--- result chomp
Ge 2-6:4

=== combine CVCV,LCCV - 1:5-3:11, Ge 2-6:4
--- ref1 chomp
1:5-3:11
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2-6:4
--- result chomp
Ge 2-6:4

=== combine CVV,LCCV - 9:5-11, Ge 2-6:4
--- ref1 chomp
9:5-11
--- ref2 chomp
Ge 2-6:4
--- result chomp
Ge 2-6:4

=== combine CV,LCCV - 8:15, Ge 2-6:4
--- ref1 chomp
8:15
---ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2-6:4
--- result chomp
Ge 2-6:4

=== combine C,LCCV - 7, Ge 2-6:4
--- ref1 chomp
7
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2-6:4
--- result chomp
Ge 2-6:4

=== combine VV,LCCV - 8-14, Ge 2-6:4
--- ref1 chomp
8-14
--- ref1state chomp
VERSE
--- ref2 chomp
Ge 2-6:4
--- result chomp
Ge 2-6:4

=== combine V,LCCV - 3, Ge 2-6:4
--- ref1 chomp
3
--- ref1state chomp
VERSE
--- ref2 chomp
Ge 2-6:4
--- result chomp
Ge 2-6:4







 
=== combine LCVLCV,LCC - Ge 2:5-Ex 6:7, Ge 3-9
--- ref1 chomp
Ge 2:5-Ex 6:7
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine LCVLC,LCC - Ge 2:5-Ex 6, Ge 3-9
--- ref1 chomp
Ge 2:5-Ex 6
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine LCLCV,LCC - Ge 2-Ex 6:7, Ge 3-9
--- ref1 chomp
Ge 2-Ex 6:7
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine LCLC,LCC - Ge 2-Ex 6, Ge 3-9
--- ref1 chomp
Ge 2-Ex 6
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine LCCV,LCC - Ge 2-6:4, Ge 3-9
--- ref1 chomp
Ge 2-6:4
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine LCC,LCC - Ge 3-9, Ge 3-9
--- ref1 chomp
Ge 3-9
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine LCVCV,LCC - Ge 2:8-6:4, Ge 3-9
--- ref1 chomp
Ge 2:8-6:4
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine LCVV,LCC - Ge 2:8-10, Ge 3-9
--- ref1 chomp
Ge 2:8-10
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine LCV,LCC - Ge 4:5, Ge 3-9
--- ref1 chomp
Ge 4:5
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine LC,LCC - Ge 12, Ge 3-9
--- ref1 chomp
Ge 12
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine CCV,LCC - 12-13:5, Ge 3-9
--- ref1 chomp
12-13:5
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine CC,LCC - 10-11, Ge 3-9
--- ref1 chomp
10-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine CVCV,LCC - 1:5-3:11, Ge 3-9
--- ref1 chomp
1:5-3:11
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine CVV,LCC - 9:5-11, Ge 3-9
--- ref1 chomp
9:5-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine CV,LCC - 8:15, Ge 3-9
--- ref1 chomp
8:15
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine C,LCC - 7, Ge 3-9
--- ref1 chomp
7
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine VV,LCC - 8-14, Ge 3-9
--- ref1 chomp
8-14
--- ref1state chomp
VERSE
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine V,LCC - 3, Ge 3-9
--- ref1 chomp
3
--- ref1state chomp
VERSE
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

 
=== combine LCVLCV,LCC - Ge 2:5-Ex 6:7, Ge 3-9
--- ref1 chomp
Ge 2:5-Ex 6:7
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine LCVLC,LCC - Ge 2:5-Ex 6, Ge 3-9
--- ref1 chomp
Ge 2:5-Ex 6
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine LCLCV,LCC - Ge 2-Ex 6:7, Ge 3-9
--- ref1 chomp
Ge 2-Ex 6:7
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine LCLC,LCC - Ge 2-Ex 6, Ge 3-9
--- ref1 chomp
Ge 2-Ex 6
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine LCCV,LCC - Ge 2-6:4, Ge 3-9
--- ref1 chomp
Ge 2-6:4
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine LCC,LCC - Ge 3-9, Ge 3-9
--- ref1 chomp
Ge 3-9
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine LCVCV,LCC - Ge 2:8-6:4, Ge 3-9
--- ref1 chomp
Ge 2:8-6:4
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine LCVV,LCC - Ge 2:8-10, Ge 3-9
--- ref1 chomp
Ge 2:8-10
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine LCV,LCC - Ge 4:5, Ge 3-9
--- ref1 chomp
Ge 4:5
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine LC,LCC - Ge 12, Ge 3-9
--- ref1 chomp
Ge 12
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine CCV,LCC - 12-13:5, Ge 3-9
--- ref1 chomp
12-13:5
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine CC,LCC - 10-11, Ge 3-9
--- ref1 chomp
10-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine CVCV,LCC - 1:5-3:11, Ge 3-9
--- ref1 chomp
1:5-3:11
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine CVV,LCC - 9:5-11, Ge 3-9
--- ref1 chomp
9:5-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine CV,LCC - 8:15, Ge 3-9
--- ref1 chomp
8:15
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine C,LCC - 7, Ge 3-9
--- ref1 chomp
7
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine VV,LCC - 8-14, Ge 3-9
--- ref1 chomp
8-14
--- ref1state chomp
VERSE
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9

=== combine V,LCC - 3, Ge 3-9
--- ref1 chomp
3
--- ref1state chomp
VERSE
--- ref2 chomp
Ge 3-9
--- result chomp
Ge 3-9











 
=== combine LCVLCV,LCVCV - Ge 2:5-Ex 6:7, Ge 2:8-6:4
--- ref1 chomp
Ge 2:5-Ex 6:7
--- ref2 chomp
Ge 2:8-6:4
--- result chomp
Ge 2:8-6:4

=== combine LCVLC,LCVCV - Ge 2:5-Ex 6, Ge 2:8-6:4
--- ref1 chomp
Ge 2:5-Ex 6
--- ref2 chomp
Ge 2:8-6:4
--- result chomp
Ge 2:8-6:4

=== combine LCLCV,LCVCV - Ge 2-Ex 6:7, Ge 2:8-6:4
--- ref1 chomp
Ge 2-Ex 6:7
--- ref2 chomp
Ge 2:8-6:4
--- result chomp
Ge 2:8-6:4

=== combine LCLC,LCVCV - Ge 2-Ex 6, Ge 2:8-6:4
--- ref1 chomp
Ge 2-Ex 6
--- ref2 chomp
Ge 2:8-6:4
--- result chomp
Ge 2:8-6:4

=== combine LCCV,LCVCV - Ge 2-6:4, Ge 2:8-6:4
--- ref1 chomp
Ge 2-6:4
--- ref2 chomp
Ge 2:8-6:4
--- result chomp
Ge 2:8-6:4

=== combine LCC,LCVCV - Ge 3-9, Ge 2:8-6:4
--- ref1 chomp
Ge 3-9
--- ref2 chomp
Ge 2:8-6:4
--- result chomp
Ge 2:8-6:4

=== combine LCVCV,LCVCV - Ge 2:8-6:4, Ge 2:8-6:4
--- ref1 chomp
Ge 2:8-6:4
--- ref2 chomp
Ge 2:8-6:4
--- result chomp
Ge 2:8-6:4

=== combine LCVV,LCVCV - Ge 2:8-10, Ge 2:8-6:4
--- ref1 chomp
Ge 2:8-10
--- ref2 chomp
Ge 2:8-6:4
--- result chomp
Ge 2:8-6:4

=== combine LCV,LCVCV - Ge 4:5, Ge 2:8-6:4
--- ref1 chomp
Ge 4:5
--- ref2 chomp
Ge 2:8-6:4
--- result chomp
Ge 2:8-6:4

=== combine LC,LCVCV - Ge 12, Ge 2:8-6:4
--- ref1 chomp
Ge 12
--- ref2 chomp
Ge 2:8-6:4
--- result chomp
Ge 2:8-6:4

=== combine CCV,LCVCV - 12-13:5, Ge 2:8-6:4
--- ref1 chomp
12-13:5
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2:8-6:4
--- result chomp
Ge 2:8-6:4

=== combine CC,LCVCV - 10-11, Ge 2:8-6:4
--- ref1 chomp
10-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2:8-6:4
--- result chomp
Ge 2:8-6:4

=== combine CVCV,LCVCV - 1:5-3:11, Ge 2:8-6:4
--- ref1 chomp
1:5-3:11
--- ref2 chomp
Ge 2:8-6:4
--- result chomp
Ge 2:8-6:4

=== combine CVV,LCVCV - 9:5-11, Ge 2:8-6:4
--- ref1 chomp
9:5-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2:8-6:4
--- result chomp
Ge 2:8-6:4

=== combine CV,LCVCV - 8:15, Ge 2:8-6:4
--- ref1 chomp
8:15
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2:8-6:4
--- result chomp
Ge 2:8-6:4

=== combine C,LCVCV - 7, Ge 2:8-6:4
--- ref1 chomp
7
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2:8-6:4
--- result chomp
Ge 2:8-6:4

=== combine VV,LCVCV - 8-14, Ge 2:8-6:4
--- ref1 chomp
8-14
--- ref1state chomp
VERSE
--- ref2 chomp
Ge 2:8-6:4
--- result chomp
Ge 2:8-6:4

=== combine V,LCVCV - 3, Ge 2:8-6:4
--- ref1 chomp
3
--- ref1state chomp
VERSE
--- ref2 chomp
Ge 2:8-6:4
--- result chomp
Ge 2:8-6:4




=== combine LCVLCV,LCVV - Ge 2:5-Ex 6:7, Ge 2:8-10
--- ref1 chomp
Ge 2:5-Ex 6:7
--- ref2 chomp
Ge 2:8-10
--- result chomp
Ge 2:8-10

=== combine LCVLC,LCVV - Ge 2:5-Ex 6, Ge 2:8-10
--- ref1 chomp
Ge 2:5-Ex 6
--- ref2 chomp
Ge 2:8-10
--- result chomp
Ge 2:8-10

=== combine LCLCV,LCVV - Ge 2-Ex 6:7, Ge 2:8-10
--- ref1 chomp
Ge 2-Ex 6:7
--- ref2 chomp
Ge 2:8-10
--- result chomp
Ge 2:8-10

=== combine LCLC,LCVV - Ge 2-Ex 6, Ge 2:8-10
--- ref1 chomp
Ge 2-Ex 6
--- ref2 chomp
Ge 2:8-10
--- result chomp
Ge 2:8-10

=== combine LCCV,LCVV - Ge 2-6:4, Ge 2:8-10
--- ref1 chomp
Ge 2-6:4
--- ref2 chomp
Ge 2:8-10
--- result chomp
Ge 2:8-10

=== combine LCC,LCVV - Ge 3-9, Ge 2:8-10
--- ref1 chomp
Ge 3-9
--- ref2 chomp
Ge 2:8-10
--- result chomp
Ge 2:8-10

=== combine LCVCV,LCVV - Ge 2:8-6:4, Ge 2:8-10
--- ref1 chomp
Ge 2:8-6:4
--- ref2 chomp
Ge 2:8-10
--- result chomp
Ge 2:8-10

=== combine LCVV,LCVV - Ge 2:8-10, Ge 2:8-10
--- ref1 chomp
Ge 2:8-10
--- ref2 chomp
Ge 2:8-10
--- result chomp
Ge 2:8-10

=== combine LCV,LCVV - Ge 4:5, Ge 2:8-10
--- ref1 chomp
Ge 4:5
--- ref2 chomp
Ge 2:8-10
--- result chomp
Ge 2:8-10

=== combine LC,LCVV - Ge 12, Ge 2:8-10
--- ref1 chomp
Ge 12
--- ref2 chomp
Ge 2:8-10
--- result chomp
Ge 2:8-10

=== combine CCV,LCVV - 12-13:5, Ge 2:8-10
--- ref1 chomp
12-13:5
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2:8-10
--- result chomp
Ge 2:8-10

=== combine CC,LCVV - 10-11, Ge 2:8-10
--- ref1 chomp
10-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2:8-10
--- result chomp
Ge 2:8-10

=== combine CVCV,LCVV - 1:5-3:11, Ge 2:8-10
--- ref1 chomp
1:5-3:11
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2:8-10
--- result chomp
Ge 2:8-10

=== combine CVV,LCVV - 9:5-11, Ge 2:8-10
--- ref1 chomp
9:5-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2:8-10
--- result chomp
Ge 2:8-10

=== combine CV,LCVV - 8:15, Ge 2:8-10
--- ref1 chomp
8:15
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2:8-10
--- result chomp
Ge 2:8-10

=== combine C,LCVV - 7, Ge 2:8-10
--- ref1 chomp
7
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 2:8-10
--- result chomp
Ge 2:8-10

=== combine VV,LCVV - 8-14, Ge 2:8-10
--- ref1 chomp
8-14
--- ref1state chomp
VERSE
--- ref2 chomp
Ge 2:8-10
--- result chomp
Ge 2:8-10

=== combine V,LCVV - 3, Ge 2:8-10
--- ref1 chomp
3
--- ref1state chomp
VERSE
--- ref2 chomp
Ge 2:8-10
--- result chomp
Ge 2:8-10




=== combine LCVLCV,LCV - Ge 2:5-Ex 6:7, Ge 4:5
--- ref1 chomp
Ge 2:5-Ex 6:7
--- ref2 chomp
Ge 4:5
--- result chomp
Ge 4:5

=== combine LCVLC,LCV - Ge 2:5-Ex 6, Ge 4:5
--- ref1 chomp
Ge 2:5-Ex 6
--- ref2 chomp
Ge 4:5
--- result chomp
Ge 4:5

=== combine LCLCV,LCV - Ge 2-Ex 6:7, Ge 4:5
--- ref1 chomp
Ge 2-Ex 6:7
--- ref2 chomp
Ge 4:5
--- result chomp
Ge 4:5

=== combine LCLC,LCV - Ge 2-Ex 6, Ge 4:5
--- ref1 chomp
Ge 2-Ex 6
--- ref2 chomp
Ge 4:5
--- result chomp
Ge 4:5

=== combine LCCV,LCV - Ge 2-6:4, Ge 4:5
--- ref1 chomp
Ge 2-6:4
--- ref2 chomp
Ge 4:5
--- result chomp
Ge 4:5

=== combine LCC,LCV - Ge 3-9, Ge 4:5
--- ref1 chomp
Ge 3-9
--- ref2 chomp
Ge 4:5
--- result chomp
Ge 4:5

=== combine LCVCV,LCV - Ge 2:8-6:4, Ge 4:5
--- ref1 chomp
Ge 2:8-6:4
--- ref2 chomp
Ge 4:5
--- result chomp
Ge 4:5

=== combine LCVV,LCV - Ge 2:8-10, Ge 4:5
--- ref1 chomp
Ge 2:8-10
--- ref2 chomp
Ge 4:5
--- result chomp
Ge 4:5

=== combine LCV,LCV - Ge 4:5, Ge 4:5
--- ref1 chomp
Ge 4:5
--- ref2 chomp
Ge 4:5
--- result chomp
Ge 4:5

=== combine LC,LCV - Ge 12, Ge 4:5
--- ref1 chomp
Ge 12
--- ref2 chomp
Ge 4:5
--- result chomp
Ge 4:5

=== combine CCV,LCV - 12-13:5, Ge 4:5
--- ref1 chomp
12-13:5
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 4:5
--- result chomp
Ge 4:5

=== combine CC,LCV - 10-11, Ge 4:5
--- ref1 chomp
10-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 4:5
--- result chomp
Ge 4:5

=== combine CVCV,LCV - 1:5-3:11, Ge 4:5
--- ref1 chomp
1:5-3:11
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 4:5
--- result chomp
Ge 4:5

=== combine CVV,LCV - 9:5-11, Ge 4:5
--- ref1 chomp
9:5-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 4:5
--- result chomp
Ge 4:5

=== combine CV,LCV - 8:15, Ge 4:5
--- ref1 chomp
8:15
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 4:5
--- result chomp
Ge 4:5

=== combine C,LCV - 7, Ge 4:5
--- ref1 chomp
7
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 4:5
--- result chomp
Ge 4:5

=== combine VV,LCV - 8-14, Ge 4:5
--- ref1 chomp
8-14
--- ref1state chomp
VERSE
--- ref2 chomp
Ge 4:5
--- result chomp
Ge 4:5

=== combine V,LCV - 3, Ge 4:5
--- ref1 chomp
3
--- ref1state chomp
VERSE
--- ref2 chomp
Ge 4:5
--- result chomp
Ge 4:5




 
=== combine LCVLCV,LC - Ge 2:5-Ex 6:7, Ge 12
--- ref1 chomp
Ge 2:5-Ex 6:7
--- ref2 chomp
Ge 12
--- result chomp
Ge 12

=== combine LCVLC,LC - Ge 2:5-Ex 6, Ge 12
--- ref1 chomp
Ge 2:5-Ex 6
--- ref2 chomp
Ge 12
--- result chomp
Ge 12

=== combine LCLCV,LC - Ge 2-Ex 6:7, Ge 12
--- ref1 chomp
Ge 2-Ex 6:7
--- ref2 chomp
Ge 12
--- result chomp
Ge 12

=== combine LCLC,LC - Ge 2-Ex 6, Ge 12
--- ref1 chomp
Ge 2-Ex 6
--- ref2 chomp
Ge 12
--- result chomp
Ge 12

=== combine LCCV,LC - Ge 2-6:4, Ge 12
--- ref1 chomp
Ge 2-6:4
--- ref2 chomp
Ge 12
--- result chomp
Ge 12

=== combine LCC,LC - Ge 3-9, Ge 12
--- ref1 chomp
Ge 3-9
--- ref2 chomp
Ge 12
--- result chomp
Ge 12

=== combine LCVCV,LC - Ge 2:8-6:4, Ge 12
--- ref1 chomp
Ge 2:8-6:4
--- ref2 chomp
Ge 12
--- result chomp
Ge 12

=== combine LCVV,LC - Ge 2:8-10, Ge 12
--- ref1 chomp
Ge 2:8-10
--- ref2 chomp
Ge 12
--- result chomp
Ge 12

=== combine LCV,LC - Ge 4:5, Ge 12
--- ref1 chomp
Ge 4:5
--- ref2 chomp
Ge 12
--- result chomp
Ge 12

=== combine LC,LC - Ge 12, Ge 12
--- ref1 chomp
Ge 12
--- ref2 chomp
Ge 12
--- result chomp
Ge 12

=== combine CCV,LC - 12-13:5, Ge 12
--- ref1 chomp
12-13:5
--- ref2 chomp
Ge 12
--- result chomp
Ge 12

=== combine CC,LC - 10-11, Ge 12
--- ref1 chomp
10-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 12
--- result chomp
Ge 12

=== combine CVCV,LC - 1:5-3:11, Ge 12
--- ref1 chomp
1:5-3:11
--- ref2 chomp
Ge 12
--- result chomp
Ge 12

=== combine CVV,LC - 9:5-11, Ge 12
--- ref1 chomp
9:5-11
--- ref2 chomp
Ge 12
--- result chomp
Ge 12

=== combine CV,LC - 8:15, Ge 12
--- ref1 chomp
8:15
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 12
--- result chomp
Ge 12

=== combine C,LC - 7, Ge 12
--- ref1 chomp
7
--- ref1state chomp
CHAPTER
--- ref2 chomp
Ge 12
--- result chomp
Ge 12

=== combine VV,LC - 8-14, Ge 12
--- ref1 chomp
8-14
--- ref1state chomp
VERSE
--- ref2 chomp
Ge 12
--- result chomp
Ge 12

=== combine V,LC - 3, Ge 12
--- ref1 chomp
3
--- ref1state chomp
VERSE
--- ref2 chomp
Ge 12
--- result chomp
Ge 12

=== combine LCVLCV,CCV - Ge 2:5-Ex 6:7, 12-13:5
--- ref1 chomp
Ge 2:5-Ex 6:7
--- ref2 chomp
12-13:5
--- ref2state chomp
CHAPTER
--- result chomp
Ex 12-13:5

=== combine LCVLC,CCV - Ge 2:5-Ex 6, 12-13:5
--- ref1 chomp
Ge 2:5-Ex 6
--- ref2 chomp
12-13:5
--- ref2state chomp
CHAPTER
--- result chomp
Ex 12-13:5

=== combine LCLCV,CCV - Ge 2-Ex 6:7, 12-13:5
--- ref1 chomp
Ge 2-Ex 6:7
--- ref2 chomp
12-13:5
--- result chomp
Ex 12-13:5

=== combine LCLC,CCV - Ge 2-Ex 6, 12-13:5
--- ref1 chomp
Ge 2-Ex 6
--- ref2 chomp
12-13:5
--- ref2state chomp
CHAPTER
--- result chomp
Ex 12-13:5

=== combine LCCV,CCV - Ge 2-6:4, 12-13:5
--- ref1 chomp
Ge 2-6:4
--- ref2 chomp
12-13:5
--- result chomp
Ge 12-13:5

=== combine LCC,CCV - Ge 3-9, 12-13:5
--- ref1 chomp
Ge 3-9
--- ref2 chomp
12-13:5
--- ref2state chomp
CHAPTER
--- result chomp
Ge 12-13:5

=== combine LCVCV,CCV - Ge 2:8-6:4, 12-13:5
--- ref1 chomp
Ge 2:8-6:4
--- ref2 chomp
12-13:5
--- result chomp
Ge 12-13:5

=== combine LCVV,CCV - Ge 2:8-10, 12-13:5
--- ref1 chomp
Ge 2:8-10
--- ref2 chomp
12-13:5
--- ref2state chomp
CHAPTER
--- result chomp
Ge 12-13:5

=== combine LCV,CCV - Ge 4:5, 12-13:5
--- ref1 chomp
Ge 4:5
--- ref2 chomp
12-13:5
--- ref2state chomp
CHAPTER
--- result chomp
Ge 12-13:5

=== combine LC,CCV - Ge 12, 12-13:5
--- ref1 chomp
Ge 12
--- ref2 chomp
12-13:5
--- ref2state chomp
CHAPTER
--- result chomp
Ge 12-13:5

=== combine LCVLCV,CC - Ge 2:5-Ex 6:7, 10-11
--- ref1 chomp
Ge 2:5-Ex 6:7
--- ref2 chomp
10-11
--- ref2state chomp
CHAPTER
--- result chomp
Ex 10-11

=== combine LCVLC,CC - Ge 2:5-Ex 6, 10-11
--- ref1 chomp
Ge 2:5-Ex 6
--- ref2 chomp
10-11
--- ref2state chomp
CHAPTER
--- result chomp
Ex 10-11

=== combine LCLCV,CC - Ge 2-Ex 6:7, 10-11
--- ref1 chomp
Ge 2-Ex 6:7
--- ref2 chomp
10-11
--- ref2state chomp
CHAPTER
--- result chomp
Ex 10-11

=== combine LCLC,CC - Ge 2-Ex 6, 10-11
--- ref1 chomp
Ge 2-Ex 6
--- ref2 chomp
10-11
--- ref2state chomp
CHAPTER
--- result chomp
Ex 10-11

=== combine LCCV,CC - Ge 2-6:4, 10-11
--- ref1 chomp
Ge 2-6:4
--- ref2 chomp
10-11
--- ref2state chomp
CHAPTER
--- result chomp
Ge 10-11

=== combine LCC,CC - Ge 3-9, 10-11
--- ref1 chomp
Ge 3-9
--- ref2 chomp
10-11
--- ref2state chomp
CHAPTER
--- result chomp
Ge 10-11

=== combine LCVCV,CC - Ge 2:8-6:4, 10-11
--- ref1 chomp
Ge 2:8-6:4
--- ref2 chomp
10-11
--- ref2state chomp
CHAPTER
--- result chomp
Ge 10-11

=== combine LCVV,CC - Ge 2:8-10, 10-11
--- ref1 chomp
Ge 2:8-10
--- ref2 chomp
10-11
--- ref2state chomp
CHAPTER
--- result chomp
Ge 10-11

=== combine LCV,CC - Ge 4:5, 10-11
--- ref1 chomp
Ge 4:5
--- ref2 chomp
10-11
--- ref2state chomp
CHAPTER
--- result chomp
Ge 10-11

=== combine LC,CC - Ge 12, 10-11
--- ref1 chomp
Ge 12
--- ref2 chomp
10-11
--- ref2state chomp
CHAPTER
--- result chomp
Ge 10-11

=== combine CCV,CC - 12-13:5, 10-11
--- ref1 chomp
12-13:5
--- ref1state chomp
CHAPTER
--- ref2 chomp
10-11
--- ref2state chomp
CHAPTER
--- result chomp
10-11

=== combine CC,CC - 10-11, 10-11
--- ref1 chomp
10-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
10-11
--- ref2state chomp
CHAPTER
--- result chomp
10-11

=== combine CVCV,CC - 1:5-3:11, 10-11
--- ref1 chomp
1:5-3:11
--- ref1state chomp
CHAPTER
--- ref2 chomp
10-11
--- ref2state chomp
CHAPTER
--- result chomp
10-11

=== combine CVV,CC - 9:5-11, 10-11
--- ref1 chomp
9:5-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
10-11
--- ref2state chomp
CHAPTER
--- result chomp
10-11

=== combine CV,CC - 8:15, 10-11
--- ref1 chomp
8:15
--- ref1state chomp
CHAPTER
--- ref2 chomp
10-11
--- ref2state chomp
CHAPTER
--- result chomp
10-11

=== combine C,CC - 7, 10-11
--- ref1 chomp
7
--- ref1state chomp
CHAPTER
--- ref2 chomp
10-11
--- ref2state chomp
CHAPTER
--- result chomp
10-11

=== combine VV,CC - 8-14, 10-11
--- ref1 chomp
8-14
--- ref1state chomp
VERSE
--- ref2 chomp
10-11
--- ref2state chomp
CHAPTER
--- result chomp
10-11

=== combine V,CC - 3, 10-11
--- ref1 chomp
3
--- ref1state chomp
VERSE
--- ref2 chomp
10-11
--- ref2state chomp
CHAPTER
--- result chomp
10-11



=== combine LCVLCV,CVCV - Ge 2:5-Ex 6:7, 1:5-3:11
--- ref1 chomp
Ge 2:5-Ex 6:7
--- ref2 chomp
1:5-3:11
--- ref2state chomp
CHAPTER
--- result chomp
Ex 1:5-3:11

=== combine LCVLC,CVCV - Ge 2:5-Ex 6, 1:5-3:11
--- ref1 chomp
Ge 2:5-Ex 6
--- ref2 chomp
1:5-3:11
--- ref2state chomp
CHAPTER
--- result chomp
Ex 1:5-3:11

=== combine LCLCV,CVCV - Ge 2-Ex 6:7, 1:5-3:11
--- ref1 chomp
Ge 2-Ex 6:7
--- ref2 chomp
1:5-3:11
--- ref2state chomp
CHAPTER
--- result chomp
Ex 1:5-3:11

=== combine LCLC,CVCV - Ge 2-Ex 6, 1:5-3:11
--- ref1 chomp
Ge 2-Ex 6
--- ref2 chomp
1:5-3:11
--- ref2state chomp
CHAPTER
--- result chomp
Ex 1:5-3:11

=== combine LCCV,CVCV - Ge 2-6:4, 1:5-3:11
--- ref1 chomp
Ge 2-6:4
--- ref2 chomp
1:5-3:11
--- ref2state chomp
CHAPTER
--- result chomp
Ge 1:5-3:11

=== combine LCC,CVCV - Ge 3-9, 1:5-3:11
--- ref1 chomp
Ge 3-9
--- ref2 chomp
1:5-3:11
--- ref2state chomp
CHAPTER
--- result chomp
Ge 1:5-3:11

=== combine LCVCV,CVCV - Ge 2:8-6:4, 1:5-3:11
--- ref1 chomp
Ge 2:8-6:4
--- ref2 chomp
1:5-3:11
--- ref2state chomp
CHAPTER
--- result chomp
Ge 1:5-3:11

=== combine LCVV,CVCV - Ge 2:8-10, 1:5-3:11
--- ref1 chomp
Ge 2:8-10
--- ref2 chomp
1:5-3:11
--- ref2state chomp
CHAPTER
--- result chomp
Ge 1:5-3:11

=== combine LCV,CVCV - Ge 4:5, 1:5-3:11
--- ref1 chomp
Ge 4:5
--- ref2 chomp
1:5-3:11
--- ref2state chomp
CHAPTER
--- result chomp
Ge 1:5-3:11

=== combine LC,CVCV - Ge 12, 1:5-3:11
--- ref1 chomp
Ge 12
--- ref2 chomp
1:5-3:11
--- ref2state chomp
CHAPTER
--- result chomp
Ge 1:5-3:11

=== combine CCV,CVCV - 12-13:5, 1:5-3:11
--- ref1 chomp
12-13:5
--- ref1state chomp
CHAPTER
--- ref2 chomp
1:5-3:11
--- ref2state chomp
CHAPTER
--- result chomp
1:5-3:11

=== combine CC,CVCV - 10-11, 1:5-3:11
--- ref1 chomp
10-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
1:5-3:11
--- ref2state chomp
CHAPTER
--- result chomp
1:5-3:11

=== combine CVCV,CVCV - 1:5-3:11, 1:5-3:11
--- ref1 chomp
1:5-3:11
--- ref1state chomp
CHAPTER
--- ref2 chomp
1:5-3:11
--- ref2state chomp
CHAPTER
--- result chomp
1:5-3:11

=== combine CVV,CVCV - 9:5-11, 1:5-3:11
--- ref1 chomp
9:5-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
1:5-3:11
--- ref2state chomp
CHAPTER
--- result chomp
1:5-3:11

=== combine CV,CVCV - 8:15, 1:5-3:11
--- ref1 chomp
8:15
--- ref1state chomp
CHAPTER
--- ref2 chomp
1:5-3:11
--- ref2state chomp
CHAPTER
--- result chomp
1:5-3:11

=== combine C,CVCV - 7, 1:5-3:11
--- ref1 chomp
7
--- ref1state chomp
CHAPTER
--- ref2 chomp
1:5-3:11
--- ref2state chomp
CHAPTER
--- result chomp
1:5-3:11

=== combine VV,CVCV - 8-14, 1:5-3:11
--- ref1 chomp
8-14
--- ref1state chomp
VERSE
--- ref2 chomp
1:5-3:11
--- ref2state chomp
CHAPTER
--- result chomp
1:5-3:11

=== combine V,CVCV - 3, 1:5-3:11
--- ref1 chomp
3
--- ref1state chomp
VERSE
--- ref2 chomp
1:5-3:11
--- ref2state chomp
CHAPTER
--- result chomp
1:5-3:11


=== combine LCVLCV,CVV - Ge 2:5-Ex 6:7, 9:5-11
--- ref1 chomp
Ge 2:5-Ex 6:7
--- ref2 chomp
9:5-11
--- ref2state chomp
CHAPTER
--- result chomp
Ex 9:5-11

=== combine LCVLC,CVV - Ge 2:5-Ex 6, 9:5-11
--- ref1 chomp
Ge 2:5-Ex 6
--- ref2 chomp
9:5-11
--- ref2state chomp
CHAPTER
--- result chomp
Ex 9:5-11

=== combine LCLCV,CVV - Ge 2-Ex 6:7, 9:5-11
--- ref1 chomp
Ge 2-Ex 6:7
--- ref2 chomp
9:5-11
--- ref2state chomp
CHAPTER
--- result chomp
Ex 9:5-11

=== combine LCLC,CVV - Ge 2-Ex 6, 9:5-11
--- ref1 chomp
Ge 2-Ex 6
--- ref2 chomp
9:5-11
--- ref2state chomp
CHAPTER
--- result chomp
Ex 9:5-11

=== combine LCCV,CVV - Ge 2-6:4, 9:5-11
--- ref1 chomp
Ge 2-6:4
--- ref2 chomp
9:5-11
--- ref2state chomp
CHAPTER
--- result chomp
Ge 9:5-11

=== combine LCC,CVV - Ge 3-9, 9:5-11
--- ref1 chomp
Ge 3-9
--- ref2 chomp
9:5-11
--- ref2state chomp
CHAPTER
--- result chomp
Ge 9:5-11

=== combine LCVCV,CVV - Ge 2:8-6:4, 9:5-11
--- ref1 chomp
Ge 2:8-6:4
--- ref2 chomp
9:5-11
--- ref2state chomp
CHAPTER
--- result chomp
Ge 9:5-11

=== combine LCVV,CVV - Ge 2:8-10, 9:5-11
--- ref1 chomp
Ge 2:8-10
--- ref2 chomp
9:5-11
--- ref1state chomp
CHAPTER
--- result chomp
Ge 9:5-11

=== combine LCV,CVV - Ge 4:5, 9:5-11
--- ref1 chomp
Ge 4:5
--- ref2 chomp
9:5-11
--- ref2state chomp
CHAPTER
--- result chomp
Ge 9:5-11

=== combine LC,CVV - Ge 12, 9:5-11
--- ref1 chomp
Ge 12
--- ref2 chomp
9:5-11
--- ref2state chomp
CHAPTER
--- result chomp
Ge 9:5-11

=== combine CCV,CVV - 12-13:5, 9:5-11
--- ref1 chomp
12-13:5
--- ref1state chomp
CHAPTER
--- ref2 chomp
9:5-11
--- ref2state chomp
CHAPTER
--- result chomp
9:5-11

=== combine CC,CVV - 10-11, 9:5-11
--- ref1 chomp
10-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
9:5-11
--- ref2state chomp
CHAPTER
--- result chomp
9:5-11

=== combine CVCV,CVV - 1:5-3:11, 9:5-11
--- ref1 chomp
1:5-3:11
--- ref1state chomp
CHAPTER
--- ref2 chomp
9:5-11
--- ref2state chomp
CHAPTER
--- result chomp
9:5-11

=== combine CVV,CVV - 9:5-11, 9:5-11
--- ref1 chomp
9:5-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
9:5-11
--- ref2state chomp
CHAPTER
--- result chomp
9:5-11

=== combine CV,CVV - 8:15, 9:5-11
--- ref1 chomp
8:15
--- ref1state chomp
CHAPTER
--- ref2 chomp
9:5-11
--- ref2state chomp
CHAPTER
--- result chomp
9:5-11

=== combine C,CVV - 7, 9:5-11
--- ref1 chomp
7
--- ref1state chomp
CHAPTER
--- ref2 chomp
9:5-11
--- ref2state chomp
CHAPTER
--- result chomp
9:5-11

=== combine VV,CVV - 8-14, 9:5-11
--- ref1 chomp
8-14
--- ref1state chomp
VERSE
--- ref2 chomp
9:5-11
--- ref2state chomp
CHAPTER
--- result chomp
9:5-11

=== combine V,CVV - 3, 9:5-11
--- ref1 chomp
3
--- ref1state chomp
VERSE
--- ref2 chomp
9:5-11
--- ref2state chomp
CHAPTER
--- result chomp
9:5-11



=== combine LCVLCV,CV - Ge 2:5-Ex 6:7, 8:15
--- ref1 chomp
Ge 2:5-Ex 6:7
--- ref2 chomp
8:15
--- ref2state chomp
CHAPTER
--- result chomp
Ex 8:15

=== combine LCVLC,CV - Ge 2:5-Ex 6, 8:15
--- ref1 chomp
Ge 2:5-Ex 6
--- ref2 chomp
8:15
--- ref2state chomp
CHAPTER
--- result chomp
Ex 8:15

=== combine LCLCV,CV - Ge 2-Ex 6:7, 8:15
--- ref1 chomp
Ge 2-Ex 6:7
--- ref2 chomp
8:15
--- ref2state chomp
CHAPTER
--- result chomp
Ex 8:15

=== combine LCLC,CV - Ge 2-Ex 6, 8:15
--- ref1 chomp
Ge 2-Ex 6
--- ref2 chomp
8:15
--- ref2state chomp
CHAPTER
--- result chomp
Ex 8:15

=== combine LCCV,CV - Ge 2-6:4, 8:15
--- ref1 chomp
Ge 2-6:4
--- ref2 chomp
8:15
--- ref2state chomp
CHAPTER
--- result chomp
Ge 8:15

=== combine LCC,CV - Ge 3-9, 8:15
--- ref1 chomp
Ge 3-9
--- ref2 chomp
8:15
--- ref2state chomp
CHAPTER
--- result chomp
Ge 8:15

=== combine LCVCV,CV - Ge 2:8-6:4, 8:15
--- ref1 chomp
Ge 2:8-6:4
--- ref2 chomp
8:15
--- ref2state chomp
CHAPTER
--- result chomp
Ge 8:15

=== combine LCVV,CV - Ge 2:8-10, 8:15
--- ref1 chomp
Ge 2:8-10
--- ref2 chomp
8:15
--- ref2state chomp
CHAPTER
--- result chomp
Ge 8:15

=== combine LCV,CV - Ge 4:5, 8:15
--- ref1 chomp
Ge 4:5
--- ref2 chomp
8:15
--- ref2state chomp
CHAPTER
--- result chomp
Ge 8:15

=== combine LC,CV - Ge 12, 8:15
--- ref1 chomp
Ge 12
--- ref2 chomp
8:15
--- ref2state chomp
CHAPTER
--- result chomp
Ge 8:15

=== combine CCV,CV - 12-13:5, 8:15
--- ref1 chomp
12-13:5
--- ref1state chomp
CHAPTER
--- ref2 chomp
8:15
--- ref2state chomp
CHAPTER
--- result chomp
8:15

=== combine CC,CV - 10-11, 8:15
--- ref1 chomp
10-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
8:15
--- ref2state chomp
CHAPTER
--- result chomp
8:15

=== combine CVCV,CV - 1:5-3:11, 8:15
--- ref1 chomp
1:5-3:11
--- ref1state chomp
CHAPTER
--- ref2 chomp
8:15
--- result chomp
8:15

=== combine CVV,CV - 9:5-11, 8:15
--- ref1 chomp
9:5-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
8:15
--- ref2state chomp
CHAPTER
--- result chomp
8:15

=== combine CV,CV - 8:15, 8:15
--- ref1 chomp
8:15
--- ref1state chomp
CHAPTER
--- ref2 chomp
8:15
--- ref2state chomp
CHAPTER
--- result chomp
8:15

=== combine C,CV - 7, 8:15
--- ref1 chomp
7
--- ref1state chomp
CHAPTER
--- ref2 chomp
8:15
--- result chomp
8:15

=== combine VV,CV - 8-14, 8:15
--- ref1 chomp
8-14
--- ref1state chomp
VERSE
--- ref2 chomp
8:15
--- ref2state chomp
CHAPTER
--- result chomp
8:15

=== combine V,CV - 3, 8:15
--- ref1 chomp
3
--- ref1state chomp
VERSE
--- ref2 chomp
8:15
--- ref2state chomp
CHAPTER
--- result chomp
8:15



 
=== combine LCVLCV,C - Ge 2:5-Ex 6:7, 7
--- ref1 chomp
Ge 2:5-Ex 6:7
--- ref2 chomp
7
--- ref2state chomp
CHAPTER
--- result chomp
Ex 7

=== combine LCVLC,C - Ge 2:5-Ex 6, 7
--- ref1 chomp
Ge 2:5-Ex 6
--- ref2 chomp
7
--- ref2state chomp
CHAPTER
--- result chomp
Ex 7

=== combine LCLCV,C - Ge 2-Ex 6:7, 7
--- ref1 chomp
Ge 2-Ex 6:7
--- ref2 chomp
7
--- ref2state chomp
CHAPTER
--- result chomp
Ex 7

=== combine LCLC,C - Ge 2-Ex 6, 7
--- ref1 chomp
Ge 2-Ex 6
--- ref2 chomp
7
--- ref2state chomp
CHAPTER
--- result chomp
Ex 7

=== combine LCCV,C - Ge 2-6:4, 7
--- ref1 chomp
Ge 2-6:4
--- ref2 chomp
7
--- ref2state chomp
CHAPTER
--- result chomp
Ge 7

=== combine LCC,C - Ge 3-9, 7
--- ref1 chomp
Ge 3-9
--- ref2 chomp
7
--- ref2state chomp
CHAPTER
--- result chomp
Ge 7

=== combine LCVCV,C - Ge 2:8-6:4, 7
--- ref1 chomp
Ge 2:8-6:4
--- ref2 chomp
7
--- ref2state chomp
CHAPTER
--- result chomp
Ge 7

=== combine LCVV,C - Ge 2:8-10, 7
--- ref1 chomp
Ge 2:8-10
--- ref2 chomp
7
--- ref2state chomp
CHAPTER
--- result chomp
Ge 7

=== combine LCV,C - Ge 4:5, 7
--- ref1 chomp
Ge 4:5
--- ref2 chomp
7
--- ref2state chomp
CHAPTER
--- result chomp
Ge 7

=== combine LC,C - Ge 12, 7
--- ref1 chomp
Ge 12
--- ref2 chomp
7
--- ref2state chomp
CHAPTER
--- result chomp
Ge 7

=== combine CCV,C - 12-13:5, 7
--- ref1 chomp
12-13:5
--- ref1state chomp
CHAPTER
--- ref2 chomp
7
--- ref2state chomp
CHAPTER
--- result chomp
7

=== combine CC,C - 10-11, 7
--- ref1 chomp
10-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
7
--- ref2state chomp
CHAPTER
--- result chomp
7

=== combine CVCV,C - 1:5-3:11, 7
--- ref1 chomp
1:5-3:11
--- ref1state chomp
CHAPTER
--- ref2 chomp
7
--- ref2state chomp
CHAPTER
--- result chomp
7

=== combine CVV,C - 9:5-11, 7
--- ref1 chomp
9:5-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
7
--- ref2state chomp
CHAPTER
--- result chomp
7

=== combine CV,C - 8:15, 7
--- ref1 chomp
8:15
--- ref1state chomp
CHAPTER
--- ref2 chomp
7
--- ref2state chomp
CHAPTER
--- result chomp
7

=== combine C,C - 7, 7
--- ref1 chomp
7
--- ref1state chomp
VERSE
--- ref2 chomp
7
--- ref2state chomp
CHAPTER
--- result chomp
7

=== combine VV,C - 8-14, 7
--- ref1 chomp
8-14
--- ref1state chomp
VERSE
--- ref2 chomp
7
--- ref2state chomp
CHAPTER
--- result chomp
7

=== combine V,C - 3, 7
--- ref1 chomp
3
--- ref1state chomp
VERSE
--- ref2 chomp
7
--- ref2state chomp
CHAPTER
--- result chomp
7



=== combine LCVLCV,VV - Ge 2:5-Ex 6:7, 8-14
--- ref1 chomp
Ge 2:5-Ex 6:7
--- ref2 chomp
8-14
--- ref2state chomp
VERSE
--- result chomp
Ex 6:8-14

=== combine LCVLC,VV - Ge 2:5-Ex 6, 8-14
--- ref1 chomp
Ge 2:5-Ex 6
--- ref2 chomp
8-14
--- ref2state chomp
VERSE
--- result chomp
Ex 6:8-14

=== combine LCLCV,VV - Ge 2-Ex 6:7, 8-14
--- ref1 chomp
Ge 2-Ex 6:7
--- ref2 chomp
8-14
--- ref2state chomp
VERSE
--- result chomp
Ex 6:8-14

=== combine LCLC,VV - Ge 2-Ex 6, 8-14
--- ref1 chomp
Ge 2-Ex 6
--- ref2 chomp
8-14
--- ref2state chomp
VERSE
--- result chomp
Ex 6:8-14

=== combine LCCV,VV - Ge 2-6:4, 8-14
--- ref1 chomp
Ge 2-6:4
--- ref2 chomp
8-14
--- ref2state chomp
VERSE
--- result chomp
Ge 6:8-14

=== combine LCC,VV - Ge 3-9, 8-14
--- ref1 chomp
Ge 3-9
--- ref2 chomp
8-14
--- ref2state chomp
VERSE
--- result chomp
Ge 9:8-14

=== combine LCVCV,VV - Ge 2:8-6:4, 8-14
--- ref1 chomp
Ge 2:8-6:4
--- ref2 chomp
8-14
--- ref2state chomp
VERSE
--- result chomp
Ge 6:8-14

=== combine LCVV,VV - Ge 2:8-10, 8-14
--- ref1 chomp
Ge 2:8-10
--- ref2 chomp
8-14
--- ref2state chomp
VERSE
--- result chomp
Ge 2:8-14

=== combine LCV,VV - Ge 4:5, 8-14
--- ref1 chomp
Ge 4:5
--- ref2 chomp
8-14
--- ref2state chomp
VERSE
--- result chomp
Ge 4:8-14

=== combine LC,VV - Ge 12, 8-14
--- ref1 chomp
Ge 12
--- ref2 chomp
8-14
--- ref2state chomp
VERSE
--- result chomp
Ge 12:8-14

=== combine CCV,VV - 12-13:5, 8-14
--- ref1 chomp
12-13:5
--- ref1state chomp
CHAPTER
--- ref2 chomp
8-14
--- ref2state chomp
VERSE
--- result chomp
13:8-14

=== combine CC,VV - 10-11, 8-14
--- ref1 chomp
10-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
8-14
--- ref2state chomp
VERSE
--- result chomp
11:8-14

=== combine CVCV,VV - 1:5-3:11, 8-14
--- ref1 chomp
1:5-3:11
--- ref1state chomp
CHAPTER
--- ref2 chomp
8-14
--- ref2state chomp
VERSE
--- result chomp
3:8-14

=== combine CVV,VV - 9:5-11, 8-14
--- ref1 chomp
9:5-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
8-14
--- ref2state chomp
VERSE
--- result chomp
9:8-14

=== combine CV,VV - 8:15, 8-14
--- ref1 chomp
8:15
--- ref1state chomp
CHAPTER
--- ref2 chomp
8-14
--- ref2state chomp
VERSE
--- result chomp
8:8-14

=== combine C,VV - 7, 8-14
--- ref1 chomp
7
--- ref1state chomp
CHAPTER
--- ref2 chomp
8-14
--- ref2state chomp
VERSE
--- result chomp
7:8-14

=== combine VV,VV - 8-14, 8-14
--- ref1 chomp
8-14
--- ref1state chomp
VERSE
--- ref2 chomp
8-14
--- ref2state chomp
VERSE
--- result chomp
8-14

=== combine V,VV - 3, 8-14
--- ref1 chomp
3
--- ref1state chomp
VERSE
--- ref2 chomp
8-14
--- ref2state chomp
VERSE
--- result chomp
8-14

 
 
=== combine LCVLCV,V - Ge 2:5-Ex 6:7, 3
--- ref1 chomp
Ge 2:5-Ex 6:7
--- ref2 chomp
3
--- ref2state chomp
VERSE
--- result chomp
Ex 6:3

=== combine LCVLC,V - Ge 2:5-Ex 6, 3
--- ref1 chomp
Ge 2:5-Ex 6
--- ref2 chomp
3
--- ref2state chomp
VERSE
--- result chomp
Ex 6:3

=== combine LCLCV,V - Ge 2-Ex 6:7, 3
--- ref1 chomp
Ge 2-Ex 6:7
--- ref2 chomp
3
--- ref2state chomp
VERSE
--- result chomp
Ex 6:3

=== combine LCLC,V - Ge 2-Ex 6, 3
--- ref1 chomp
Ge 2-Ex 6
--- ref2 chomp
3
--- ref2state chomp
VERSE
--- result chomp
Ex 6:3

=== combine LCVLCV, V - Ge 2:5-Ex 6:7, 3
--- ref1 chomp
Ge 2:5-Ex 6:7
--- ref2 chomp
3
--- ref2state chomp
VERSE
--- result chomp
Ex 6:3

=== combine LCCV,V - Ge 2-6:4, 3
--- ref1 chomp
Ge 2-6:4
--- ref2 chomp
3
--- ref2state chomp
VERSE
--- result chomp
Ge 6:3

=== combine LCC,V - Ge 3-9, 3
--- ref1 chomp
Ge 3-9
--- ref2 chomp
3
--- ref2state chomp
VERSE
--- result chomp
Ge 9:3

=== combine LCVCV,V - Ge 2:8-6:4, 3
--- ref1 chomp
Ge 2:8-6:4
--- ref2 chomp
3
--- ref2state chomp
VERSE
--- result chomp
Ge 6:3

=== combine LCVV,V - Ge 2:8-10, 3
--- ref1 chomp
Ge 2:8-10
--- ref2 chomp
3
--- ref2state chomp
VERSE
--- result chomp
Ge 2:3

=== combine LCV,V - Ge 4:5, 3
--- ref1 chomp
Ge 4:5
--- ref2 chomp
3
--- ref2state chomp
VERSE
--- result chomp
Ge 4:3

=== combine LC,V - Ge 12, 3
--- ref1 chomp
Ge 12
--- ref2 chomp
3
--- ref2state chomp
VERSE
--- result chomp
Ge 12:3

=== combine CCV,V - 12-13:5, 3
--- ref1 chomp
12-13:5
--- ref1state chomp
CHAPTER
--- ref2 chomp
3
--- ref2state chomp
VERSE
--- result chomp
13:3

=== combine CC,V - 10-11, 3
--- ref1 chomp
10-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
3
--- ref2state chomp
VERSE
--- result chomp
11:3

=== combine CVCV,V - 1:5-3:11, 3
--- ref1 chomp
1:5-3:11
--- ref1state chomp
CHAPTER
--- ref2 chomp
3
--- ref2state chomp
VERSE
--- result chomp
3:3

=== combine CVV,V - 9:5-11, 3
--- ref1 chomp
9:5-11
--- ref1state chomp
CHAPTER
--- ref2 chomp
3
--- ref2state chomp
VERSE
--- result chomp
9:3

=== combine CV,V - 8:15, 3
--- ref1 chomp
8:15
--- ref1state chomp
CHAPTER
--- ref2 chomp
3
--- ref2state chomp
VERSE
--- result chomp
8:3

=== combine C,V - 7, 3
--- ref1 chomp
7
--- ref1state chomp
CHAPTER
--- ref2 chomp
3
--- ref2state chomp
VERSE
--- result chomp
7:3

=== combine VV,V - 8-14, 3
--- ref1 chomp
8-14
--- ref1state chomp
VERSE
--- ref2 chomp
3
--- ref2state chomp
VERSE
--- result chomp
3

=== combine V,V - 3, 3
--- ref1 chomp
3
--- ref1state chomp
VERSE
--- ref2 chomp
3
--- ref2state chomp
VERSE
--- result chomp
3

 





























