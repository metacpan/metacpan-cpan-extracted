use t::TestConfig;
use utf8;
use Data::Dumper;
no warnings;

plan tests => 30;
    
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
  19: 
    Match:
      Book: ['Psaumes', 'Psaume', 'psaumes', 'psaume']
      Abbreviation: ['Ps']
    Normalized: 
      Book: Psaume
      Abbreviation: Ps

regex:
  livres_avec_un_chapitre: (?:Ab|Abdias|2Jn|2Jean|Phm|Philemon|Philémon|Jud|Jude|3Jn|3Jean)

YAML

my $c = new Religion::Bible::Regex::Config($yaml); 
my $b = new Religion::Bible::Regex::Builder($c);

run {
    my $block = shift;
    my $r1 = new Religion::Bible::Regex::Reference($c, $b);	
    my $r2 = new Religion::Bible::Regex::Reference($c, $b);	
    
    $r1->parse($block->ref1, $block->state);    
    $r2->parse($block->ref2, $block->state);    
    my $i = $r1->interval($r2);

    is($r1->interval($r2)->formatted_normalize, $block->expect, $block->name);
};

#__END__
# === 1 begin_interval_reference LCLCVV - Ge 1-Ex 2:5, LCVLCV - Lé 5:6-De 7:8 - after, after
# --- ref2 chomp
# Ge 1-Ex 2:5
# --- ref1 chomp
# Lé 5:6-De 7:8
# --- expect chomp 
# Ge 1-De 7:8
# === 2 begin_interval_reference LCLC - Ge 1-Ex 2, LCVLCV - Lé 5:6-De 7:8 - after, after
# --- ref2 chomp
# Ge 1-Ex 2
# --- ref1 chomp
# Lé 5:6-De 7:8
# --- expect chomp
# Ge 1-De 7:8
# === 3 begin_interval_reference LC - Ge 1, LCVLCV - Lé 5:6-De 7:8 - after, after
# --- ref2 chomp
# Ge 1
# --- ref1 chomp
# Lé 5:6-De 7:8
# --- expect chomp
# Ge 1-De 7:8
# === 4 begin_interval_reference LCVCV - Ge 1:1-2:5, LCVLCV - Lé 5:6-De 7:8 - after, after
# --- ref2 chomp
# Ge 1:1-2:5
# --- ref1 chomp
# Lé 5:6-De 7:8
# --- expect chomp
# Ge 1:1-De 7:8
# === 5 begin_interval_reference LCCV - Ge 1-2:5, LCVLCV - Lé 5:6-De 7:8 - after, after
# --- ref2 chomp
# Ge 1-2:5
# --- ref1 chomp
# Lé 5:6-De 7:8
# --- expect chomp 
# Ge 1-De 7:8
# === 6 begin_interval_reference LCC - Ge 1-2, LCVLCV - Lé 5:6-De 7:8 - after, after
# --- ref2 chomp
# Ge 1-2
# --- ref1 chomp
# Lé 5:6-De 7:8
# --- expect chomp
# Ge 1-De 7:8
# === 7 begin_interval_reference LC - Ge 1, LCVLCV - Lé 5:6-De 7:8 - after, after
# --- ref2 chomp
# Ge 1
# --- ref1 chomp
# Lé 5:6-De 7:8
# --- expect chomp
# Ge 1-De 7:8



# === 8 begin_interval_reference LCLCVV - Ge 1-Ex 2:5, LCVLC- Lé 5:6-De 7 - after, after
# --- ref2 chomp
# Ge 1-Ex 2:5
# --- ref1 chomp
# Lé 5:6-De 7
# --- expect chomp 
# Ge 1-De 7
# === 9 begin_interval_reference LCLC - Ge 1-Ex 2, LCVLC- Lé 5:6-De 7 - after, after
# --- ref2 chomp
# Ge 1-Ex 2
# --- ref1 chomp
# Lé 5:6-De 7
# --- expect chomp
# Ge 1-De 7
# === 10 begin_interval_reference LC - Ge 1, LCVLC- Lé 5:6-De 7 - after, after
# --- ref2 chomp
# Ge 1
# --- ref1 chomp
# Lé 5:6-De 7
# --- expect chomp
# Ge 1-De 7
# === 11 begin_interval_reference LCVCV - Ge 1:1-2:5, LCVLC- Lé 5:6-De 7 - after, after
# --- ref2 chomp
# Ge 1:1-2:5
# --- ref1 chomp
# Lé 5:6-De 7
# --- expect chomp
# Ge 1:1-De 7
# === 12 begin_interval_reference LCCV - Ge 1-2:5, LCVLC- Lé 5:6-De 7 - after, after
# --- ref2 chomp
# Ge 1-2:5
# --- ref1 chomp
# Lé 5:6-De 7
# --- expect chomp 
# Ge 1-De 7
# === 13 begin_interval_reference LCC - Ge 1-2, LCVLC- Lé 5:6-De 7 - after, after
# --- ref2 chomp
# Ge 1-2
# --- ref1 chomp
# Lé 5:6-De 7
# --- expect chomp
# Ge 1-De 7
# === 14 begin_interval_reference LC - Ge 1, LCVLC- Lé 5:6-De 7 - after, after
# --- ref2 chomp
# Ge 1
# --- ref1 chomp
# Lé 5:6-De 7
# --- expect chomp
# Ge 1-De 7





# === begin_interval_reference LCLCVV - Ge 1-Ex 2:5, LCLC - Lé 5:6-De 7 - after, after
# --- ref2 chomp
# Ge 1-Ex 2:5
# --- ref1 chomp
# Lé 5:6-De 7
# --- expect chomp 
# Ge 1-De 7
# === begin_interval_reference LCLC - Ge 1-Ex 2, LCLC - Lé 5:6-De 7 - after, after
# --- ref2 chomp
# Ge 1-Ex 2
# --- ref1 chomp
# Lé 5:6-De 7
# --- expect chomp
# Ge 1-De 7
# === begin_interval_reference LC - Ge 1, LCLC - Lé 5:6-De 7 - after, after
# --- ref2 chomp
# Ge 1
# --- ref1 chomp
# Lé 5:6-De 7
# --- expect chomp
# Ge 1-De 7
# === begin_interval_reference LCVCV - Ge 1:1-2:5, LCLC - Lé 5:6-De 7 - after, after
# --- ref2 chomp
# Ge 1:1-2:5
# --- ref1 chomp
# Lé 5:6-De 7
# --- expect chomp
# Ge 1:1-De 7
# === begin_interval_reference LCCV - Ge 1-2:5, LCLC - Lé 5:6-De 7 - after, after
# --- ref2 chomp
# Ge 1-2:5
# --- ref1 chomp
# Lé 5:6-De 7
# --- expect chomp 
# Ge 1-De 7
# === begin_interval_reference LCC - Ge 1-2, LCLC - Lé 5:6-De 7 - after, after
# --- ref2 chomp
# Ge 1-2
# --- ref1 chomp
# Lé 5:6-De 7
# --- expect chomp
# Ge 1-De 7
# === begin_interval_reference LC - Ge 1, LCLC - Lé 5:6-De 7 - after, after
# --- ref2 chomp
# Ge 1
# --- ref1 chomp
# Lé 5:6-De 7
# --- expect chomp
# Ge 1-De 7



# === begin_interval_reference LCLCVV - Ge 1-Ex 2:5, LCLCV - Lé 5-De 7:8 - after, after
# --- ref2 chomp
# Ge 1-Ex 2:5
# --- ref1 chomp
# Lé 5-De 7:8
# --- expect chomp 
# Ge 1-De 7:8
# === begin_interval_reference LCLC - Ge 1-Ex 2, LCLCV - Lé 5-De 7:8 - after, after
# --- ref2 chomp
# Ge 1-Ex 2
# --- ref1 chomp
# Lé 5-De 7:8
# --- expect chomp
# Ge 1-De 7:8
# === begin_interval_reference LC - Ge 1, LCLCV - Lé 5-De 7:8 - after, after
# --- ref2 chomp
# Ge 1
# --- ref1 chomp
# Lé 5-De 7:8
# --- expect chomp
# Ge 1-De 7:8
# === begin_interval_reference LCVCV - Ge 1:1-2:5, LCLCV - Lé 5-De 7:8 - after, after
# --- ref2 chomp
# Ge 1:1-2:5
# --- ref1 chomp
# Lé 5-De 7:8
# --- expect chomp
# Ge 1:1-De 7:8
# === begin_interval_reference LCCV - Ge 1-2:5, LCLCV - Lé 5-De 7:8 - after, after
# --- ref2 chomp
# Ge 1-2:5
# --- ref1 chomp
# Lé 5-De 7:8
# --- expect chomp 
# Ge 1-De 7:8
# === begin_interval_reference LCC - Ge 1-2, LCLCV - Lé 5-De 7:8 - after, after
# --- ref2 chomp
# Ge 1-2
# --- ref1 chomp
# Lé 5-De 7:8
# --- expect chomp
# Ge 1-De 7:8
# === 28 begin_interval_reference LC - Ge 1, LCLCV - Lé 5-De 7:8 - after, after
# --- ref2 chomp
# Ge 1
# --- ref1 chomp
# Lé 5-De 7:8
# --- expect chomp
# Ge 1-De 7:8

__END__
=== begin_interval_reference LCV - Ps 1:3, LCV - Ps 1:4
--- ref1 chomp
Ps 1:3
--- ref2 chomp
Ps 1:4
--- expect chomp 
Ps 1:3-4

=== begin_interval_reference LCV - Ge 1:1, LCV - Ge 1:1
--- ref1 chomp
Ge 1:1
--- ref2 chomp
Ge 1:1
--- expect chomp 
Ge 1:1


































=== begin_interval_reference LCLCVV - Ge 1-Ex 2:5, LCVLCV - Lé 5:6-De 7:8, - before, before
--- ref1 chomp
Ge 1-Ex 2:5
--- ref2 chomp
Lé 5:6-De 7:8
--- expect chomp 
Ge 1-De 7:8
=== begin_interval_reference LCLC - Ge 1-Ex 2, LCVLCV - Lé 5:6-De 7:8, - before, before
--- ref1 chomp
Ge 1-Ex 2
--- ref2 chomp
Lé 5:6-De 7:8
--- expect chomp
Ge 1-De 7:8
=== begin_interval_reference LC - Ge 1, LCVLCV - Lé 5:6-De 7:8, - before, before
--- ref1 chomp
Ge 1
--- ref2 chomp
Lé 5:6-De 7:8
--- expect chomp
Ge 1-De 7:8
=== begin_interval_reference LCVCV - Ge 1:1-2:5, LCVLCV - Lé 5:6-De 7:8, - before, before
--- ref1 chomp
Ge 1:1-2:5
--- ref2 chomp
Lé 5:6-De 7:8
--- expect chomp
Ge 1:1-De 7:8
=== begin_interval_reference LCCV - Ge 1-2:5, LCVLCV - Lé 5:6-De 7:8, - before, before
--- ref1 chomp
Ge 1-2:5
--- ref2 chomp
Lé 5:6-De 7:8
--- expect chomp 
Ge 1-De 7:8
=== begin_interval_reference LCC - Ge 1-2, LCVLCV - Lé 5:6-De 7:8, - before, before
--- ref1 chomp
Ge 1-2
--- ref2 chomp
Lé 5:6-De 7:8
--- expect chomp
Ge 1-De 7:8
=== begin_interval_reference LC - Ge 1, LCVLCV - Lé 5:6-De 7:8, - before, before
--- ref1 chomp
Ge 1
--- ref2 chomp
Lé 5:6-De 7:8
--- expect chomp
Ge 1-De 7:8



=== begin_interval_reference LCLCVV - Ge 1-Ex 2:5, LCVLC- Lé 5:6-De 7, - before, before
--- ref1 chomp
Ge 1-Ex 2:5
--- ref2 chomp
Lé 5:6-De 7
--- expect chomp 
Ge 1-De 7
=== begin_interval_reference LCLC - Ge 1-Ex 2, LCVLC- Lé 5:6-De 7, - before, before
--- ref1 chomp
Ge 1-Ex 2
--- ref2 chomp
Lé 5:6-De 7
--- expect chomp
Ge 1-De 7
=== begin_interval_reference LC - Ge 1, LCVLC- Lé 5:6-De 7, - before, before
--- ref1 chomp
Ge 1
--- ref2 chomp
Lé 5:6-De 7
--- expect chomp
Ge 1-De 7
=== begin_interval_reference LCVCV - Ge 1:1-2:5, LCVLC- Lé 5:6-De 7, - before, before
--- ref1 chomp
Ge 1:1-2:5
--- ref2 chomp
Lé 5:6-De 7
--- expect chomp
Ge 1:1-De 7
=== begin_interval_reference LCCV - Ge 1-2:5, LCVLC- Lé 5:6-De 7, - before, before
--- ref1 chomp
Ge 1-2:5
--- ref2 chomp
Lé 5:6-De 7
--- expect chomp 
Ge 1-De 7
=== begin_interval_reference LCC - Ge 1-2, LCVLC- Lé 5:6-De 7, - before, before
--- ref1 chomp
Ge 1-2
--- ref2 chomp
Lé 5:6-De 7
--- expect chomp
Ge 1-De 7
=== begin_interval_reference LC - Ge 1, LCVLC- Lé 5:6-De 7, - before, before
--- ref1 chomp
Ge 1
--- ref2 chomp
Lé 5:6-De 7
--- expect chomp
Ge 1-De 7





=== begin_interval_reference LCLCVV - Ge 1-Ex 2:5, LCLC - Lé 5:6-De 7, - before, before
--- ref1 chomp
Ge 1-Ex 2:5
--- ref2 chomp
Lé 5:6-De 7
--- expect chomp 
Ge 1-De 7
=== begin_interval_reference LCLC - Ge 1-Ex 2, LCLC - Lé 5:6-De 7, - before, before
--- ref1 chomp
Ge 1-Ex 2
--- ref2 chomp
Lé 5:6-De 7
--- expect chomp
Ge 1-De 7
=== begin_interval_reference LC - Ge 1, LCLC - Lé 5:6-De 7, - before, before
--- ref1 chomp
Ge 1
--- ref2 chomp
Lé 5:6-De 7
--- expect chomp
Ge 1-De 7
=== begin_interval_reference LCVCV - Ge 1:1-2:5, LCLC - Lé 5:6-De 7, - before, before
--- ref1 chomp
Ge 1:1-2:5
--- ref2 chomp
Lé 5:6-De 7
--- expect chomp
Ge 1:1-De 7
=== begin_interval_reference LCCV - Ge 1-2:5, LCLC - Lé 5:6-De 7, - before, before
--- ref1 chomp
Ge 1-2:5
--- ref2 chomp
Lé 5:6-De 7
--- expect chomp 
Ge 1-De 7
=== begin_interval_reference LCC - Ge 1-2, LCLC - Lé 5:6-De 7, - before, before
--- ref1 chomp
Ge 1-2
--- ref2 chomp
Lé 5:6-De 7
--- expect chomp
Ge 1-De 7
=== begin_interval_reference LC - Ge 1, LCLC - Lé 5:6-De 7, - before, before
--- ref1 chomp
Ge 1
--- ref2 chomp
Lé 5:6-De 7
--- expect chomp
Ge 1-De 7



=== begin_interval_reference LCLCVV - Ge 1-Ex 2:5, LCLCV - Lé 5-De 7:8, - before, before
--- ref1 chomp
Ge 1-Ex 2:5
--- ref2 chomp
Lé 5-De 7:8
--- expect chomp 
Ge 1-De 7:8
=== begin_interval_reference LCLC - Ge 1-Ex 2, LCLCV - Lé 5-De 7:8, - before, before
--- ref1 chomp
Ge 1-Ex 2
--- ref2 chomp
Lé 5-De 7:8
--- expect chomp
Ge 1-De 7:8
=== begin_interval_reference LC - Ge 1, LCLCV - Lé 5-De 7:8, - before, before
--- ref1 chomp
Ge 1
--- ref2 chomp
Lé 5-De 7:8
--- expect chomp
Ge 1-De 7:8
=== begin_interval_reference LCVCV - Ge 1:1-2:5, LCLCV - Lé 5-De 7:8, - before, before
--- ref1 chomp
Ge 1:1-2:5
--- ref2 chomp
Lé 5-De 7:8
--- expect chomp
Ge 1:1-De 7:8
=== begin_interval_reference LCCV - Ge 1-2:5, LCLCV - Lé 5-De 7:8, - before, before
--- ref1 chomp
Ge 1-2:5
--- ref2 chomp
Lé 5-De 7:8
--- expect chomp 
Ge 1-De 7:8
=== begin_interval_reference LCC - Ge 1-2, LCLCV - Lé 5-De 7:8, - before, before
--- ref1 chomp
Ge 1-2
--- ref2 chomp
Lé 5-De 7:8
--- expect chomp
Ge 1-De 7:8
=== begin_interval_reference LC - Ge 1, LCLCV - Lé 5-De 7:8, - before, before
--- ref1 chomp
Ge 1
--- ref2 chomp
Lé 5-De 7:8
--- expect chomp
Ge 1-De 7:8
