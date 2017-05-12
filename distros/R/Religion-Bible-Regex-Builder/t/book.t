use t::TestConfig;
use utf8;
use Data::Dumper;
no warnings;

plan tests => 237;

run {
    my $block = shift;
    my $c = new Religion::Bible::Regex::Config($block->yaml); 
    my $r = new Religion::Bible::Regex::Builder($c);
    
    my $yaml_loader = YAML::Loader->new();
    my $bookconfig = $yaml_loader->load($block->yaml); 

#    print Dumper $bookconfig;
    # Foreach match abbreviation return the normalized book
    while ( my ($key, $value) = each(%{$bookconfig->{books}})) {
	foreach my $mb (@{$value->{Match}->{Abbreviation}}) {
	        my $result = $r->book($mb);
		my $expected = $value->{Normalized}->{Book};
		is_deeply($result, $expected, $block->name . ": with the abbreviation='$mb', result='$result', expected='$expected'");
	}
    }

    # Foreach key return the normalized book
    while ( my ($key, $value) = each(%{$bookconfig->{books}})) {
	my $result = $r->book($key);
	my $expected = $value->{Normalized}->{Book};
	is_deeply($result, $expected, $block->name . ": with the key='$key', result='$result', expected='$expected' ");
    }


    # # Given a key return the abbreviation
    # my $result = $r->abbreviation($block->key);
    # my $expected = $block->abbreviation;
    # chomp $expected;
    # is_deeply($result, $expected, $block->name . ": with the abbreviation");

    # # Given a book return the abbreviation
    # $result = $r->abbreviation($block->book);
    # $expected = $block->abbreviation;
    # chomp $expected;
    # is_deeply($result, $expected, $block->name . ": asking with the canonical book name");

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
  6: 
    Match:
      Book: ['Josué', 'Josue']
      Abbreviation: ['Jos']
    Normalized: 
      Book: Josué
      Abbreviation: Jos
  7: 
    Match:
      Book: ['Juges']
      Abbreviation: ['Jug', 'Jg']
    Normalized: 
      Book: Juges
      Abbreviation: Jug
  8: 
    Match:
      Book: ['Ruth']
      Abbreviation: ['Ru']
    Normalized: 
      Book: Ruth
      Abbreviation: Ru
  9: 
    Match:
      Book: ['1Samuel', '1 Samuel', '1 Samuel']
      Abbreviation: ['1S', '1 S', '1 S']
    Normalized: 
      Book: 1Samuel
      Abbreviation: 1S
  10: 
    Match:
      Book: ['2Samuel', '2 Samuel', '2 Samuel']
      Abbreviation: ['2S', '2 S', '2 S']
    Normalized: 
      Book: 2Samuel
      Abbreviation: 2S
  11: 
    Match:
      Book: ['1Rois', '1 Rois', '1 Rois']
      Abbreviation: ['1R', '1 R', '1 R']
    Normalized: 
      Book: 1Rois
      Abbreviation: 1R
  12: 
    Match:
      Book: ['2Rois', '2 Rois', '2 Rois']
      Abbreviation: ['2R', '2 R', '2 R']
    Normalized: 
      Book: 2Rois
      Abbreviation: 2R
  13: 
    Match:
      Book: ['1Chroniques', '1 Chroniques', '1 Chroniques']
      Abbreviation: ['1Ch', '1 Ch', '1 Ch']
    Normalized: 
      Book: 1Chroniques
      Abbreviation: 1Ch
  14: 
    Match:
      Book: ['2Chroniques', '2 Chroniques', '2 Chroniques']
      Abbreviation: ['2Ch', '2 Ch', '2 Ch']
    Normalized: 
      Book: 2Chroniques
      Abbreviation: 2Ch
  15: 
    Match:
      Book: ['Esdras']
      Abbreviation: ['Esd']
    Normalized: 
      Book: Esdras
      Abbreviation: Esd
  16: 
    Match:
      Book: ['Néhémie', 'Nehemie']
      Abbreviation: ['Né']
    Normalized: 
      Book: Néhémie
      Abbreviation: Né
  17: 
    Match:
      Book: ['Esther']
      Abbreviation: ['Est']
    Normalized: 
      Book: Esther
      Abbreviation: Est
  18: 
    Match:
      Book: ['Job']
      Abbreviation: ['Job']
    Normalized: 
      Book: Job
      Abbreviation: Job
  19: 
    Match:
      Book: ['Psaumes', 'Psaume', 'psaumes', 'psaume']
      Abbreviation: ['Ps']
    Normalized: 
      Book: Psaume
      Abbreviation: Ps
  20: 
    Match:
      Book: ['Proverbes']
      Abbreviation: ['Pr']
    Normalized: 
      Book: Proverbes
      Abbreviation: Pr
  21: 
    Match:
      Book: ['Ecclésiaste', 'Ecclesiaste']
      Abbreviation: ['Ec']
    Normalized: 
      Book: Ecclésiaste
      Abbreviation: Ec
  22: 
    Match:
      Book: ['Cantique', 'Cantique des Cantiques']
      Abbreviation: ['Ca']
    Normalized: 
      Book: Cantique
      Abbreviation: Ca
  23: 
    Match:
      Book: ['Esaïe', 'Esaie', 'Ésaïe','Ésaie']
      Abbreviation: ['És', 'Esa']
    Normalized: 
      Book: Esaïe
      Abbreviation: Esa
  24: 
    Match:
      Book: ['Jérémie', 'Jeremie']
      Abbreviation: ['Jér', 'Jer', 'Jé']
    Normalized: 
      Book: Jérémie
      Abbreviation: Jér
  25: 
    Match:
      Book: ['Lamentations']
      Abbreviation: ['La']
    Normalized: 
      Book: Lamentations
      Abbreviation: La
  26: 
    Match:
      Book: ['Ezékiel', 'Ezekiel', 'Ézekiel', 'Ézékiel', 'Ezéchiel', 'Ezechiel', 'Ézechiel', 'Ézéchiel']
      Abbreviation: ['Ez', 'Éz']
    Normalized: 
      Book: Ezékiel
      Abbreviation: Ez
  27: 
    Match:
      Book: ['Daniel']
      Abbreviation: ['Da', 'Dan']
    Normalized: 
      Book: Daniel
      Abbreviation: Da
  28: 
    Match:
      Book: ['Osée', 'Osee']
      Abbreviation: ['Os']
    Normalized: 
      Book: Osée
      Abbreviation: Os
  29: 
    Match:
      Book: ['Joël', 'Joel']
      Abbreviation: ['Joe', 'Joë']
    Normalized: 
      Book: Joël
      Abbreviation: Joe
  30: 
    Match:
      Book: ['Amos']
      Abbreviation: ['Am']
    Normalized: 
      Book: Amos
      Abbreviation: Am
  31: 
    Match:
      Book: ['Abdias']
      Abbreviation: ['Ab']
    Normalized: 
      Book: Abdias
      Abbreviation: Ab
  32: 
    Match:
      Book: ['Jonas']
      Abbreviation: ['Jon']
    Normalized: 
      Book: Jonas
      Abbreviation: Jon
  33: 
    Match:
      Book: ['Michée', 'Michee']
      Abbreviation: ['Mic', 'Mi']
    Normalized: 
      Book: Michée
      Abbreviation: Mi
  34: 
    Match:
      Book: ['Nahum']
      Abbreviation: ['Na']
    Normalized: 
      Book: Nahum
      Abbreviation: Na
  35: 
    Match:
      Book: ['Habakuk']
      Abbreviation: ['Ha']
    Normalized: 
      Book: Habakuk
      Abbreviation: Ha
  36: 
    Match:
      Book: ['Sophonie']
      Abbreviation: ['Sop', 'So']
    Normalized: 
      Book: Sophonie
      Abbreviation: Sop
  37: 
    Match:
      Book: ['Aggée', 'Aggee']
      Abbreviation: ['Ag']
    Normalized: 
      Book: Aggée
      Abbreviation: Ag
  38: 
    Match:
      Book: ['Zacharie']
      Abbreviation: ['Za']
    Normalized: 
      Book: Zacharie
      Abbreviation: Za
  39: 
    Match:
      Book: ['Malachie']
      Abbreviation: ['Mal', 'Ma']
    Normalized: 
      Book: Malachie
      Abbreviation: Mal
  40: 
    Match:
      Book: ['Matthieu']
      Abbreviation: ['Mt']
    Normalized: 
      Book: Matthieu
      Abbreviation: Mt
  41: 
    Match:
      Book: ['Marc']
      Abbreviation: ['Mc', 'Mr']
    Normalized: 
      Book: Marc
      Abbreviation: Mr
  42: 
    Match:
      Book: ['Luc']
      Abbreviation: ['Lu']
    Normalized: 
      Book: Luc
      Abbreviation: Lu
  43: 
    Match:
      Book: ['Jean']
      Abbreviation: ['Jn']
    Normalized: 
      Book: Jean
      Abbreviation: Jn
  44: 
    Match:
      Book: ['Actes']
      Abbreviation: ['Ac']
    Normalized: 
      Book: Actes
      Abbreviation: Ac
  45: 
    Match:
      Book: ['Romains']
      Abbreviation: ['Ro']
    Normalized: 
      Book: Romains
      Abbreviation: Ro
  46: 
    Match:
      Book: ['1Corinthiens', '1 Corinthiens', '1 Corinthiens']
      Abbreviation: ['1Co', '1 Co', '1 Co']
    Normalized: 
      Book: 1Corinthiens
      Abbreviation: 1Co
  47: 
    Match:
      Book: ['2Corinthiens', '2 Corinthiens', '2 Corinthiens']
      Abbreviation: ['2Co', '2 Co', '2 Co']
    Normalized: 
      Book: 2Corinthiens
      Abbreviation: 2Co
  48: 
    Match:
      Book: ['Galates']
      Abbreviation: ['Ga']
    Normalized: 
      Book: Galates
      Abbreviation: Ga
  49: 
    Match:
      Book: ['Ephésiens', 'Ephesiens', 'Éphésiens', 'Éphesiens']
      Abbreviation: ['Ép','Ep']
    Normalized: 
      Book: Ephésiens
      Abbreviation: Ep
  50: 
    Match:
      Book: ['Philippiens']
      Abbreviation: ['Ph']
    Normalized: 
      Book: Philippiens
      Abbreviation: Ph
  51: 
    Match:
      Book: ['Colossiens']
      Abbreviation: ['Col']
    Normalized: 
      Book: Colossiens
      Abbreviation: Col
  52: 
    Match:
      Book: ['1Thessaloniciens', '1 Thessaloniciens', '1 Thessaloniciens']
      Abbreviation: ['1Th', '1 Th', '1 Th']
    Normalized: 
      Book: 1Th
      Abbreviation: 1Th
  53: 
    Match:
      Book: ['2Thessaloniciens', '2 Thessaloniciens', '2 Thessaloniciens']
      Abbreviation: ['2Th', '2 Th', '2 Th']
    Normalized: 
      Book: 2Th
      Abbreviation: 2Th
  54: 
    Match:
      Book: ['1Timothée', '1 Timothée', '1Timothee', '1 Timothee', '1 Timothée', '1Timothee', '1 Timothee']
      Abbreviation: ['1Ti', '1 Ti', '1 Ti']
    Normalized: 
      Book: 1Timothée
      Abbreviation: 1Ti
  55: 
    Match:
      Book: ['2Timothée', '2 Timothée', '2Timothee', '2 Timothee', '2 Timothée', '2Timothee', '2 Timothee']
      Abbreviation: ['2Ti', '2 Ti', '2 Ti']
    Normalized: 
      Book: 2Timothée
      Abbreviation: 2Ti
  56: 
    Match:
      Book: ['Tite']
      Abbreviation: ['Tit', 'Ti']
    Normalized: 
      Book: Tite
      Abbreviation: Tit
  57: 
    Match:
      Book: ['Philémon', 'Philemon']
      Abbreviation: ['Phm']
    Normalized: 
      Book: Philémon
      Abbreviation: Phm
  58: 
    Match:
      Book: ['Hébreux', 'Hebreux']
      Abbreviation: ['Hé']
    Normalized: 
      Book: Hébreux
      Abbreviation: Hé
  59: 
    Match:
      Book: ['Jacques']
      Abbreviation: ['Ja']
    Normalized: 
      Book: Jacques
      Abbreviation: Ja
  60: 
    Match:
      Book: ['1Pierre', '1 Pierre', '1 Pierre']
      Abbreviation: ['1P', '1 P', '1Pi', '1 Pi', '1 P', '1Pi', '1 Pi']
    Normalized: 
      Book: 1Pierre
      Abbreviation: 1P
  61: 
    Match:
      Book: ['2Pierre', '2 Pierre', '2 Pierre']
      Abbreviation: ['2P', '2 P', '2Pi', '2 Pi', '2 P', '2Pi', '2 Pi']
    Normalized: 
      Book: 2Pierre
      Abbreviation: 2P
  62: 
    Match:
      Book: ['1Jean', '1 Jean', '1 Jean']
      Abbreviation: ['1Jn', '1 Jn', '1 Jn']
    Normalized: 
      Book: 1Jean
      Abbreviation: 1Jn
  63: 
    Match:
      Book: ['2Jean', '2 Jean', '2 Jean']
      Abbreviation: ['2Jn', '2 Jn', '2 Jn']
    Normalized: 
      Book: 2Jean
      Abbreviation: 2Jn
  64: 
    Match:
      Book: ['3Jean', '3 Jean', '3 Jean']
      Abbreviation: ['3Jn', '3 Jn', '3 Jn']
    Normalized: 
      Book: 3Jean
      Abbreviation: 3Jn
  65: 
    Match:
      Book: ['Jude']
      Abbreviation: ['Jude', 'Jud']
    Normalized: 
      Book: Jude
      Abbreviation: Jude
  66: 
    Match:
      Book: ['Apocalypse']
      Abbreviation: ['Ap']
    Normalized: 
      Book: Apocalypse
      Abbreviation: Ap
  67: 
    Match:
      Book: ['1Esdras', '1 Esdras', '1 Esdras']
      Abbreviation: ['1Es', '1 Es', '1 Es']
    Normalized: 
      Book: 1Esdras
      Abbreviation: 1Es
  68: 
    Match:
      Book: ['2Esdras', '2 Esdras', '2 Esdras']
      Abbreviation: ['2Es', '2 Es', '2 Es']
    Normalized: 
      Book: 2Esdras
      Abbreviation: 2Es
  69: 
    Match:
      Book: ['Tobit']
      Abbreviation: ['Tob']
    Normalized: 
      Book: Tobit
      Abbreviation: Tob
  70: 
    Match:
      Book: ['Judith']
      Abbreviation: ['Jdt']
    Normalized: 
      Book: Judith
      Abbreviation: Jdt
  71: 
    Match:
      Book: ['EstherG']
      Abbreviation: ['EstG']
    Normalized: 
      Book: EstherG
      Abbreviation: EstG
  72: 
    Match:
      Book: ['Wisdom']
      Abbreviation: ['Sag']
    Normalized: 
      Book: Wisdom
      Abbreviation: Sag
  73: 
    Match:
      Book: ['Sirach']
      Abbreviation: ['Sir']
    Normalized: 
      Book: Sirach
      Abbreviation: Sir
  74: 
    Match:
      Book: ['Baruch']
      Abbreviation: ['Bar']
    Normalized: 
      Book: Baruch
      Abbreviation: Bar
  75: 
    Match:
      Book: ['Azariah']
      Abbreviation: ['Aza']
    Normalized: 
      Book: Azariah
      Abbreviation: Aza
  76: 
    Match:
      Book: ['Susanna']
      Abbreviation: ['Sus']
    Normalized: 
      Book: Susanna
      Abbreviation: Sus
  77: 
    Match:
      Book: ['Bel']
      Abbreviation: ['Bel']
    Normalized: 
      Book: Bel
      Abbreviation: Bel
  78: 
    Match:
      Book: ['Manasses']
      Abbreviation: ['Man']
    Normalized: 
      Book: Manasses
      Abbreviation: Man
  79: 
    Match:
      Book: ['1Maccabees', '1 Maccabees', '1 Maccabees']
      Abbreviation: ['1Ma', '1 Ma', '1 Ma']
    Normalized: 
      Book: 1Maccabees
      Abbreviation: 1Ma
  80: 
    Match:
      Book: ['2Maccabees', '2 Maccabees', '2 Maccabees']
      Abbreviation: ['2Ma', '2 Ma', '2 Ma']
    Normalized: 
      Book: 2Maccabees
      Abbreviation: 2Ma
  81: 
    Match:
      Book: ['3Maccabees', '3 Maccabees', '3 Maccabees']
      Abbreviation: ['3Ma', '3 Ma', '3 Ma']
    Normalized: 
      Book: 3Maccabees
      Abbreviation: 3Ma
  82: 
    Match:
      Book: ['4Maccabees', '4 Maccabees', '4 Maccabees']
      Abbreviation: ['4Ma', '4 Ma', '4 Ma']
    Normalized: 
      Book: 4Maccabees
      Abbreviation: 4Ma
  83: 
    Match:
      Book: ['2Psalm', '2 Psalm', '2 Psalm']
      Abbreviation: ['2Ps', '2 Ps', '2 Ps']
    Normalized: 
      Book: 2Psalm
      Abbreviation: 2Ps
