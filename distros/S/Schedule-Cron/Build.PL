#!/usr/bin/perl
use Module::Build;
my $build = Module::Build->new
  (
   module_name => "Schedule::Cron",
   dist_author => 'Roland Huss (roland@cpan.org)',
   abstract => 'Cron-like scheduler for Perl subroutines',
   distribution_type => 'module',
   installdirs => 'site',

   license => "perl",
   
   requires => {
                "Time::ParseDate" => "2011.0505",
                "Data::Dumper" => "0"
               },
   
   build_requires => {
                      "Test::More" => "0",
                      "Test" => "0",
                     },                       
   keywords => [  "Cron", "Scheduler", "Job" ],
   provides => {
                "Schedule::Cron" => {
                               file =>  "lib/Schedule/Cron.pm"
                              }
               },
   configure_requires => { 'Module::Build' => 0}
  );
$build->create_build_script;
