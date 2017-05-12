use t::TestConfig;
use Data::Dumper;

plan tests => 1 * blocks();

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
  65: 
    Match:
      Book: ['Jude']
      Abbreviation: ['Ju']
    Normalized: 
      Book: Jude
      Abbreviation: Ju

regex:
  chapitre_mots: (?:voir aussi|voir|\\(|voir chapitre|\\bde\\b)
  verset_mots: (?:vv?\.|voir aussi v\.)
  livres_avec_un_chapitre: (?:Ab|Abdias|2Jn|2Jean|Phm|Philemon|Philémon|Jud|Jude|3Jn|3Jean)

YAML

my $c = new Religion::Bible::Regex::Config($yaml); 
my $b = new Religion::Bible::Regex::Builder($c);

run {
    my $block = shift;

    # Initialize a new reference
    my $ref = new Religion::Bible::Regex::Reference($c, $b);

    # Parse the reference
    $ref->parse($block->reference);

    # Normalize the reference
    my $result = $ref->normalize;
    my $expected = $block->expected;

    is($result, $expected, $block->name);
};

#=== Parse not reference - Michael 2:3
#--- reference chomp
#Michael 2:3
#--- expected chomp

__END__
=== Parse LCVLCV - Genèse 1:1-Exode 2:5
--- reference chomp
Genèse 1:1-Exode 2:5
--- expected chomp
Genèse 1:1-Exode 2:5
=== Parse LCLCV - Genèse 1-Exode 2:5
--- reference chomp
Genèse 1-Exode 2:5
--- expected chomp 
Genèse 1-Exode 2:5
=== Parse LCLC - Genèse 1-Exode 2
--- reference chomp
Genèse 1-Exode 2
--- expected chomp
Genèse 1-Exode 2
=== Parse LC - Genèse 1
--- reference chomp
Genèse 1
--- expected chomp
Genèse 1
=== Parse LCVCV - Genèse 1:1-2:5
--- reference chomp
Genèse 1:1-2:5
--- expected chomp
Genèse 1:1-2:5
=== Parse LCCV - Genèse 1-2:5
--- reference chomp
Genèse 1-2:5
--- expected chomp 
Genèse 1-2:5
=== Parse LCC - Genèse 1-2
--- reference chomp
Genèse 1-2
--- expected chomp
Genèse 1-2
=== Parse LC - Genèse 1
--- reference chomp
Genèse 1
--- expected chomp
Genèse 1
=== Parse CVCV - 1:1-2:5
--- reference chomp
voir 1:1-2:5
--- state chomp
CHAPTER
--- expected chomp
voir 1:1-2:5
=== Parse CCV - 1-2:5
--- reference chomp
voir 1-2:5
--- state chomp
CHAPTER
--- expected chomp
voir 1-2:5
=== Parse CC - 1-2
--- reference chomp
voir 1-2
--- state chomp
CHAPTER
--- expected chomp
voir 1-2
=== Parse C - 2
--- reference chomp
voir 1
--- state chomp
CHAPTER
--- expected chomp
voir 1
=== Parse VV - 1-2
--- reference chomp
vv. 1-2
--- state chomp
VERSE
--- expected chomp
vv. 1-2
=== Parse V - 2
--- reference chomp
v. 1
--- state chomp
VERSE
--- expected chomp
v. 1
=== Parse a book that has only one chapter - Jude 4
--- reference chomp
Jude 4
--- state chomp
VERSE
--- expected chomp
Jude 1:4

=== Parse LCVLCV - Genèse 1:1-Genèse 2:5 - Shorten reference when books are the same
--- reference chomp
Genèse 1:1-Genèse 2:5
--- expected chomp
Genèse 1:1-2:5

=== Parse LCLC - Genèse 1-Genèse 2 - Shorten reference when book and chapter are the same
--- reference chomp
Genèse 2-Genèse 2
--- expected chomp
Genèse 2

=== Parse LCVLCV - Genèse 1:1-Genèse 2:5 - Shorten reference when book, chapter and verse are the same
--- reference chomp
Genèse 2:5-Genèse 2:5
--- expected chomp
Genèse 2:5


=== Parse LCVLCV - Genèse 1:1-Genèse 2:5 - Shorten reference when books are the same, cvs should be ':'
--- reference chomp
Genèse 1.1-Genèse 2.5
--- expected chomp
Genèse 1:1-2:5

=== Parse LCVLCV - Genèse 1:1-Genèse 2:5 - Shorten reference when book, chapter and verse are the same, cvs should be ':'
--- reference chomp
Genèse 2.5-Genèse 2.5
--- expected chomp
Genèse 2:5


