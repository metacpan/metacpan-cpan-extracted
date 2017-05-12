use t::TestConfig;

plan tests => 1 * blocks;

filters {
    yaml => [config => 'dumper' ],
#    perl => [strict => eval => 'dumper'],
};

sub config { 
    my $c = new Religion::Bible::Regex::Config(shift); 
    new Religion::Bible::Regex::Builder($c)->{verset_mots};
}   

sub wsnoise {
    s/(?:\s*|\n)//g;
}

run_is yaml => 'perl';


__END__
=== two numeric books defined
--- yaml
---
regex:
  verset_mots: (?:vv?\.|du verset|des versets|les versets|voir aussi v.|le verset|aux versets|au verse|les versets suivants \()
--- perl
qr/(?-xism:(?:vv?\.|du verset|des versets|les versets|voir aussi v.|le verset|aux versets|au verse|les versets suivants \())/

