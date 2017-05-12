#!/usr/bin/perl -w

use ExtUtils::MakeMaker;
use strict;

require 5.008;

WriteMakefile
(
  NAME         => 'Spreadsheet::XML_to_XLS',
  VERSION_FROM => 'lib/Spreadsheet/XML_to_XLS.pm',
  AUTHOR       => 'Radik Usmanov (radik.usmanov@ubs.com, rusmanov@luxoft.com)',
  BUILD_REQUIRES => {
    'XML::DOM' => '1.44',
    'Spreadsheet::WriteExcel' => '2.37'
  },
);
