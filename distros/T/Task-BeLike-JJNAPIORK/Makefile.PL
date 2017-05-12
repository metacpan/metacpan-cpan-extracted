#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

requires (
  'App::cpanminus' => '1.4004',
  'App::local::lib::helper' => '0.04',
  'Module::Setup' => '0.09',
  'Module::Setup::Flavor::JJNAPIORK' => '0.05',
  'Module::Install' => '1.00',
  'Module::Install::Repository' => '0.06',
  'Module::Install::AutoManifest' => '0.003',
  'Module::Install::ReadmeMarkdownFromPod' => '0.03',
  'Module::Install::ManifestSkip' => '0.14',
  'Module::Install::Homepage' => '0.01',
  'Module::Install::AutoLicense' => '0.08',
);

test_requires 'Test::More' => '0.98';
all_from 'lib/Task/BeLike/JJNAPIORK.pm';
require 'maint/Makefile.PL.include'
  if $Module::Install::AUTHOR;

WriteAll;
