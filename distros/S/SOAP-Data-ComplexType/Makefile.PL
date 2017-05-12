#!/usr/bin/perl -w
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile (
 NAME		=> "SOAP::Data::ComplexType",
 AUTHOR		=> 'Eric Rybski (rybskej@yahoo.com)',
 ABSTRACT	=> 'Complex SOAP::Data object class interface',
 VERSION_FROM	=> 'lib/SOAP/Data/ComplexType.pm',
 PREREQ_PM	=> {
  'SOAP::Data::Builder' => 0.8,
 },
 (MM->can('signature_target') ? (SIGN => 1) : ()),
);
