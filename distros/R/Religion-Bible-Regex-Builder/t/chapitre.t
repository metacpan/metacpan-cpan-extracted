use t::TestConfig;

plan tests => 1 * blocks;

filters {
    yaml => [config => 'dumper' => 'chomp'],
    perl => ['chomp'],
};

sub config { 
    my $c = new Religion::Bible::Regex::Config(shift); 
    new Religion::Bible::Regex::Builder($c)->{chapitre};
}   

run_is yaml => 'perl';

__END__
=== chapitre is not set
--- yaml
---
--- perl
qr/(?-xism:(?:\b150\b)|(?:\b1[01234]\d\b)|\b\d{1,2}\b)/
=== chapitre is set to the default ','
--- yaml
---
regex:
  chapitre: \d{1,3}
--- perl
qr/(?-xism:\d{1,3})/
=== chapitre is set to something other than the default ','
--- yaml
---
regex:
  chapitre: \d{1,4}
--- perl
qr/(?-xism:\d{1,4})/
