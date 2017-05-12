#!/usr/bin/perl 

no warnings 'once';
$main::location = 'mod_perl_proxy1';
$main::rayapp_env_data = 'mono_lake';
$main::rayapp_env_style_data = 'krtek';

if (-d 't') {
	require 't/set1.pl';
} else {
	require 'set1.pl';
}
