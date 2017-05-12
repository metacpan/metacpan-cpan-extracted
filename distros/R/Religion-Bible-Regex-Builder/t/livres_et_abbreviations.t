use t::TestConfig;

plan tests => 1 * blocks;

filters {
    yaml => [config => 'dumper' ],
#    perl => [strict => eval => 'dumper'],
};

sub config { 
    my $c = new Religion::Bible::Regex::Config(shift); 
    new Religion::Bible::Regex::Builder($c)->{livres_et_abbreviations};
}   

sub wsnoise {
    s/(?:\s*|\n)//g;
}

run_is yaml => 'perl';

__END__
=== one book defined
--- yaml
---
books:
  1: 
    Match:
      Book: ['Genèse', 'Genese']
      Abbreviation: ['Ge']
    Normalized: 
      Book: "Genèse"
      Book: "Genèse"
      Abbreviation: "Ge"
--- perl
qr/(?-xism:(?:(?-xism:Genèse|Genese)|(?-xism:Ge)))/
=== two book defined
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
--- perl
qr/(?-xism:(?:(?-xism:Genèse|Genese|Exode)|(?-xism:Ge|Ex)))/
