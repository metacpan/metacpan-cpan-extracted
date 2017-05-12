use t::TestConfig;

plan tests => 1 * blocks;

filters {
    yaml => [config => 'dumper'],
#    perl => [strict => eval => 'dumper'],
};

sub config { 
    my $c = new Religion::Bible::Regex::Config(shift); 
    new Religion::Bible::Regex::Builder($c)->{vl_separateur};
}   

run_is yaml => 'perl';

__END__
=== vl_separateur is not set
--- yaml
---
--- perl
qr/(?-xism:,)/
=== vl_separateur is set to the default ','
--- yaml
---
regex:
  vl_separateur: ","
--- perl
qr/(?-xism:,)/
=== vl_separateur is set to something other than the default ','
--- yaml
---
regex:
  vl_separateur: ";"
--- perl
qr/(?-xism:;)/
