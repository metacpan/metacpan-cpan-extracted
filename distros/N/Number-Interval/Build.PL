#!perl

use strict;
use warnings;
use Module::Build;

# Set it up.
my $build = Module::Build->new
  (
   module_name => 'Number::Interval',
   license  => 'gpl2',
   dist_abstract => 'Representation of a numeric interval',
   dist_author => 'Tim Jenness <tjenness@cpan.org>',
   meta_merge => {
               resources =>  {repository => "git://github.com/timj/perl-Number-Interval.git",
                              homepage => "http://github.com/timj/perl-Number-Interval/tree/master",
                             },
                },
   build_requires => {
                      'Test::More' => 0,
                     },
  );

$build->create_build_script;
