use strict;
use warnings;

# Input files are assumed to be in the UTF-8 strict character encoding.
use utf8;
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
use Getopt::Long;
use Religion::Bible::Test::FixtureHelper;
use Religion::Bible::Regex::Config;
use Religion::Bible::Regex::Builder;
use Data::Dumper;

my $fix = new Religion::Bible::Test::FixtureHelper(\*DATA);

# Test de Reconnasance 
use Test::More qw(no_plan);
while ( my ($key, $value) = each(%{$fix->{fixtures}}) ) {
    my $configuration = new Religion::Bible::Regex::Config($value->{'configuration_file'});
    my $r = new Religion::Bible::Regex::Builder($configuration);

    is($r->{'chiffre'}, qr/$value->{'chiffre'}/) if (defined($value->{'chiffre'}));
    is($r->{'chapitre_mots'}, qr/$value->{'chapitre_mots'}/) if (defined($value->{'chapitre_mots'}));
    is($r->{'livres'}, qr/$value->{'livres'}/) if (defined($value->{'livres'}));
    is($r->{'abbreviations'}, qr/$value->{'abbreviations'}/) if (defined($value->{'abbreviations'}));

    # is($r->{'livres_numerique'}, qr/$value->{'livres_numerique'}/) if (defined($value->{'livres_numerique'}));
    # is($r->{'livres_numerique'}, $value->{'livres_numerique'}) if (defined($value->{'livres_numerique'}) && $value->{'livres_numerique'} eq '');
    # is($r->{'livres'}, qr/$value->{'books'}/x);
}

__DATA__
1:
  configuration_file:t/config/blank.yml
  chiffre:\d{1,3}[abcdes]?
2:
  configuration_file:t/config/change_chiffre_value.yml
  chiffre:\d{1,3}
3:
  configuration_file:t/config/change_chapitre_mots_value.yml
  chapitre_mots:(?:\(|voir aussi|voir|\(voir|\bde\b|dans|Dans|dans les chapitres|\[|se rapporte à|voyez également|par ex\.|A partir de|Au verset|au verset|passage de|\(chap\.)
4:
  configuration_file:t/config/change_chapitre_mots_value_with_file.yml
  chapitre_mots:(?:\(|voir aussi|voir|\(voir|\bde\b|dans|Dans|dans les chapitres|\[|se rapporte à|voyez également|par ex\.|A partir de|Au verset|au verset|passage de|\(chap\.)
5:
  configuration_file:t/config/simple.yml
  livres:Genèse|Genese|Exode
  abbreviations:Ge|Ex
  livres_numerique:
