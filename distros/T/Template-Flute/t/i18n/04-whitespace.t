#!perl

use strict;
use warnings;
use utf8;

use Test::More tests => 3;

use Template::Flute;
use Template::Flute::I18N;

my %lexicon = (
               "Enter your username..." => "Inserisci il nome utente...",
               "Submit result" => "Invia i risultati",
               "Title" => "Titolo",
               "Do-not-translate" => "FAIL",
               "Please insert your username here and we will send you a reset link." => "Inserisci il tuo nome utente e ti manderemo le istruzioni",
              );

sub translate {
    my $text = shift;
    return $lexicon{$text};
};

my $i18n = Template::Flute::I18N->new(\&translate);

my $spec = '<specification></specification>';
my $template =<<"HTML";
<html>
<body>
<div>
<p>
    Please insert your username here and we will send you a reset
    link.
</p>
<p>This is
a broken line
</p>
<p>Submit
result
</p>
</div>
</body>
</html>
HTML

my $flute = Template::Flute->new(specification => $spec,
                                 template => $template,
                                 i18n => $i18n);
my $output = $flute->process();

# diag $output;

like $output, qr{\sInserisci il tuo nome utente e ti manderemo le istruzioni\s},
  "White space collapsed and string translated";
like $output, qr{This is\na broken line}, "Untranslated text is not collapsed";
like $output, qr{Invia i risultati}, "Translated text collapsed";
