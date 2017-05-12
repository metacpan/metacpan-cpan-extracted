use t::TestConfig;

plan tests => 1 * blocks;

filters {
    yaml => [config => 'dumper'],
    perl => [strict => eval => 'dumper'],
};

sub config { 
        new Religion::Bible::Regex::Config(shift)->get_search_configurations; 
}

run_is yaml => 'perl';

__END__
=== Chapter and Verse Seperators
+++ yaml
---
books:
  1: 
    Match:
      Book: ['Genèse', 'Genese']
      Abbreviation: ['Ge']
    Normalized: 
      Book: "Genèse"
      Abbreviation: "Ge"
regex:
  cl_separateur: ";"
  vl_separateur: ","
+++ perl
{
   'cl_separateur' => ';',
   'vl_separateur' => ','
}
