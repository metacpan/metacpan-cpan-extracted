#!perl
use strict;
use warnings;
use Test::More tests => 5;

use Template::Flute;
use Template::Flute::I18N;

my $xml = <<EOF;
<specification name="textarea">
<form name="textarea" id="textarea">
<field name="content"/>
</form>
</specification>
EOF

my $html = <<EOF;
<script>test</script>
<style>test</style>
<p>test</p>
<form name="textarea" id="textarea">
<textarea class="content" placeholder="test">
</textarea>
</form>
EOF

sub translate {
    my $l = shift;
    my %trx = (
               test => 'Translated',
               'Hello World' => 'Translated Hello World',
              );
    return $trx{$l} || $l;
}


{
    my $flute = new Template::Flute(
                                    specification => $xml,
                                    template => $html,
                                   );
    my ($form) = $flute->template->forms;
    $form->fill({content => "Hello World\r\nHello There"});
    my $out =  $flute->process;
    like $out, qr/Hello World\r\nHello There/, "new line preserved" or diag $out;
}


{
    my $i18n = Template::Flute::I18N->new(\&translate);
    my $flute = new Template::Flute(
                                    specification => $xml,
                                    template => $html,
                                    i18n => $i18n,
                                   );
    my ($form) = $flute->template->forms;
    $form->fill({content => "Hello World\r\nHello There"});
    my $out =  $flute->process;
    # diag $out;
    like $out, qr/Hello World\r\nHello There/, "new line preserved" or diag $out;
    unlike $out, qr/<(script|style)>Translated/, "No style/script translated";
    like $out, qr/placeholder="Translated/, "placeholder translated";
    like $out, qr/<p>Translated/, "Paragraph translated";
}

