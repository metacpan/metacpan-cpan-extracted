#!/bin/env perl
############################################################
#
#   $Id: rrd-server.pl 1101 2008-01-24 18:07:32Z nicolaw $
#   rrd-server.pl - Data gathering script for RRD::Simple
#
#   Copyright 2006, 2007, 2008 Nicola Worthington
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
############################################################
# vim:ts=4:sw=4:tw=78

BEGIN {
	# User defined constants
	use constant BASEDIR => '/home/nicolaw/webroot/www/rrd.me.uk';
	use constant THEME  => ('BACK#F5F5FF','SHADEA#C8C8FF','SHADEB#9696BE',
				'ARROW#61B51B','GRID#404852','MGRID#67C6DE');
}



BEGIN {
	# Ensure we can find RRDs.so for RRDs.pm
	eval "use RRDs";
	if ($@ && !defined $ENV{LD_LIBRARY_PATH}) {
		$ENV{LD_LIBRARY_PATH} = BASEDIR.'/lib';
		exec($0,@ARGV);
	}
}

use 5.004;
use strict;
use warnings;
use lib qw(../lib);
use RRD::Simple 1.41;
use RRDs;
use Memoize;
use Getopt::Std qw();
use File::Basename qw(basename);
use File::Path qw();
use Config::General qw();
use File::Spec::Functions qw(catfile catdir);
use vars qw($VERSION);

$VERSION = '1.43' || sprintf('%d', q$Revision: 1101 $ =~ /(\d+)/g);

# Get command line options
my %opt = ();
$Getopt::Std::STANDARD_HELP_VERSION = 1;
$Getopt::Std::STANDARD_HELP_VERSION = 1;
Getopt::Std::getopts('u:G:T:gthvVf?', \%opt);

$opt{g} ||= $opt{G};
$opt{t} ||= $opt{T};

# Display help or version
(VERSION_MESSAGE() && exit) if defined $opt{v};
(HELP_MESSAGE() && exit) if defined $opt{h} || defined $opt{'?'} ||
	!(defined $opt{u} || defined $opt{g} || defined $opt{t});

# cd to the righr location and define directories
chdir BASEDIR || die sprintf("Unable to chdir to '%s': %s", BASEDIR, $!);
my %dir = map { ( $_ => BASEDIR."/$_" ) } qw(bin data etc graphs cgi-bin thumbnails);

# Create an RRD::Simple object
my $rrd = RRD::Simple->new(rrdtool => "$dir{bin}/rrdtool");

# Cache results from read_create_data()
memoize('read_create_data');
memoize('read_graph_data');
memoize('basename');
memoize('graph_def');

# Update the RRD if we've been asked to
my $hostname = defined $opt{u} ? update_rrd($rrd,\%dir,$opt{u}) : undef;

# Generate some graphs
my @hosts;
for my $host (($hostname, $opt{G}, $opt{T})) {
	next unless defined $host;
	for (split(/\s*[,:]\s*/,$host)) {
		push(@hosts, $_) if defined($_) && length($_);
	}
}
@hosts = list_dir($dir{data}) unless @hosts;

for my $hostname (@hosts) {
	create_thumbnails($rrd,\%dir,$hostname) if defined $opt{t};
	create_graphs($rrd,\%dir,$hostname) if defined $opt{g};
}

exit;




sub create_graphs {
	my ($rrd,$dir,$hostname,@options) = @_;

	my ($caller) = ((caller(1))[3] || '') =~ /.*::(.+)$/;
	my $thumbnails = defined $caller && $caller eq 'create_thumbnails' ? 1 : 0;
	my $destdir = $thumbnails ? $dir->{thumbnails} : $dir->{graphs};

	my @colour_theme = (color => [ THEME ]);
	my $gdefs = read_graph_data("$dir->{etc}/graph.defs");
	my @hosts = defined $hostname ? ($hostname)
			: grep { -d catdir($dir->{data}, $_) } list_dir("$dir->{data}");

	# For each hostname
	for my $hostname (sort @hosts) {
		# Create the graph directory for this hostname
		my $destination = "$destdir/$hostname";
		File::Path::mkpath($destination) unless -d $destination;

		# For each RRD
		for my $file (grep { $_ =~ /\.rrd$/i && !-d catfile($dir->{data},$hostname,$_) }
				list_dir(catdir($dir->{data},$hostname))
			) {

			# next unless $file =~ /cpu_utilisation/;

			my $rrdfile = catfile($dir->{data},$hostname,$file);
			my $graph = basename($file,'.rrd');
			my $gdef = graph_def($gdefs,$graph);

			# Make sure we parse these raw commands with care
			my @raw_cmd_list = qw(DEF CDEF VDEF TEXTALIGN AREA STACK LINE\d* HRULE\d* VRULE\d* TICK SHIFT GPRINT PRINT COMMENT);
			my $raw_cmd_regex = '('.join('|',@raw_cmd_list).')';
			# my $raw_cmd_regex = qr/^(?:[VC]?DEF|G?PRINT|COMMENT|[HV]RULE\d*|LINE\d*|AREA|TICK|SHIFT|STACK|TEXTALIGN)$/i;
			my @raw_commands;
			my @def_sources;
			my @def_sources_draw;

			# Allow users to put raw commands in the graph.defs file
			for my $raw_cmd (@raw_cmd_list) {
				for my $cmd (grep(/^$raw_cmd$/i, keys %{$gdef})) {
					my $values = $gdef->{$cmd};
					$values = [($values)] unless ref($values);
					for my $v (@{$values}) {
						push @raw_commands, (sprintf('%s:%s', uc($cmd), $v) => '');
						if ($cmd =~ /^[CV]?DEF$/i && $v =~ /^([a-z0-9\_\-]{1,30})=/) {
							push @def_sources, $1;
						} elsif ($cmd =~ /^(?:LINE\d*|AREA|G?PRINT|TICK|STACK)$/i && $v =~ /^([a-z0-9\_\-]{1,30})[#:]/) {
							push @def_sources_draw, $1;
						}
					}
				}
			}

			# Wrap the RRD::Simple calls in an eval() block just in case
			# the explode in a big nasty smelly heap!
			eval {

				# Anything that doesn't start with ^source(?:s|_) should just
				# be pushed on to the RRD::Simple->graph option stack (So this
				# would NOT include the "sources" option).
				my @graph_opts = map { ($_ => $gdef->{$_}) }
						grep(!/^source(s|_)/ && !/^$raw_cmd_regex$/i, keys %{$gdef});

				# Anything that starts with ^source_ should be split up and passed
				# as a hash reference in to the RRD::Simple->graph option stack
				# (This would NOT include the "sources" option).
				push @graph_opts, map {
						# If we see a value from a key/value pair that looks
						# like it might be quoted and comma seperated,
						# "like this", 'then we should','split especially'
						if ($gdef->{$_} =~ /["']\s*,\s*["']/) {
							($_ => [ split(/\s*["']\s*,\s*["']\s*/,$gdef->{$_}) ])

						# Otherwise just split on whitespace like the old
						# version of rrd-server.pl used to do.
						} else {
							($_ => [ split(/\s+/,$gdef->{$_}) ])
						}
					} grep(/^source_/,keys %{$gdef});

				# By default we want to tell RRDtool to be lazy and only generate
				# graphs when it's actually necessary. If we have the -f for force
				# flag then we won't let RRDtool be economical.
				push @graph_opts, ('lazy','') unless exists $opt{f};

				# Only draw the sources we've been told to, and only
				# those that actually exist in the RRD file
				my @rrd_sources = $rrd->sources($rrdfile);
				if (defined $gdef->{sources}) {
					my @sources;
					for my $ds (split(/(?:\s+|\s*,\s*)/,$gdef->{sources})) {
						push @sources, $ds if grep(/^$ds$/,@rrd_sources);
					}
					push @graph_opts, ('sources',\@sources);
				} elsif (!@def_sources && !@def_sources_draw) {
					push @graph_opts, ('sources', [ sort @rrd_sources ]);
				} else {
					push @graph_opts, ('sources', undef);
				}

				printf "Generating %s/%s/%s ...\n",
					$hostname,
					($thumbnails ? 'thumbnails' : 'graphs'),
					$graph if $opt{V};

				# Generate the graph and capture the results to
				# write the text file output in the same directory
				my @stack = ($rrdfile);
				push @stack, @raw_commands if @raw_commands;
				push @stack, ( destination => $destination );
				push @stack, ( timestamp => 'both' );
				push @stack, @colour_theme if @colour_theme;
				push @stack, @options if @options;
				push @stack, @graph_opts if @graph_opts;
				write_txt($rrd->graph(@stack));
				
				my $glob = catfile($destination,"$graph*.png");
				my @images = glob($glob);
				warn "[Warning] $rrdfile: Looks like \$rrd->graph() failed to generate any images in '$glob'\n."
					unless @images;
			};
			warn "[Warning] $rrdfile: => $@" if $@;
		}
	}
}

sub graph_def {
	my ($gdefs,$graph) = @_;

	my $rtn = {};
	for (keys %{$gdefs->{graph}}) {
		my $graph_key = qr(^$_$);
		if (my ($var) = $graph =~ /$graph_key/) {
			$rtn = { %{$gdefs->{graph}->{$_}} };
			unless (defined $var && "$var" ne "1") {
				($var) = $graph =~ /_([^_]+)$/;
			}
			for my $key (keys %{$rtn}) {
				$rtn->{$key} =~ s/\$1/$var/g;
			}
			last;
		}
	}

	return $rtn;
}

sub list_dir {
	my $dir = shift;
	my @items = ();
	opendir(DH,$dir) || die "Unable to open file handle for directory '$dir': $!";
	@items = grep(!/^\./,readdir(DH));
	closedir(DH) || die "Unable to close file handle for directory '$dir': $!";
	return @items;
}

sub create_thumbnails {
	my ($rrd,$dir,$hostname) = @_;
	my @thumbnail_options = (only_graph => '', width => 125, height => 32);
	create_graphs($rrd,$dir,$hostname,@thumbnail_options);
}

sub update_rrd {
	my ($rrd,$dir,$hostname) = @_;
	my $filename = shift @ARGV || undef;

	# Check out the input data
	die "Input data file '$filename' does not exist.\n"
		if defined $filename && !-f $filename;
	die "No data recieved while expecting STDIN data from rrd-client.pl.\n"
		if !$filename && !key_ready();

	# Check the hostname is sane
	die "Hostname '$hostname' contains disallowed characters.\n"
		if $hostname =~ /[^\w\-\.\d]/ || $hostname =~ /^\.|\.$/;

	# Create the data directory for the RRD file if it doesn't exist
	File::Path::mkpath(catdir($dir->{data},$hostname)) unless -d catdir($dir->{data},$hostname);

	# Open the input file if specified
	if (defined $filename) {
		open(FH,'<',$filename) || die "[Error] $rrd: Unable to open file handle for file '$filename': $!";
		select FH;
	};

	# Parse the data
	my %data = ();
	while (local $_ = <>) {
		my ($path,$value) = split(/\s+/,$_);
		my ($time,@path) = split(/\./,$path);
		my $key = pop @path;

		# Check that none of the data is bogus or bollocks
		my $bogus = 0;
		$bogus++ unless $time =~ /^\d+$/;
		$bogus++ unless $value =~ /^[\d\.]+$/;
		for (@path) {
			$bogus++ unless /^[\w\-\_\.\d]+$/;
		}
		next if $bogus;

		my $rrdfile = catfile($dir->{data},$hostname,join('_',@path).'.rrd');
		$data{$rrdfile}->{$time}->{$key} = $value;
	}

	# Process the data
	for my $rrdfile (sort keys %data) {
		for my $time (sort keys %{$data{$rrdfile}}) {
			eval {
				create_rrd($rrd,$dir,$rrdfile,$data{$rrdfile}->{$time})
					unless -f $rrdfile;
				$rrd->update($rrdfile, $time, %{$data{$rrdfile}->{$time}});
			};
			warn "[Warning] $rrdfile: $@" if $@;
		}
	}

	# Close the input file if specified
	if (defined $filename) {
		select STDOUT;
		close(FH) || warn "[Warning] $rrd: Unable to close file handle for file '$filename': $!";
	}

	return $hostname;
}

sub create_rrd {
	my ($rrd,$dir,$rrdfile,$data) = @_;
	my $defs = read_create_data(catfile($dir->{etc},'create.defs'));

	# Figure out what DS types to use
	my %create = map { ($_ => 'GAUGE') } sort keys %{$data};
	while (my ($match,$def) = each %{$defs}) {
		next unless basename($rrdfile,qw(.rrd)) =~ /$match/;
		for my $ds (keys %create) {
			$create{$ds} = $def->{'*'}->{type} if defined $def->{'*'}->{type};
			$create{$ds} = $def->{lc($ds)}->{type} if defined $def->{lc($ds)}->{type};
		}
	}

	# Create the RRD file
	$rrd->create($rrdfile, %create);

	# Tune to use min and max values if specified
	while (my ($match,$def) = each %{$defs}) {
		next unless basename($rrdfile,qw(.rrd)) =~ /$match/;
		for my $ds ($rrd->sources($rrdfile)) {
			my $min = defined $def->{lc($ds)}->{min} ? $def->{lc($ds)}->{min} :
				defined $def->{'*'}->{min} ? $def->{'*'}->{min} : undef;
			RRDs::tune($rrdfile,'-i',"$ds:$min") if defined $min;

			my $max = defined $def->{lc($ds)}->{max} ? $def->{lc($ds)}->{max} :
				defined $def->{'*'}->{max} ? $def->{'*'}->{max} : undef;
			RRDs::tune($rrdfile,'-a',"$ds:$max") if defined $max;
		}
	}
}

sub HELP_MESSAGE {
	print qq{Syntax: rrd-server.pl <-u hostname,-g,-t,-V|-h|-v> [inputfile]
     -u <hostname>   Update RRD data for <hostname>
     -g              Create graphs from RRD data
     -t              Create thumbnails from RRD data
     -V              Display verbose progress information
     -v              Display version information
     -h              Display this help\n};
}

# Display version
sub VERSION { &VERSION_MESSAGE; }
sub VERSION_MESSAGE {
	print "$0 version $VERSION ".'($Id: rrd-server.pl 1101 2008-01-24 18:07:32Z nicolaw $)'."\n";
}

sub key_ready {
	my ($rin, $nfd) = ('','');
	vec($rin, fileno(STDIN), 1) = 1;
	return $nfd = select($rin,undef,undef,3);
}

sub read_graph_data {
	my $filename = shift || undef;

	my %config = ();
	eval {
		my $conf = new Config::General(
			-ConfigFile		=> $filename,
			-LowerCaseNames		=> 1,
			-UseApacheInclude	=> 1,
			-IncludeRelative	=> 1,
			-MergeDuplicateBlocks	=> 1,
			-AllowMultiOptions	=> 1,
			-AutoTrue		=> 1,
		);
		%config = $conf->getall;
	};
	warn "[Warning] $@" if $@;

	return \%config;
}

sub read_create_data {
	my $filename = shift || undef;
	my %defs = ();
	
	# Open the input file if specified
	my @data;
	if (defined $filename && -f $filename) {
		open(FH,'<',$filename) || die "Unable to open file handle for file '$filename': $!";
		@data = <FH>;
		close(FH) || warn "Unable to close file handle for file '$filename': $!";
	} else {
		@data = <DATA>;
	}

	# Parse the file that you've just selected
	for (@data) {
		last if /^__END__\s*$/;
		next if /^\s*$/ || /^\s*#/;

		my %def = ();
		@def{qw(rrdfile ds type min max)} = split(/\s+/,$_);
		next unless defined $def{ds};
		$def{ds} = lc($def{ds});
		$def{rrdfile} = qr($def{rrdfile});
		for (keys %def) {
			if (!defined $def{$_} || $def{$_} eq '-') {	
				delete $def{$_};
			} elsif ($_ =~ /^(min|max)$/ && $def{$_} !~ /^[\d\.]+$/) {
				delete $def{$_};
			} elsif ($_ eq 'type' && $def{$_} !~ /^(GAUGE|COUNTER|DERIVE|ABSOLUTE|COMPUTE)$/i) {
				delete $def{$_};
			}
		}

		$defs{$def{rrdfile}}->{$def{ds}} = {
				map { ($_ => $def{$_}) } grep(!/^(rrdfile|ds)$/,keys %def)
			};
	}

	return \%defs;
}




##
## This processing and robustness of this routine is pretty
## bloody dire and awful. It needs to be rewritten with crap
## input data in mind rather than patching it every time I
## find a new scenario for the data to not be as expected!! ;-)
##

sub write_txt {
	my %rtn = @_;
	while (my ($period,$data) = each %rtn) {
		my $filename = shift @{$data};
		last if $filename =~ m,/thumbnails/,;

		my %values = ();
		my $max_len = 0;
		for (@{$data->[0]}) {
			my ($ds,$k,$v) = split(/\s+/,$_);
			next unless defined($ds) && length($ds) && defined($k);
			$values{$ds}->{$k} = $v;
			$max_len = length($ds) if length($ds) > $max_len;
		}

		if (open(FH,'>',"$filename.txt")) {
			printf FH "%s (%dx%d) %dK\n\n",
				basename($filename),
				(defined($data->[1]) ? $data->[1] : -1),
				(defined($data->[2]) ? $data->[2] : -1),
				(-e $filename ? (stat($filename))[7]/1024 : 0);

			for my $ds (sort keys %values) {
				for (qw(min max last)) {
					$values{$ds}->{$_} = ''
						unless defined $values{$ds}->{$_};
				}
				printf FH "%-${max_len}s     min: %s, max: %s, last: %s\n", $ds,
				$values{$ds}->{min}, $values{$ds}->{max}, $values{$ds}->{last};
			}
			close(FH);
		}
	}
}




1;


__DATA__

#	* means all
#	- means undef/na

# rrdfile	ds	type	min	max

^net_traffic_.+	Transmit	DERIVE	0	-
^net_traffic_.+	Receive	DERIVE	0	-

^hdd_io_.+	*	DERIVE	0	-

^hw_irq_interrupts_cpu\d+$	*	DERIVE	0	-

^apache_status$	ReqPerSec	DERIVE	0	-
^apache_status$	BytesPerSec	DERIVE	0	-
^apache_logs$	*	DERIVE	0	-

^db_mysql_activity$	*	DERIVE	0	-
^db_mysql_activity_com$	*	DERIVE	0	-

__END__

