#!/usr/bin/perl
#
# $Id: sinfp3.pl,v 42a38f4bde90 2015/11/25 06:26:55 gomor $
#
use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

my %lopts = ();
GetOptions(
   "version"            => \$lopts{version},
   "help"               => \$lopts{help},

   # Global options
   "target=s"           => \$lopts{target},
   "port=s"             => \$lopts{port},
   "port-src=i"         => \$lopts{port_src},
   "6"                  => \$lopts{6},
   "jobs=i"             => \$lopts{jobs},
   "dns-reverse"        => \$lopts{dns_reverse},
   "device=s"           => \$lopts{device},
   "thread"             => \$lopts{thread},
   "retry=i"            => \$lopts{retry},
   "timeout=i"          => \$lopts{timeout},
   "pps=i"              => \$lopts{pps},
   "ip-src=s"           => \$lopts{ip_src},
   "ip6-src=s"          => \$lopts{ip6_src},
   "mac-src=s"          => \$lopts{mac_src},
   "subnet-src=s"       => \$lopts{subnet_src},
   "subnet6-src=s"      => \$lopts{subnet6_src},
   "ip-gateway=s"       => \$lopts{ip_gateway},
   "ip6-gateway=s"      => \$lopts{ip6_gateway},
   "mac-gateway=s"      => \$lopts{mac_gateway},
   "verbose=i"          => \$lopts{verbose},
   "quiet"              => \$lopts{quiet},
   "threshold=i"        => \$lopts{threshold},
   "best-score"         => \$lopts{best_score},
   "passive"            => \$lopts{passive},

   # Generic options
   "input=s"            => \$lopts{input},
   "input-arg=s%"       => \$lopts{input_arg},
   "db=s"               => \$lopts{db},
   "db-arg=s%"          => \$lopts{db_arg},
   "mode=s"             => \$lopts{mode},
   "mode-arg=s%"        => \$lopts{mode_arg},
   "search=s"           => \$lopts{search},
   "search-arg=s%"      => \$lopts{search_arg},
   "output=s"           => \$lopts{output},
   "output-arg=s%"      => \$lopts{output_arg},

   # Plugin-loading options
   "input-null"        => \$lopts{input_null},
   "input-arpdiscover" => \$lopts{input_arpdiscover},
   "input-pcap"        => \$lopts{input_pcap},
   "input-synscan"     => \$lopts{input_synscan},
   "input-ipport"      => \$lopts{input_ipport},
   "input-sniff"       => \$lopts{input_sniff},
   "input-signature"   => \$lopts{input_signature},
   "input-signaturep"  => \$lopts{input_signaturep},
   "input-connect"     => \$lopts{input_connect},
   "input-server"      => \$lopts{input_server},
   "mode-null"         => \$lopts{mode_null},
   "mode-active"       => \$lopts{mode_active},
   "mode-passive"      => \$lopts{mode_passive},
   "db-null"           => \$lopts{db_null},
   "db-sinfp3"         => \$lopts{db_sinfp3},
   "search-null"       => \$lopts{search_null},
   "search-active"     => \$lopts{search_active},
   "search-passive"    => \$lopts{search_passive},
   "log-null"          => \$lopts{log_null},
   "log-console"       => \$lopts{log_console},
   "output-null"            => \$lopts{output_null},
   "output-console"         => \$lopts{output_console},
   "output-csv"             => \$lopts{output_csv},
   "output-dumper"          => \$lopts{output_dumper},
   "output-osonly"          => \$lopts{output_osonly},
   "output-osversionfamily" => \$lopts{output_osversionfamily},
   "output-pcap"            => \$lopts{output_pcap},
   "output-ubigraph"        => \$lopts{output_ubigraph},
   "output-simple"          => \$lopts{output_simple},
   "output-client"          => \$lopts{output_client},

   # Plugin-specific options
   "db-update"           => \$lopts{db_update},
   "db-file=s"           => \$lopts{db_file},
   "sniff-promiscuous"   => \$lopts{sniff_promiscuous},
   "pcap-anonymize"      => \$lopts{pcap_anonymize},
   "pcap-append"         => \$lopts{pcap_append},
   "pcap-filter=s"       => \$lopts{pcap_filter},
   "pcap-file=s"         => \$lopts{pcap_file},
   "active-1"            => \$lopts{active_1},
   "active-2"            => \$lopts{active_2},
   "active-3"            => \$lopts{active_3},
   "synscan-fingerprint" => \$lopts{synscan_fingerprint},
   "csv-file=s"          => \$lopts{csv_file},

) or pod2usage(2);

if ($lopts{version}) {
   use Class::Gomor;
   use DBD::SQLite;
   use Net::Libdnet;
   use Net::Frame;
   use Net::Frame::Device;
   use Net::Frame::Dump;
   use Net::Frame::Layer::ICMPv6;
   use Net::Frame::Layer::IPv6;
   use Net::Frame::Layer::SinFP3;
   use Net::Frame::Simple;
   use Net::Write;
   use Net::Write::Fast;
   print
      "\n  -- SinFP3 - $Net::SinFP3::VERSION --\n".
      "\n".
      '   $Id: sinfp3.pl,v 42a38f4bde90 2015/11/25 06:26:55 gomor $'."\n".
      "\n  -- Perl modules --\n\n".
      "  o Class::Gomor              - $Class::Gomor::VERSION\n".
      "  o DBD::SQLite               - $DBD::SQLite::VERSION\n".
      "  o Net::Libdnet              - $Net::Libdnet::VERSION\n".
      "  o Net::Frame                - $Net::Frame::VERSION\n".
      "  o Net::Frame::Device        - $Net::Frame::Device::VERSION\n".
      "  o Net::Frame::Dump          - $Net::Frame::Dump::VERSION\n".
      "  o Net::Frame::Layer::ICMPv6 - $Net::Frame::Layer::ICMPv6::VERSION\n".
      "  o Net::Frame::Layer::IPv6   - $Net::Frame::Layer::IPv6::VERSION\n".
      "  o Net::Frame::Layer::SinFP3 - $Net::Frame::Layer::SinFP3::VERSION\n".
      "  o Net::Frame::Simple        - $Net::Frame::Simple::VERSION\n".
      "  o Net::Write                - $Net::Write::VERSION\n".
      "  o Net::Write::Fast          - $Net::Write::Fast::VERSION\n".
      "\n";
   exit(0);
}
elsif ($lopts{help}) {
   pod2usage(1);
}

# Load required modules
use Net::SinFP3;
use Net::SinFP3::Global;
use Net::SinFP3::Log::Null;
use Net::SinFP3::Log::Console;
use Net::SinFP3::Input::Null;
use Net::SinFP3::Input::IpPort;
use Net::SinFP3::Input::Pcap;
use Net::SinFP3::Input::ArpDiscover;
use Net::SinFP3::Input::Server;
use Net::SinFP3::Input::SynScan;
use Net::SinFP3::Input::Sniff;
use Net::SinFP3::Input::Signature;
use Net::SinFP3::Input::SignatureP;
use Net::SinFP3::Input::Connect;
use Net::SinFP3::DB::Null;
use Net::SinFP3::DB::SinFP3;
use Net::SinFP3::Mode::Null;
use Net::SinFP3::Mode::Active;
use Net::SinFP3::Mode::Passive;
use Net::SinFP3::Search::Null;
use Net::SinFP3::Search::Active;
use Net::SinFP3::Search::Passive;
use Net::SinFP3::Output::Null;
use Net::SinFP3::Output::Client;
use Net::SinFP3::Output::Console;
use Net::SinFP3::Output::Simple;
use Net::SinFP3::Output::CSV;
use Net::SinFP3::Output::Dumper;
use Net::SinFP3::Output::OsOnly;
use Net::SinFP3::Output::OsVersionFamily;
use Net::SinFP3::Output::Pcap;
use Net::SinFP3::Output::Ubigraph;

# Set global default values
$lopts{6}           ||= 0;
$lopts{jobs}        ||= 10;
$lopts{dns_reverse} ||= 0;
$lopts{thread}      ||= 0;
$lopts{retry}       ||= 3;
$lopts{timeout}     ||= 3;
$lopts{pps}         ||= 300;
$lopts{port}        ||= 'top10';
$lopts{port_src}    ||= 53;
$lopts{threshold}   ||= 70;
$lopts{best_score}  ||= 0;
$lopts{verbose}     ||= 1;
$lopts{passive}     ||= 0;
if ($lopts{quiet}) {
   $lopts{verbose} = 0;
}

# Set default plugin options
$lopts{input_synscan}  ||= 1;
$lopts{mode_active}    ||= 1;
$lopts{db_sinfp3}      ||= 1;
$lopts{search_active}  ||= 1;
$lopts{log_console}    ||= 1;
$lopts{output_simple}  ||= 1;

# Set default plugin-specific values
$lopts{db_update}           ||= 0;
$lopts{sniff_promiscuous}   ||= 1;
$lopts{pcap_anonymize}      ||= 0;
$lopts{pcap_append}         ||= 0;
$lopts{synscan_fingerprint} ||= 0;
$lopts{csv_file}            ||= 'sinfp3-output.csv';

#
# Prepare log module
#
my $log;
if ($lopts{log}) {
   $log = loadModule('Log', 'log', 'log_arg', \%lopts);
}
elsif ($lopts{log_null}) {
   $log = Net::SinFP3::Log::Null->new or exit(1);
}
# Default
elsif ($lopts{log_console}) {
   $log = Net::SinFP3::Log::Console->new(
      level => $lopts{verbose},
   ) or exit(1);
}
$log->init;

# Prepare global configuration
my $worker = 'Fork';
if ($lopts{thread}) {
   $worker = 'Thread';
}
my %args = (
   log        => $log,
   worker     => $worker,
   ipv6       => $lopts{6},
   dnsReverse => $lopts{dns_reverse},
   jobs       => $lopts{jobs},
   retry      => $lopts{retry},
   timeout    => $lopts{timeout},
   pps        => $lopts{pps},
   threshold  => $lopts{threshold},
   bestScore  => $lopts{best_score},
);
if ($lopts{device}) {
   $args{device} = $lopts{device};
}
if ($lopts{target}) {
   $args{target} = $lopts{target};
}
if ($lopts{port}) {
   $args{port} = $lopts{port};
}
if ($lopts{ip_src}) {
   $args{ip} = $lopts{ip_src};
}
if ($lopts{ip6_src}) {
   $args{ip6} = $lopts{ip6_src};
}
if ($lopts{mac_src}) {
   $args{mac} = $lopts{mac_src};
}
if ($lopts{ip_gateway}) {
   $args{gatewayIp} = $lopts{ip_gateway};
}
if ($lopts{ip6_gateway}) {
   $args{gatewayIp6} = $lopts{ip6_gateway};
}
if ($lopts{subnet}) {
   $args{subnet} = $lopts{subnet};
}
if ($lopts{subnet6}) {
   $args{subnet6} = $lopts{subnet6};
}
if ($lopts{mac_gateway}) {
   $args{gatewayMac} = $lopts{mac_gateway};
}
my $global = Net::SinFP3::Global->new(%args) or exit(1);

# Prepare plugins
my @input  = ();
my @db     = ();
my @mode   = ();
my @search = ();
my @output = ();

#
# Prepare DB module
#
if ($lopts{db_null}) {
   push @db, Net::SinFP3::DB::Null->new(
      global => $global,
   ) or exit(1);
}
elsif ($lopts{db_update}) {
   # If user wants to update its database
   my %args = (
      global => $global,
   );
   if ($lopts{db_file}) {
      $args{file} = $lopts{db_file};
   }
   my $db = Net::SinFP3::DB::SinFP3->new(%args) or exit(1);
   $db->update;
   $log->post;
   exit(0);
}
elsif ($lopts{db}) {
   push @db, loadModule('DB', 'db', 'db_arg', \%lopts, $global);
}
# Default
elsif ($lopts{db_sinfp3}) {
   my %args = (
      global => $global,
   );
   if ($lopts{db_file}) {
      $args{file} = $lopts{db_file};
   }
   push @db, Net::SinFP3::DB::SinFP3->new(%args) or exit(1);
}

#
# Prepare Input module
#
if ($lopts{input}) {
   push @input, loadModule('Input', 'input', 'input_arg', \%lopts, $global);
}
elsif ($lopts{input_null}) {
   push @input, Net::SinFP3::Input::Null->new(
      global => $global,
   ) or exit(1);
}
elsif ($lopts{input_ipport}) {
   if (! $lopts{target}) {
      $log->fatal("You must provide -target argument");
   }
   push @input, Net::SinFP3::Input::IpPort->new(
      global => $global,
   ) or exit(1);
}
elsif ($lopts{input_arpdiscover}) {
   push @input, Net::SinFP3::Input::ArpDiscover->new(
      global => $global,
   ) or exit(1);
}
elsif ($lopts{input_sniff}) {
   my $input = Net::SinFP3::Input::Sniff->new(
      global  => $global,
      promisc => $lopts{sniff_promiscuous},
   ) or exit(1);
   $input->filter($lopts{pcap_filter}) if $lopts{pcap_filter};
   push @input, $input;
}
elsif ($lopts{input_signature}) {
   push @input, Net::SinFP3::Input::Signature->new(
      global => $global,
   ) or exit(1);
}
elsif ($lopts{input_signaturep}) {
   push @input, Net::SinFP3::Input::SignatureP->new(
      global => $global,
   ) or exit(1);
}
elsif ($lopts{input_connect}) {
   if (! $lopts{target}) {
      $log->fatal("You must provide -target argument");
   }
   push @input, Net::SinFP3::Input::Connect->new(
      global => $global,
   ) or exit(1);
}
elsif ($lopts{input_server}) {
   push @input, Net::SinFP3::Input::Server->new(
      global => $global,
   ) or exit(1);
}
elsif ($lopts{input_pcap}) {
   if (! $lopts{pcap_file}) {
      $log->fatal("You must provide -pcap-file argument");
   }
   if ($lopts{mode_passive}) {
      my $input = Net::SinFP3::Input::Pcap->new(
         global => $global,
         file   => $lopts{pcap_file},
      ) or exit(1);
      $input->filter($lopts{pcap_filter}) if $lopts{pcap_filter};
      push @input, $input;
   }
   elsif ($lopts{mode_active}) {
      push @input, Net::SinFP3::Input::Pcap->new(
         global => $global,
         file   => $lopts{pcap_file},
         count  => 10,
      ) or exit(1);
   }
}
# Default
elsif ($lopts{input_synscan}) {
   if (! $lopts{target}) {
      $log->fatal("You must provide -target or -input-sniff argument, ".
                  "or try -help for usage");
   }
   push @input, Net::SinFP3::Input::SynScan->new(
      global => $global,
      fingerprint => $lopts{synscan_fingerprint},
   ) or exit(1);
}

#
# Prepare output module
#
if ($lopts{output}) {
   push @output, loadModule('Output', 'output', 'output_arg', \%lopts, $global);
}
elsif ($lopts{output_null}) {
   push @output, Net::SinFP3::Output::Null->new(
      global => $global,
   ) or exit(1);
}
elsif ($lopts{output_dumper}) {
   push @output, Net::SinFP3::Output::Dumper->new(
      global => $global,
   ) or exit(1);
}
elsif ($lopts{output_osonly}) {
   push @output, Net::SinFP3::Output::OsOnly->new(
      global => $global,
   ) or exit(1);
}
elsif ($lopts{output_osversionfamily}) {
   push @output, Net::SinFP3::Output::OsVersionFamily->new(
      global => $global,
   ) or exit(1);
}
elsif ($lopts{output_csv}) {
   push @output, Net::SinFP3::Output::CSV->new(
      global => $global,
      file   => $lopts{csv_file},
   ) or exit(1);
}
elsif ($lopts{output_ubigraph}) {
   push @output, Net::SinFP3::Output::Ubigraph->new(
      global => $global,
      file   => $lopts{csv_file},
   ) or exit(1);
}
elsif ($lopts{output_console}) {
   push @output, Net::SinFP3::Output::Console->new(
      global => $global,
   ) or exit(1);
}
elsif ($lopts{output_client}) {
   push @output, Net::SinFP3::Output::Client->new(
      global => $global,
   ) or exit(1);
}
# Default
elsif ($lopts{output_simple}) {
   push @output, Net::SinFP3::Output::Simple->new(
      global => $global,
   ) or exit(1);
}
# We use multiple output module for this one
if (!$lopts{output_null} && $lopts{output_pcap}) {
   push @output, Net::SinFP3::Output::Pcap->new(
      global    => $global,
      anonymize => $lopts{pcap_anonymize},
      append    => $lopts{pcap_append},
   ) or exit(1);
}

#
# Prepare mode
#
if ($lopts{mode}) {
   push @mode, loadModule('Mode', 'mode', 'mode_arg', \%lopts, $global);
}
elsif ($lopts{mode_null}) {
   push @mode, Net::SinFP3::Mode::Null->new(
      global => $global,
   ) or exit(1);
}
elsif ($lopts{mode_passive} || $lopts{passive}) {
   push @mode, Net::SinFP3::Mode::Passive->new(
      global => $global,
   ) or exit(1);
}
# Default
elsif ($lopts{mode_active}) {
   my %args = (
      global => $global,
   );
   if ($lopts{active_3}) {
      $args{doP1} = 1;
      $args{doP2} = 1;
      $args{doP3} = 1;
   }
   elsif ($lopts{active_2}) {
      $args{doP1} = 1;
      $args{doP2} = 1;
      $args{doP3} = 0;
   }
   elsif ($lopts{active_1}) {
      $args{doP1} = 0;
      $args{doP2} = 1;
      $args{doP3} = 0;
   }
   else {  # Default for -active-2
      $args{doP1} = 1;
      $args{doP2} = 1;
      $args{doP3} = 0;
   }
   push @mode, Net::SinFP3::Mode::Active->new(%args) or exit(1);
}

#
# Prepare search engine
#
if ($lopts{search}) {
   push @search, loadModule('Search', 'search', 'search_arg', \%lopts, $global);
}
elsif ($lopts{search_null}) {
   push @search, Net::SinFP3::Search::Null->new(
      global => $global,
   ) or exit(1);
}
elsif ($lopts{search_passive} || $lopts{passive}) {
   push @search, Net::SinFP3::Search::Passive->new(
      global => $global,
   ) or exit(1);
}
# Default
elsif ($lopts{search_active}) {
   push @search, Net::SinFP3::Search::Active->new(
      global => $global,
   ) or exit(1);
}

# Ready to run, my lord
my $sinfp = Net::SinFP3->new(
   global => $global,
   input  => \@input,
   db     => \@db,
   mode   => \@mode,
   search => \@search,
   output => \@output,
) or exit(1);

$sinfp->run;

$log->post;

exit(0);

sub loadModule {
   my ($kind, $module, $values, $lopts, $global) = @_;

   my $mod = 'Net::SinFP3::'.$kind.'::'.$lopts->{$module};
   $log->debug("Loading module [$mod]");
   eval "use $mod";
   if ($@) {
      chomp($@);
      $log->fatal("$kind module [$mod] loading failed with error [$@]");
   }
   my $new = $mod->new(
      global => $global,
      %{$lopts->{$values}},
   ) or exit(1);
   if ($new->can('ipv6')) {
      $new->ipv6($lopts->{6});
   }
   return $new;
}

__END__

=head1 NAME

sinfp3.pl - more than a passive and active OS fingerprinting tool

=head1 SYNOPSIS

   o Information about signature database updates and more:
   o https://www.secure-side.com/lists/mailman/listinfo/sinfp

sinfp3.pl [options] -target ip|ip6|hostname -port port|portList

Examples:

   # Single port active fingerprinting
   sinfp3.pl -target example.com -port 80 -input-ipport

   # Single port IPv6 active fingerprinting
   sinfp3.pl -target example.com -port 80 -input-ipport -6

   # SynScan active fingerprinting of a single target
   sinfp3.pl -target example.com -port top100

   # SynScan IPv6 active fingerprinting of a single target
   sinfp3.pl -target example.com -port top100 -6

   # SynScan active fingerprinting of a target subnet
   sinfp3.pl -target 192.0.43.0/24 -port top100

   # Passive fingerprinting
   sinfp3.pl -mode-passive -search-active -input-sniff

   # Passive IPv6 fingerprinting
   sinfp3.pl -mode-passive -search-active -input-sniff -6

   # Active fingerprinting of LAN
   sinfp3.pl -input-arpdiscover

   # Active fingerprinting of IPv6 LAN
   sinfp3.pl -input-arpdiscover -6

   # Simply SynScan the target
   sinfp3.pl -target example.com -port full -mode-null -search-null -db-null

=head1 OPTIONS

=over 4

=item B<Global:>

=over 8

=item B<-version>

Print B<sinfp3.pl> version.

=item B<-help>

This help message.

=item B<-target> ip|ip6|hostname

Target. This is used to auto-detect some global parameters like B<device> or B<ip>.

=item B<-port> port|portList|top10|top100|top1000|all

Target port. Default for top10 ports for plugins able to handle multiple ports. This format is documented in `perldoc Net::SinFP3::Global' B<expandPorts> method.

=item B<-port-src> port

Source port to use. Not supported by all plugins.

=item B<-passive>

Use passive fingerprinting. Default to use active one.

=item B<-6>

Use IPv6 fingerprinting where available. Default to off.

=item B<-jobs> number

Maximum number of jobs in parallel. Default: 10.

=item B<-dns-reverse>

Do a reverse DNS lookup for targets. Default to no.

=item B<-device> name

Network device to use. Default to auto-detect.

=item B<-thread>

Use threaded worker model (discouraged). Fork is used by default (and in Perl, it is better than ithreads).

=item B<-retry> times

Re-launch probes specified number of time. Default: 3.

=item B<-timeout> seconds

Time in seconds before timing out. Default: 3.

=item B<-pps> number

Number of packet per seconds. Default: 200.

=item B<-ip-src> ip

The source IPv4 address to use. Default to auto-detect.

=item B<-ip6-src> ip6

The source IPv6 address to use. Default to auto-detect.

=item B<-mac-src> mac

The source MAC address to use. Default to auto-detect.

=item B<-subnet-src> subnet

The source IPv4 subnet address to use. Default to auto-detect.

=item B<-subnet6-src> subnet

The source IPv6 subnet address to use. Default to auto-detect.

=item B<-ip-gateway> ip

The gateway IPv4 address to use. Default to auto-detect.

=item B<-ip6-gateway> ip6

The gateway IPv6 address to use. Default to auto-detect.

=item B<-mac-gateway> mac

The gateway MAC address to use. Default to auto-detect.

=item B<-verbose> level

Use the following verbose level number. Between 0 and 3, from the less verbose to the most verbose. Default to 1.

=item B<-quiet>

Set verbose level to 0. Default to not.

=item B<-threshold> score

Use the specified threshold for plugins supporting it. Default to no threshold (0).

=item B<-best-score>

Only gather results for the best matches. Default to not.

=back

=back

=over 4

=item B<Manually select all plugins and their options:>

=over 8

=item B<-input> plugin

Use specified plugin for input. Default input plugin is L<Net::SinFP3::Input::SynScan>.

=item B<-input-arg> plugin-arg

Parameter to the specified input plugin. Must use multiple times to give multiple parameters.

=item B<-db> plugin

Use specified plugin for db. Default DB plugin is L<Net::SinFP3::DB::SinFP3>.
Example: L<sinfp3.pl -db SinFP3 -db-arg file=sinfp3.db>.

=item B<-db-arg> plugin-arg

Parameter to the specified db plugin. Must use multiple times to give multiple parameters.

=item B<-mode> plugin

Use specified plugin for mode. Default mode plugin is L<Net::SinFP3::Mode::Active>.

=item B<-mode-arg> plugin-arg

Parameter to the specified mode plugin. Must use multiple times to give multiple parameters.

=item B<-search> plugin

Use specified plugin for search. Default search plugin is L<Net::SinFP3::Search::Active>.

=item B<-search-arg> plugin-arg

Parameter to the specified search plugin. Must use multiple times to give multiple parameters.

=item B<-output> plugin

Use specified plugin for output. Default output plugin is L<Net::SinFP3::Output::Console>.

=item B<-output-arg> plugin-arg

Parameter to the specified output plugin. Must use multiple times to give multiple parameters.

=back

=back

=over 4

=item B<Plugin loading options:>

=over 8

=item B<-input-null>

Turn off input plugin.

=item B<-input-arpdiscover>

Use ARP scanning on the local subnet to discover targets. Works also with B<-6> argument.

=item B<-input-pcap>

Take a pcap file (or files) as input.

=item B<-input-synscan>

Perform a TCP SYN scan to find open ports. Default plugin.

=item B<-input-ipport>

Use only target IP or hostname and one port.

=item B<-input-sniff>

Listen on the network to capture frames.

=item B<-input-signature>

Will ask the end-user to past an active signature as a string.

=item B<-input-signaturep>

Will ask the end-user to past a passive signature as a string.

=item B<-input-connect>

Performs a standard TCP connect() and sends a "GET /HTTP/1.0". Then, it analyzes the SYN|ACK response to perform active fingerprinting.

=item B<-input-server>

Starts a SinFP3 server on localhost:32000, so clients speaking the SinFP3 API will be able to access the fingerprinrint engine.

=item B<-mode-null>

Turn off mode plugin.

=item B<-mode-active>

Run using active plugin. This does active OS fingerprinting via SinFP3 engine.

=item B<-mode-passive>

Run using passive plugin. This does passive OS fingerprinting via SinFP3 engine.

=item B<-db-null>

Turn off DB plugin.

=item B<-db-sinfp3>

Use B<Net::SinFP3::DB::SinFP3> database plugin. Default plugin.

=item B<-search-null>

Turn off search plugin.

=item B<-search-active>

Perform a search through a database in active mode. Default plugin.

=item B<-search-passive>

Perform a search through a database in passive mode.

=item B<-log-null>

Turn off log plugin.

=item B<-log-console>

Log messages to the console. Default plugin.

=item B<-output-null>

Turn off output plugin.

=item B<-output-console>

Render output to the console with many details.

=item B<-output-client>

Render output to the connected client using SinFP3 communication protocol.

=item B<-output-simple>

Render output to the console, in a simple way. Default plugin.

=item B<-output-dumper>

Prints a dump to the console.

=item B<-output-osonly>

Only outputs operating system, and not full details of the fingerprint.

=item B<-output-osversionfamily>

Only outputs operating system and its version family, and not full details of the fingerprint.

=item B<-output-pcap>

Saves a trace to a pcap file. You can reply it afterwards using B<Net::SinFP3::Input::Pcap>.

=item B<-output-csv>

Saves fingerprinting results a csv file. You can use L<-csv-file> to choose the output file.

=item B<-output-ubigraph>

Takes a CSV file and display results using Ubigraph. You must use a CSV file as generated by B<Net::SinFP3::Output::CSV>. You can use L<-csv-file> to choose the input file.

=back

=back

=over 4

=item B<Plugin specific options:>

=over 8

=item B<-db-update>

Will update the database for the selected B<Net::SinFP3::DB> plugin.

=item B<-db-file> file

Database file to use. Default is plugin dependant.

=item B<-sniff-promiscuous>

Use promiscuous mode while sniffing. Default to true.

=item B<-pcap-anonymize>

Replaces IP source and destination addresses (and update IP/TCP checksums) to anonymize a pcap output. Default to not.

=item B<-pcap-append>

Append to an already existing pcap file. Default to not.

=item B<-pcap-filter> pcap

Use specified pcap filter. Use it where available.

=item B<-csv-file> file

Use input taken from specified CSV file.

=item B<-pcap-file> file|fileList

Use input taken from specified pcap file or fileList. FileList uses Perl B<glob> function.

=item B<-active-3>

Run all probes in active mode (default).

=item B<-active-2>

Run only probes P1 and P2 in active mode (stealthier).

=item B<-active-1>

Run only probe P2 in active mode (even stealthier).

=item B<-synscan-fingerprint>

Do not perform classic 3 packets fingerprinting, just use the SYN|ACK reply from the SYN request for fingerprinting.

=back

=back

=cut
