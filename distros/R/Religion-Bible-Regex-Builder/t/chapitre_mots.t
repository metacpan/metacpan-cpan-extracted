use t::TestConfig;

plan tests => 1 * blocks;

filters {
    yaml => [config => 'dumper' ],
#    perl => [strict => eval => 'dumper'],
};

sub config { 
    my $c = new Religion::Bible::Regex::Config(shift); 
    new Religion::Bible::Regex::Builder($c)->{chapitre_mots};
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
  chapitre_mots: (?:\(|voir aussi|voir|\(voir|\bde\b|dans|Dans|\[|se rapporte à|voyez également|par ex\.|A partir de|Au verset|au verset|passage de|\(chap\.)
--- perl
qr/(?-xism:(?:\(|voir aussi|voir|\(voir|\bde\b|dans|Dans|\[|se rapporte à|voyez également|par ex\.|A partir de|Au verset|au verset|passage de|\(chap\.))/

