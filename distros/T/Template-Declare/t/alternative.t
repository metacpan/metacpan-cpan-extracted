use strict;
use warnings;
use Test::More tests => 7;

package MyApp::Templates;

use Template::Declare::Tags 'HTML';

eval "td { 'hi' }";
::ok $@, 'td is invalid';
::is $@, "td {...} is invalid; use cell {...} instead.\n";

eval "tr { 'hi' }";
::ok $@, 'tr is invalid';
::like $@, qr/Transliteration replacement not terminated/;

eval "base { 'hi' }";
::ok $@;
::like $@, qr/Can't locate object method "base"/;

package MyApp::Templates2;

use base 'Template::Declare';
use Template::Declare::Tags 'XUL';

template main => sub {
    xul_tempalte {}
};

Template::Declare->init( dispatch_to => ['MyApp::Templates2']);
my $out = Template::Declare->show('main') . "\n";
::is $out, <<_EOC_;

<template />
_EOC_

