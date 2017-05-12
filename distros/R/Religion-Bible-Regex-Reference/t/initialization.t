use t::TestConfig;
use Data::Dumper;

plan tests => 2;

filters {
#    yaml => [config => 'dumper'],
    initialing_hash => [strict => eval => 'dumper'],
    result => [strict => eval => 'dumper']
};

run {
    my $block = shift;
    my $c = new Religion::Bible::Regex::Config($block->yaml); 
    my $r = new Religion::Bible::Regex::Builder($c);
    my $ref = new Religion::Bible::Regex::Reference($c, $r);

    is ref($ref->get_configuration), 'Religion::Bible::Regex::Config';
    is ref($ref->get_regexes), 'Religion::Bible::Regex::Builder';

#    is ref($ref->get_formatting_configuration_hash), 'HASH';
#    is ref($ref->get_versification_configuration_hash), 'HASH';

};

__END__
=== 
--- yaml
---
books:
  1: 
    Match:
      Book: ['Genèse', 'Genese']
      Abbreviation: ['Ge']
    Normalized: 
      Book: "Genèse"
      Book: "Genèse"
      Abbreviation: "Ge"
regex:
  chapitre: \d{1,3}
--- initialing_hash
{l=>'Ge', a=>' ', c=>'1', b=>'', cvs=>':', d=>'', v=>'1'}
--- result
{l=>'Ge', a=>' ', c=>'1', b=>'', cvs=>':', d=>'', v=>'1'}
