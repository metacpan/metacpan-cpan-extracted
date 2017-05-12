use strict;
use lib qw(lib);
use Siesta::Build;

my $build = Siesta::Build->new(
    module_name => "Siesta",
    license     => 'perl',
    scripts     => [ 'bin/tequila', 'bin/nacho', 'bin/bandito' ],
    requires    => {
        'perl' => '5.006',
        'Apache::Session::SharedMem' => 0,
        'Class::Accessor::Fast' => 0,
        'Class::DBI' => '0.93', # older versions don't do TEMP properly
        'Class::DBI::BaseDSN' => 0,
        'Class::DBI::SQLite' => 0,
        'Digest::MD5' => 0,
        'Email::Folder' => 0,
        'Email::Simple' => '1.4',
        'Email::LocalDelivery' => '0.05',
        'File::Path' => 0,
        'File::Basename' => 0,
        'File::Find::Rule' => 0,
        'Mail::Address' => 0,
        'Mail::DeliveryStatus::BounceParser' => 0,
        # Module::Build 0.18 is the first release with
        # working scripts shebang rewriting
        'Module::Build' => '0.18',
        'Python::Serialise::Marshal' => 0,
        'Storable' => 0,
        'String::Random' => 0,
        'String::ShellQuote' => 0,
        'Sys::Hostname' => 0,
        'Test::More' => 0,
        'Tie::IxHash' => 0,
        'Template' => 0,
        'UNIVERSAL::require' => 0,
        'YAML'               => 0,
    },
    create_makefile_pl => 'passthrough',
    dynamic_config => 1,
   );

$build->{config}{__extras_from} = [ 'messages', 'web-frontend' ];

$|= 1;
print "Checking for existing Siesta::Config... ";

my $D_ROOT = '/usr/local/siesta';
eval {
    require Siesta::Config;
    print "found. setting defaults based on existing install\n";
    $D_ROOT = $Siesta::Config::ROOT;
};

print "failed. selecting regular defaults\n"
  if $@;

my $ROOT = $build->prompt("where do we install to guv?", $D_ROOT);

print "Generating Siesta::Config from your answers\n";
open(IN,  "<Config.pm.in")
  or die "couldn't open Config.pm.in: $!";
open(OUT, ">lib/Siesta/Config.pm")
  or die "couldn't open Config.pm for write: $!";
while (<IN>) {
    s'@@ROOT@@'$ROOT'e;
    print OUT $_;
}
close IN  or die "error closing Config.pm.in: $!";
close OUT or die "error closing Config.pm: $!";

$build->{config}{__extras_destination} = $ROOT;

$build->create_build_script;
