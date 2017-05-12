#!/usr/bin/perl 

no warnings 'once';
$main::location = 'cgi2';
$main::rayapp_env_data = 'mono2';
$main::rayapp_env_style_data = 'jezevec';

if (-d 't') {
	require 't/set1.pl';
} else {
	require 'set1.pl';
}
