use strict;
use warnings;

use ExtUtils::MakeMaker;

my ($mode) = @ARGV;

my @warnings;
my @debugOpts;

if ($mode && $mode eq 'dev') {
   @warnings = qw{-Wall -Wmissing-declarations -Wundef
                  -Wimplicit -Winline
                  -Wstrict-prototypes -Wmissing-prototypes
                  -Werror};             
   @debugOpts = qw{-g}
} else {
  @warnings = ();
  @debugOpts = ();
}

my $xmlrpcConfigProg = 'xmlrpc-c-config';

my $xmlrpcVersion = qx{$xmlrpcConfigProg --version};

if ($xmlrpcVersion eq '') {
   print("You don't seem to have a '$xmlrpcConfigProg' shell command, " .
         "which probably means Xmlrpc-c is not installed.  Without that " .
         "program, we don't know how to link the Perl extension with " .
         "Xmlrpc-c.\n");
   exit(1);
} else {
    print("Found Xmlrpc-c library Version $xmlrpcVersion\n");

    my $xmlrpcLibs = qx{$xmlrpcConfigProg client --libs};

    my $xmlrpcInc  = qx{$xmlrpcConfigProg client --cflags};

    WriteMakefile(
                  'NAME'	 => 'RPC::Xmlrpc_c::Client::Curl',
                  'VERSION_FROM' => 'Curl.pm',
                  'LIBS'	 => $xmlrpcLibs,
                  'DEFINE'	 => '',
                  'INC'	         => $xmlrpcInc,
                  'CCFLAGS'      => join(' ', @warnings, @debugOpts),
                  );
}
