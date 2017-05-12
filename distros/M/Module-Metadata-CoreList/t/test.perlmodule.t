use Capture::Tiny 'capture';

use Module::Metadata::CoreList;

use Test::More tests => 1;

# ------------------------

my($app) = Module::Metadata::CoreList -> new(module_name => 'warnings', perl_version => 5.008001);

my($stdout, $stderr, @result) = capture{$app -> check_perl_module};

my(@report) = map{s/^\s//; s/\s$//; $_} split(/\n/, $stdout);
my($expect) = <<EOS;
Module names which match the regexp qr/warnings/ in Perl V 5.008001: warnings, warnings::register.
EOS
my(@expect) = split(/\n/, $expect);

is_deeply(\@report, \@expect, 'Check output from (effectively) running cc.perlmodule.pl on module "warnings"');
