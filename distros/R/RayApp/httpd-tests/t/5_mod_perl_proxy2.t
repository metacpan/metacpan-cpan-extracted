#!/usr/bin/perl 

no warnings 'once';
$main::location = 'mod_perl_proxy2';
$main::rayapp_env_data = 'man53';
$main::rayapp_env_style_data = 'pes';

if (-d 't') {
	require 't/set1.pl';
} else {
	require 'set1.pl';
}
