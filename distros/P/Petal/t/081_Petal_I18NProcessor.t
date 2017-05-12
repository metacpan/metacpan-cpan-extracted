#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal::I18N;
use Petal;

eval "use Lingua::31337";
if ($@) {
   warn "Lingua::31337 not found - skipping";
   ok (1);
}
else
{
    eval "use Petal::TranslationService::h4x0r";
    die $@ if ($@);

    $Petal::TranslationService = Petal::TranslationService::h4x0r->new();
    my $xml = <<EOF;
  <html><body>

    <!-- this is a mad example of romanized japanese, which we
         are going to turn into h4x0rz r0m4n|z3d J4paN33z -->

    <div i18n:translate="">
      Konichiwa, <span i18n:name="name">Buruno</span>-san,
      Kyoo wa o-genki desu ka?
    </div>

  </body></html>
EOF

    $xml =~ s/\s*$//;
    
    my $res = Petal::I18N->process ($xml);
    ok ($res =~ /Buruno/);
    ok ($res !~ /Konichiwa/);
}


1;


__END__
