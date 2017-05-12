use t::TestConfig;

plan tests => 1 * blocks;

filters {
    yaml => [config => 'dumper' ],
    perl => [strict => eval => 'dumper'],
};

sub config { 
    my $c = new Religion::Bible::Regex::Config(shift); 
    new Religion::Bible::Regex::Builder($c)->{key2book};
}    

run_is yaml => 'perl';

__END__
=== one book, one abbreviation defined
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
{ '1' => 'Genèse' }

=== one books, three booknames, three abbreviations defined
--- yaml
---
books:
  9: 
    Match:
      Book: ['1Samuel', '1 Samuel', '1 Samuel']
      Abbreviation: ['1S', '1 S', '1 S']
    Normalized: 
      Book: 1Samuel
      Abbreviation: 1S
--- perl
{ '9' => '1Samuel' }
