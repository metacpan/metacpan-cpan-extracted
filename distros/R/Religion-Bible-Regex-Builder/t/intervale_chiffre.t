use t::TestConfig;

plan tests => 1 * blocks;

filters {
    yaml => [config => 'dumper'],
#    perl => [strict => eval => 'dumper'],
};

sub config { 
    my $c = new Religion::Bible::Regex::Config(shift); 
    new Religion::Bible::Regex::Builder($c)->{separateur};
}   

run_is yaml => 'perl';

__END__
=== cv_separateu is not set
--- yaml
---
--- perl
qr/(?-xism:\bet\b)/
=== separateur is set to the default ','
--- yaml
---
regex:
  separateur: (?::|\.)
--- perl
qr/(?-xism:(?::|\.))/
=== separateur is set to something other than the default ','
--- yaml
---
regex:
  separateur: (?::|\.)
--- perl
qr/(?-xism:(?::|\.))/
