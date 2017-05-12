use 5.006000;
use lib 'lib';
use inc::Module::Install;
use strict;
use warnings;

name		'Net-Hulu';
author		'Gerald L. Hevener, M.S. <{[hevenerg]}at{[marshall]}dot{[edu]}>';
perl_version	'5.005';
license		'perl';
all_from	'lib/Net/Hulu.pm';
requires	'XML::Twig'	=> '3.32';
requires	'LWP::Simple'	=> '2.18';
requires	'Carp'		=> '1.11';
test_requires	'Test::Perl::Critic'	=> '1.02';
test_requires	'Test::Distribution'	=> '2.00';
test_requires	'Test::More'		=> '0.94';
test_requires	'Test::Kwalitee'	=> '1.01';
test_requires	'Test::Pod::Coverage'	=> '1.08';
test_requires	'Test::Pod'		=> '1.40';
test_requires	'Test::Strict'		=> '0.13';

PREREQ_PM => { 'LWP::Simple' => 0, 'XML::Twig' => 0 };

#This is a normal CPAN module
install_as_cpan;

#Build SIGNATURE file using Signature.pm
sign;

#Write make file
WriteAll;
