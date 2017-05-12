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
=== cl_separateur is not set
--- yaml
---
--- perl
qr/(?-xism:;)/
=== cl_separateur is set to the default ';'
--- yaml
---
regex:
  cl_separateur: ";"
--- perl
qr/(?-xism:;)/
=== cl_separateur is set to something other than the default ','
--- yaml
---
regex:
  cl_separateur: ","
--- perl
qr/(?-xism:,)/
