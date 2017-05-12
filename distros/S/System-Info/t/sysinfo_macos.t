#! perl -w
use strict;

# We need at least 5.9.5 for the CORE::GLOBEL::readpipe () override
my $not595;
BEGIN { eval qq/use 5.009005/; $not595 = $@ }

use Test::More $not595
    ? ( skip_all => "This is only version $] (needs 5.9.5)" )
    : "no_plan";

use Carp qw( cluck );
our $DEBUG = 0;

require System::Info::Darwin;

my %output = (
    mini_intel => {
	uname  => "Mac mini (1.83 GHz) 1 [2 cores] Intel Core Duo",
	output => <<"__EOOUT__" },
Hardware:
    Hardware Overview:
      Model Name: Mac mini
      Model Identifier: Macmini1,1
      Processor Name: Intel Core Duo
      Processor Speed: 1.83 GHz
      Number Of Processors: 1
      Total Number Of Cores: 2
      L2 Cache (per processor): 2MB
      Memory: 1 GB
      Bus Speed: 667 MHz
      Boot ROM Version: MM11.0055.B08
      SMC Version: 1.3f4
__EOOUT__

    ibook_g4 => {
	uname  => "iBook G4 (1.07 GHz) 1 macppcG4",
	output => <<"__EOOUT__" },
Hardware:

    Hardware Overview:

      Machine Name: iBook G4
      Machine Model: PowerBook6,5
      CPU Type: PowerPC G4  (1.1)
      Number Of CPUs: 1
      CPU Speed: 1.07 GHz
      L2 Cache (per CPU): 512 KB
      Memory: 768 MB
      Bus Speed: 133 MHz
      Boot ROM Version: 4.8.5f0
__EOOUT__

    macbook_pro => {
	uname  => "MacBook Pro (2.4 GHz) 1 [2 cores] Intel Core 2 Duo",
	output => <<"__EOOUT__" },
Hardware:

    Hardware Overview:

      Model Name: MacBook Pro
      Model Identifier: MacBookPro7,1
      Processor Name: Intel Core 2 Duo
      Processor Speed: 2.4 GHz
      Number Of Processors: 1
      Total Number Of Cores: 2
      L2 Cache: 3 MB
      Memory: 8 GB
      Bus Speed: 1.07 GHz
      Boot ROM Version: MBP71.0039.B0B
      SMC Version (system): 1.62f7
      Sudden Motion Sensor:
	  State: Enabled
__EOOUT__
    );

our $OUTPUT;
sub fake_qx {
    $DEBUG and cluck ("<$_[0]>");

    $_[0] =~ m{/usr/sbin/system_profiler}
	? $OUTPUT
	: CORE::readpipe ($_[0]);
    } # fake_qx

BEGIN { *CORE::GLOBAL::readpipe = \&fake_qx }

for my $model (keys %output) {
    $OUTPUT = $output{$model}{output};

    local $^O = "Darwin";
    my $info = System::Info::Darwin->new;
    is $info->si_uname ("m c p"), $output{$model}{uname}, $output{$model}{uname};
    }
