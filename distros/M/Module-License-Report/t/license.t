#!/usr/bin/perl

use warnings;
use strict;

BEGIN
{
   # GRR!!  I really HATE these stupid modules!
   # If you're going to override Perl, at least do it in a backward compatible way!!
   $INC{'UNIVERSAL/isa.pm'} = 1;
   $INC{'UNIVERSAL/can.pm'} = 1;
}

use lib qw(t/lib);
use Mockery;     # mockobject functions, in t/lib

BEGIN
{
   use Test::More tests => 28;
   use_ok("Module::License::Report");
}

my $cb = Mockery::create('Mockery::CPANPLUS::Backend');

#######################################################################
my $cp = Module::License::Report::CPANPLUS->new({cb => $cb});
ok($cp, 'new Module::License::Report::CPANPLUS');
ok($cp->get_module('Module::License::Report'), 'get_module');
ok($cp->get_module('Module::License::Report'), 'get_module, again');

ok($cp->set_host('http://example.com/path/to/files'), 'set_host');
is_deeply([$cb->__get_last_args()], ['hosts', [{scheme=>'http', host=>'example.com', path=>'/path/to/files'}]], 'set_host');
ok($cp->set_host('default'), 'set_host');
is_deeply([$cb->__get_last_args()], [], 'set_host');
ok(!$cp->set_host('mailto:fred@example.com'), 'set_host');
ok(!$cp->set_host(), 'set_host');

#######################################################################
my $reporter = Module::License::Report->new({cb => $cb});
ok($reporter, 'new Module::License::Report');

$reporter = Module::License::Report->new({cb => $cb, cpanhost => 'file://localhost/'});
ok($reporter, 'new Module::License::Report');

my $license = $reporter->license('Module-License-Report');
ok($license, 'license');

$license = $reporter->license('Module::License::Report');
ok($license, 'license');
is($license && "$license", 'perl', 'license name');
is($license && $license->confidence(), 100, 'confidence');
is($license && $license->source_file(), 'META.yml', 'source_file');
is($license && $license->source_filepath(), File::Spec->catfile(q{.},'META.yml'), 'source_filepath');
is($license && $license->source_name(), 'META.yml', 'source_name');
ok($license && $license->source_description(), 'source_description');
ok($license && $license->package_version(), 'package_version');


$license = $reporter->license('No::Such::Module');
is($license, undef, 'license, no such module');

$license = $reporter->license('No::License');
is($license, undef, 'license, no license');

$license = $reporter->license('Unknown::License');
is($license, undef, 'license, unknown license');

SKIP:
{
   eval { require Module::Depends; require Module::CoreList; };
   skip('Optional dependencies not installed', 4) if ($@);

   my %cmp = (
      'CPANPLUS'              => 'perl',
      'File-Slurp'            => 'perl',
      'Module-License-Report' => 'perl',
      'YAML'                  => 'perl',
   );
   
   my %lic = $reporter->license_chain('Module::License::Report');
   is_deeply(\%lic, \%cmp, 'license_chain');
   %lic = $reporter->license_chain('Module::License::Report');
   is_deeply(\%lic, \%cmp, 'license_chain, again');

   is($lic{CPANPLUS} && $lic{CPANPLUS}->source_file(), undef, 'source_file, dslip');
   is($lic{CPANPLUS} && $lic{CPANPLUS}->source_filepath(), undef, 'source_filepath, dslip');
}
