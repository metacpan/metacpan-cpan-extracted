use t::TestConfig;

plan tests => 1 * blocks;

filters {
    yaml => [config => 'dumper' ],
#    perl => [strict => eval => 'dumper'],
};

sub config { 
    my $c = new Religion::Bible::Regex::Config(shift); 
    new Religion::Bible::Regex::Builder($c)->{livres_numerique};
}   

sub wsnoise {
    s/(?:\s*|\n)//g;
}


run_is yaml => 'perl';


#=== Two books defined, but no numeric books
# --- yaml
# ---
# books:
#   1: 
#     Match:
#       Book: ['Genèse', 'Genese']
#       Abbreviation: ['Ge']
#     Normalized: 
#       Book: Genèse
#       Abbreviation: Ge
#   2: 
#     Match:
#       Book: ['Exode']
#       Abbreviation: ['Ex']
#     Normalized: 
#       Book: Exode
#       Abbreviation: Ex
# --- 
#    perl


__END__
=== two numeric books defined
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
  10: 
    Match:
      Book: ['2Samuel', '2 Samuel', '2 Samuel']
      Abbreviation: ['2S', '2 S', '2 S']
    Normalized: 
      Book: 2Samuel
      Abbreviation: 2Sbooks:
--- perl
qr/(?-xism:1 S|1 Samuel|2 S|2 Samuel|S|Samuel)/
