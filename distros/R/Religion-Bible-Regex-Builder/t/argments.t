use t::TestConfig;

plan tests => 1 * blocks;

filters {
    yaml => [config => 'dumper'],
#    perl => [strict => eval => 'dumper'],
};

sub config { 
    my $c = new Religion::Bible::Regex::Config(shift); 
    new Religion::Bible::Regex::Builder($c)->{cl_separateur};
}   

run_is yaml => 'perl';

__END__
=== Chapter and Verse Seperators
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
regex:
  cl_separateur: ";"
  vl_separateur: ","
--- perl
qr/(?-xism:;)/
