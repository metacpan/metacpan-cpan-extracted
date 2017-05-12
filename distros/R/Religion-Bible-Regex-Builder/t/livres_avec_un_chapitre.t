use t::TestConfig;

plan tests => 1 * blocks;

filters {
    yaml => [config => 'dumper' ],
#    perl => [strict => eval => 'dumper'],
};

sub config { 
    my $c = new Religion::Bible::Regex::Config(shift); 
    new Religion::Bible::Regex::Builder($c)->{livres_avec_un_chapitre};
}   

sub wsnoise {
    s/(?:\s*|\n)//g;
}


run_is yaml => 'perl';

__END__
=== test for default values
--- yaml
---
--- perl
qr/(?-xism:(?:Ab|Abdias|2Jn|2Jean|Phm|Philemon|Philémon|Jud|Jude|3Jn|3Jean))/
=== two book defined
--- yaml
---
regex:
  livres_avec_un_chapitre: (?:Ab|Abdias|2Jn|2Jean|Phm|Philemon|Philémon|Jud|Jude|3Jn|3Jean)
--- perl
qr/(?-xism:(?:Ab|Abdias|2Jn|2Jean|Phm|Philemon|Philémon|Jud|Jude|3Jn|3Jean))/
