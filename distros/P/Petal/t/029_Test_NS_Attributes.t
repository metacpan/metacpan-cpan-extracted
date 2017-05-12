#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::BASE_DIR = './t/data/test_ns_attributes/';

my $template;


#####

$Petal::NS = "petal";
$template = new Petal('test_rightWayOfDoing.xml');

my $string = $template->process (baz_value => 'baz_value');
like ($string => qr/baz_value/);


#####

$Petal::NS = "petal";
$template = new Petal('test_ns_attributes1.xml');

$string = $template->process (
    baz_value  => 'Replaced baz',
    buzz_value => 'Replaced buzz'
   );

like ($string => qr/Replaced baz/);
like ($string => qr/Replaced buzz/);


#####

$template = new Petal('test_ns_attributes2.xml');
$string =  $template->process(
    baz_value  => 'Replaced baz',
    buzz_value => 'Replaced buzz'
   );

like ($string => qr/Replaced baz/);
like ($string => qr/Replaced buzz/);


#####

$Petal::NS = "petal-temp";
$template = new Petal('test_ns_attributes3.xml');
$string = $template->process (
    baz_value  => 'Replaced baz',
    buzz_value => 'Replaced buzz'
   );
like ($string => qr/Replaced baz/);
like ($string => qr/Replaced buzz/);


#####
$Petal::NS = "petal_temp";
$Petal::NS_URI = "urn:pepsdesign.com:petal:temp";
$template = new Petal('test_ns_attributes4.xml');
$string = $template->process(baz_value => 'baz_value');
like ($string => qr/baz_value/);


#####
$Petal::NS = "petal-temp";
$Petal::NS_URI = "urn:pepsdesign.com:petal:temp";
$template = new Petal('test_ns_attributes5.xml');
$string = $template->process(baz_value => 'baz_value');
like ($string => qr/baz_value/);


# Replacing multiple attributes...
$Petal::NS = "petal_temp";
$Petal::NS_URI = "urn:pepsdesign.com:petal:temp";
$template = new Petal ('test_ns_attributes6.xml');
$string = $template->process (
    baz_data  => 'baz_value',
    buzz_data => 'buzz_value',
    quxx_data => 'quxx_value',
    SC        => ';'
   );

like ($string => qr/baz_value/);
like ($string => qr/buzz_value/);
like ($string => qr/quxx_value/);
like ($string => qr/;/);


# Replacing multiple attributes...
$Petal::NS = "petal-temp";
$Petal::NS_URI = "urn:pepsdesign.com:petal:temp";
$template = new Petal('test_ns_attributes7.xml');
$string = $template->process (
    baz_data  => 'baz_value',
    buzz_data => 'buzz_value',
    quxx_data => 'quxx_value',
    SC        => ';'
   );

like ($string => qr/baz_value/);
like ($string => qr/buzz_value/);
like ($string => qr/quxx_value/);
like ($string => qr/;/);


1;


__END__
