use t::TestConfig;

plan tests => 1 * blocks;

#my $c = new Religion::Bible::Regex::Config("config/config-key.yml");

#is(';', $c->get('regex', 'cl_separateur'), 'Test 1');
#is(',', $c->get('regex', 'vl_separateur'), 'Test 2');

filters {
    yaml => [config => 'dumper'],
    perl => [strict => eval => 'dumper'],
};

sub config { 
        new Religion::Bible::Regex::Config(shift); 
}

run_is yaml => 'perl';

__END__
=== Chapter and Verse Seperators
+++ yaml
---
books:
  1: 
    Match:
      Book: ['Genèse', 'Genese']
      Abbreviation: ['Ge']
    Normalized: 
      Book: "Genèse"
      Abbreviation: "Ge"
regex:
  cl_separateur: ";"
  vl_separateur: ","
+++ perl
bless( {
   'config' => {
     'books' => {
       '1' => {
         'Match' => {
           'Abbreviation' => [
             'Ge'
           ],
           'Book' => [
             'Genèse',
             'Genese'
           ]
         },
         'Normalized' => {
           'Abbreviation' => 'Ge',
           'Book' => 'Genèse'
         }
       }
     },
     'regex' => {
       'cl_separateur' => ';',
       'vl_separateur' => ','
     }
   }
 }, 'Religion::Bible::Regex::Config' )
