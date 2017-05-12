use t::TestConfig;

plan tests => 1 * blocks;

filters {
    yaml => [config => 'dumper'],
#    perl => [strict => eval => 'dumper'],
};

sub config { 
    my $c = new Religion::Bible::Regex::Config(shift); 
    new Religion::Bible::Regex::Builder($c)->{verset};
}   

run_is yaml => 'perl';

__END__
=== verset is not set
--- yaml
---
--- perl
qr/(?-xism:\b(?:(?-xism:(?:17[0123456]|1[0123456]\d|\d{1,2})))(?:(?-xism:[a-z]))?\b)/
=== verset is set to the default ','
--- yaml
---
regex:
  verset: \d{1,3}
--- perl
qr/(?-xism:\d{1,3})/
=== verset is set to something other than the default ','
--- yaml
---
regex:
  verset: \d{1,4}
--- perl
qr/(?-xism:\d{1,4})/
