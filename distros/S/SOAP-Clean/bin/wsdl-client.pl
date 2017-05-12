#! /usr/bin/env perl

# Copyright (c) 2003, Cornell University
# See the file COPYING for the status of this software

# Try,
#
# ./wsdl-client.pl 'cgifile:./soap-server.cgi?wsdl' --usage
# ./wsdl-client.pl http://www.xmethods.net/sd/TemperatureService.wsdl --usage
# ./wsdl-client.pl http://www.xmethods.net/sd/TemperatureService.wsdl getTemp zipcode=14853
# ./wsdl-client.pl http://ctcstager.tc.cornell.edu/Users/heber/Persistence/Persistence.asmx?WSDL --usage
# ./wsdl-client.pl http://ctcstager.tc.cornell.edu/Users/heber/Persistence/Persistence.asmx?WSDL TestMath x=10 y=12

use strict;
use warnings;

use File::Basename;

#use lib dirname($0).'/..';

use SOAP::Clean::Misc;
use SOAP::Clean::XML;
use SOAP::Clean::Client;

use Getopt::Long;

my $verbose = 0;
my $help = 0;
my $usage = 0;

my $status = GetOptions('verbose+' => \$verbose,
			'usage' => \$usage,
			'help' => \$help);

if ( !$status || $help ) { usage($status); }

my $wsdl_url = shift @ARGV;
if ( !defined($wsdl_url) ) {
  print STDERR "No WSDL URL specified\n";
  usage(2);
}

my $c = new SOAP::Clean::Client($wsdl_url);
if ( $verbose ) { $c->verbose($verbose); }

my $usage_data = $c->usage();

if ( $usage ) {

  foreach my $method_name ( sort(keys %$usage_data) ) {
    my $method_data = $$usage_data{$method_name};
    print "$method_name\n";
    foreach my $direction ( "input", "output" ) {
      print "  $direction:\n";
      my $args = $$method_data{$direction};
      foreach my $arg ( keys %$args ) {
	print "    $arg: ",$$args{$arg},"\n";
      }
    }
  }

  goto EXIT;
}

my $method_name = shift @ARGV;
defined($method_name) || die "No method name specified";

my $method_data = $$usage_data{$method_name};
defined($method_data) || die "No such method. Try --usage to get a list";
my $in_args = $$method_data{input};
my $out_args = $$method_data{output};

my %arg_data = ();
my %arg_mech = ();
foreach my $arg ( @ARGV ) {
  if ( $arg =~ /^([^=]+)=(.*)$/ ) {
    $arg_data{$1} = $2;
    $arg_mech{$1} = 'value';
  } elsif ( $arg =~ /^([^:]+):(.*)$/ ) {
    $arg_data{$1} = $2;
    $arg_mech{$1} = 'file';
  } elsif ( $arg =~ /^([^:]+)\?$/ ) {
    $arg_mech{$1} = 'status';
  } else {
    die "Ill-formed argument: $arg";
  }
}

my $args = {};
foreach my $in_arg_name ( keys %$in_args ) {
  my $optional=0;
  my $in_arg_type = $$in_args{$in_arg_name};
  if ( $in_arg_type =~ /^optional\s+(.*)/ ) {
    $optional = 1;
    $in_arg_type = $1;
  }
  my $mech = $arg_mech{$in_arg_name};
  assert($optional || defined($mech),
	 "Missing input argument: $in_arg_name");
  if ( !defined($mech) ) {
    # Optional argument without a value.
  } elsif (  $mech eq 'value' ) {
    if ( $in_arg_type eq "xml" ) {
      $$args{$in_arg_name} = xml_from_string($arg_data{$in_arg_name});
    } else {
      $$args{$in_arg_name} = $arg_data{$in_arg_name};
    }
  } elsif ( $mech eq 'file' ) {
    my $filename = $arg_data{$in_arg_name};
    if ( ! ( -f $filename && -r $filename ) ) {
      die "Cannot read file $filename";
    }
    if ($in_arg_type eq "raw" ) {
      open F, "<".$filename
	|| die("Can't open file $filename");
      binmode F;
      my $out_len = sysseek F,0,2; # how long is the file.
      sysseek F,0,0;		# jump back to the beginning.
      my $out_str;
      sysread F,$out_str,$out_len;
      $$args{$in_arg_name} = $out_str;
    } elsif ( $in_arg_type eq "xml" ) {
      $$args{$in_arg_name} = xml_from_file($filename);
    } else {
      $$args{$in_arg_name} = `cat $filename`;
    }
  } elsif ( $mech eq 'status' ) {
    die "Input paramaters cannot be specified as status argument"
  } else {
    die "Bad mechanism - $mech";
  }
}

my $results = $c->invoke($method_name,$args);

my $exit_status;

# fixme: bools are printed as 0 and 1. Is that right?
foreach my $out_arg_name ( keys %$out_args ) {
  my $out_arg_type = $$out_args{$out_arg_name};
  my $optional = 0;
  if ( $out_arg_type =~ /^optional\s+(.*)/ ) {
    $optional = 1;
    $out_arg_type = $1;
  }
  my $data = $arg_data{$out_arg_name};
  my $mech = $arg_mech{$out_arg_name};
  defined($mech) || ( $mech = 'value' );
  my $result = $$results{$out_arg_name};

  if ( $mech eq 'value' ) {
    if ( $out_arg_type eq "xml" ) {
      print $out_arg_name,"=",xml_to_string($result),"\n";
    } else {
      print $out_arg_name,"=",$result,"\n";
    }
  } elsif ( $mech eq 'file' ) {
    if ( $out_arg_type eq "raw" ) {
      open F,">$data" || die;
      binmode F;
      syswrite F, $result;
      close F || die;
    } elsif ( $out_arg_type eq "xml" ) {
      xml_to_file($result,$data);
    } else {
      open F,">$data" || die;
      print F $result,"\n";
      close F;
    }
  } elsif ( $mech eq 'status' ) {
    !defined($exit_status)
      || die "More than one output parameter specified as the exit status";
    if ( $out_arg_type eq "bool" || $out_arg_type eq "int" ) {
      # exit codes: true -> 0, false -> 1
      $exit_status = ( $result ? 0 : 1 );
    } else {
      die "Cannot convert type $out_arg_type to exit status";
    }
  } else {
    die "Bad mechanism - $mech";
  }
}

########################################################################

EXIT:

if ( $verbose ) {
  print "##################################################\n";
  print "HTTP Statistics:\n";
  my ($request_count,$response_count) = $c->counts();
  print "Request count = ",$request_count,"\n";
  print "Response count = ",$response_count,"\n";
}

defined($exit_status) || ( $exit_status = 0 );
exit($exit_status);

########################################################################

sub usage {
  my ($stat) = @_;
  print "Usage: $0 [--help] [--verbose] wsdl [--usage] params ...\n";
  exit($stat);
}

