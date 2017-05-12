use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Net::Async::Matrix',
   requires => {
      'Data::Dump' => 0,
      'Future::Utils' => 0,
      'IO::Async::Notifier' => '0.63',
      'JSON::MaybeXS' => 0,
      'List::Util' => '1.29',
      'Net::Async::HTTP' => '0.36',
      'POSIX' => 0,
      'String::Tagged' => '0.12',
      'Struct::Dumb' => 0,
      'URI' => 0,
   },
   recommends => {
      'Digest::HMAC_MD5' => 0,

      # For formatted message support
      'Convert::Color::HTML' => 0,
      'HTML::TreeBuilder' => '5',
      'String::Tagged::HTML' => 0,
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
      'Test::Async::HTTP' => '0.02',
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_makefile_pl => 'small',
   create_license => 1,
   create_readme  => 1,
   meta_merge => {
      resources => {
         x_IRC => "irc://irc.perl.org/#io-async",
      },
   },
);

$build->create_build_script;
