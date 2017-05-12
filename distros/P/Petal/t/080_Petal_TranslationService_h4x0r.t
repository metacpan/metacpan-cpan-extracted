#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';

eval "use Lingua::31337";
if ($@) {
   warn "Lingua::31337 not found - skipping";
   ok (1);
}
else
{
   eval "use Petal::TranslationService::h4x0r";
   die $@ if ($@);

   my $trans  = new Petal::TranslationService::h4x0r;
   ok ($trans->isa ('Petal::TranslationService::h4x0r'));

   my $string = 'Adam, Bruno, Chris';
   my $res = $trans->maketext ($string);
   ok ($res ne $string);
}


1;


__END__
