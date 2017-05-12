#!perl

use strict;
use warnings;
use utf8;

use Test::More tests => 23;

use Template::Flute;
use Template::Flute::I18N;

my %lexicon = (
               "Enter your username..." => "Inserisci il nome utente...",
               "Submit result" => "Invia i risultati",
               "Title" => "Titolo",
               "Do-not-translate" => "FAIL",
              );

sub translate {
    my $text = shift;
    return $lexicon{$text};
};

my $i18n = Template::Flute::I18N->new(\&translate);
my $spec = '<specification></specification>';
my $template =<<HTML;
<html>
<body>
<div>
<h3>Title</h3>
<input placeholder=" Enter your username... ">
<input type="submit" data-role="button" data-icon="arrow-r"
         data-iconpos="right" data-iconpos="" data-theme="b"
         value=" Submit result">
<input type="hidden" name="blabla" value="Do-not-translate">
</div>
</body>
</html>
HTML

my $flute = Template::Flute->new(specification => $spec,
                                 template => $template,
                                 i18n => $i18n);
my $output = $flute->process();

like $output, qr/Titolo/, "Title translated";
like $output, qr/value=" Invia i risultati"/, "input submit translated";
like $output, qr/placeholder=" Inserisci il nome utente... "/,
  "placeholder translated";
like $output, qr/value="Do-not-translate"/, "hidden input preserved";

$flute = Template::Flute->new(specification => $spec,
                              template => $template,
                              translate_attributes => [],
                              i18n => $i18n);

$output = $flute->process;

like $output, qr/Titolo/, "Title translated";
unlike $output, qr/value=" Invia i risultati"/, "input submit not translated";
like $output, qr/value=" Submit result"/, "input submit not translated";
unlike $output, qr/placeholder=" Inserisci il nome utente... "/,
  "placeholder not translated";
like $output, qr/placeholder=" Enter your username\.\.\. "/,
  "placeholder not translated";
like $output, qr/value="Do-not-translate"/, "hidden input preserved";

$template =<<HTML;
<html>
<body>
<div>
<h3>Title</h3>
<input placeholder=" Enter your username... ">
<input type="submit" data-role="button" data-icon="arrow-r"
         data-iconpos="right" data-iconpos="" data-theme="b"
         value=" Submit result">
<input type="hidden" name="blabla" value="Do-not-translate">
<input type="submit" name="blabla" value="Do-not-translate">
<input value="Do-not-translate">
</div>
<p placeholder="Title">Title</p>
</body>
</html>
HTML


$flute = Template::Flute->new(specification => $spec,
                              template => $template,
                              translate_attributes => [qw/placeholder
                                                          input.value.type.hidden
                                                         /],
                              i18n => $i18n);

$output = $flute->process;

like $output, qr/Titolo/, "Title translated";
unlike $output, qr/value=" Invia i risultati"/, "input submit not translated";
like $output, qr/value=" Submit result"/, "input submit not translated";
like $output, qr/<input[^>]*placeholder=" Inserisci il nome utente\.\.\. "/,
  "placeholder translated";
like $output, qr/value="FAIL"/, "hidden input translated";
like $output, qr{<p placeholder="Titolo">Titolo</p>}, "Other placeholder translated as well";
like $output, qr{<input name="blabla" type="hidden" value="FAIL" />}, "input.value.type.hidden ok";
like $output, qr{<input name="blabla" type="submit" value="Do-not-translate" />}, "input.submit not translated";
like $output, qr{<input value="Do-not-translate" />}, "input not translated";


$flute = Template::Flute->new(specification => $spec,
                              template => $template,
                              translate_attributes => [qw/placeholder
                                                          input.value
                                                         /],
                              i18n => $i18n);

$output = $flute->process;

like $output, qr/value=" Invia i risultati"/, "input.value translated";
like $output, qr{<input name="blabla" type="hidden" value="FAIL" />}, "input.value.type.hidden ok";
like $output, qr{<input name="blabla" type="submit" value="FAIL" />}, "input.submit ok";
like $output, qr{<input value="FAIL" />}, "input translated";
