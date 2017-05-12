#!/usr/bin/perl
############################################################
#
#   $Id: rrd-browse.cgi 1096 2008-01-23 19:14:46Z nicolaw $
#   rrd-browse.cgi - Graph browser CGI script for RRD::Simple
#
#   Copyright 2006,2007 Nicola Worthington
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

# User defined constants
use constant BASEDIR => '/home/nicolaw/webroot/www/rrd.me.uk';
use constant RRDURL  => '';

# Caching
use constant CACHE   => 1;
use constant DEFAULT_EXPIRES => '60 minutes';

# When is an RRD file regarded as stale?
use constant STALE_THRESHOLD => 60*60; # 60 minutes

############################################################




use 5.6.1;
use warnings;
use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use HTML::Template::Expr;
use File::Basename qw(basename);
use Config::General qw();
use File::Spec::Functions qw(tmpdir catdir catfile);
use vars qw(%LIST_CACHE %GRAPH_CACHE %SLURP_CACHE
	$CACHE_ROOT $CACHE $FRESHEN_CACHE %STALERRD_CACHE);

# Enable some basic caching.
# See notes about $tmpl_cache a little further
# down in this code.
if (CACHE) {
	# Cache calls to list_dir() and graph_def()
	require Memoize;
	Memoize::memoize('list_dir',  LIST_CACHE   => [HASH => \%LIST_CACHE]);
	Memoize::memoize('graph_def', SCALAR_CACHE => [HASH => \%GRAPH_CACHE]);
	Memoize::memoize('stale_rrd', SCALAR_CACHE => [HASH => \%STALERRD_CACHE]);
	
	# This isn't really necessary unless you're viewing the same page many
	# times over in defail view - i don't think that the extra memory utilisation
	# is worth the small improvement in rendering time.
	#Memoize::memoize('slurp',     SCALAR_CACHE => [HASH => \%SLURP_CACHE]);

	# Try some caching on disk
	unless (defined($CACHE) && ref($CACHE)) {
		$CACHE_ROOT = catdir(tmpdir(), 'rrd-browse.cgi');
		mkdir($CACHE_ROOT,0700) unless -d $CACHE_ROOT;
		eval {
			require Cache::File;
			$CACHE = Cache::File->new(
					cache_root => $CACHE_ROOT,
					default_expires => DEFAULT_EXPIRES
				);
		};
		warn $@ if $@;
	};
}


# Grab CGI paramaters
my $cgi = new CGI;
my %q = $cgi->Vars;
my $cache_key = $cgi->self_url(-absolute => 1, -query_string => 1, -path_info => 1);

# cd to the righr location and define directories
my %dir = map { ( $_ => BASEDIR."/$_" ) } qw(data etc graphs cgi-bin thumbnails);
chdir $dir{'cgi-bin'} || die sprintf("Unable to chdir to '%s': %s", $dir{'cgi-bin'}, $!);

# Create the initial %tmpl data hash
my %tmpl = %ENV;
$tmpl{template} = defined $q{template} && -f $q{template} ? $q{template} : 'index.tmpl';
$tmpl{PERIOD}   = defined $q{PERIOD} && $q{PERIOD} =~ /^(daily|weekly|monthly|annual)$/i ? lc($q{PERIOD}) : 'daily';
$tmpl{title}    = ucfirst(basename($tmpl{template},'.tmpl')); $tmpl{title} =~ s/[_\-]/ /g;
$tmpl{self_url} = $cgi->self_url(-absolute => 1, -query_string => 0, -path_info => 0);
$tmpl{rrd_url}  = RRDURL;

# Go read a bunch of stuff from disk to pump in to %tmpl in a moment
my $gdefs = read_graph_data("$dir{etc}/graph.defs");
my @graphs = list_dir($dir{graphs});
# my @thumbnails = list_dir($dir{thumbnails}); # Not used anywhere


# Build up the data in %tmpl by host
# The $tmpl_cache structure could be cached in theory, but
# the process of thawing actually uses LOTS of memory if
# the source structure was quite sizable to start with. For
# this reason, I'm *NOT* actually caching this structure
# anymore, and am opting to cache the HTML output on a per
# URL basis. This means there's less chance of a cache hit,
# but it means you don't use 715MB of memory if you have
# 100 or so servers with an average of 25 graphs per host.
my $tmpl_cache = {
		graph_tmpl  => {},
		hosts       => [],
		graphs      => [],
	};


# Pull in the HTML cache (mentioned above)
my $html = { last_update => 0, html => '' };

# Check if we should force an update on the cache
if ($q{FRESHEN_CACHE}) {
	$FRESHEN_CACHE  = 1 ;
}

# Check the mtimes of each directory for any modifications
# and thereby a requirement to freshen our caches
if (!defined($FRESHEN_CACHE) && !$FRESHEN_CACHE) {
	while (my ($k,$dir) = each %dir) {
		if (!defined $html->{last_update} || (stat($dir))[9] > $html->{last_update}) {
			$FRESHEN_CACHE = 1;
			warn "$k($dir) has been modified since the cache was last updated; forcing an update now\n";
		}
	}
}

# Output from the cache if possible
if (!$FRESHEN_CACHE) {
	eval { $html = $CACHE->thaw($cache_key); };
	warn $@ if $@;
	if ($html->{html}) {
		#warn "Using cached version '$cache_key'\n";
		$html->{html} =~ s/[ \t][ \t]+/ /g unless $q{DEBUG};
		print $cgi->header(-content => 'text/html'), $html->{html};
		exit;
	}
} else {
	%LIST_CACHE     = ();
	%GRAPH_CACHE    = ();
	%STALERRD_CACHE = ();
	%SLURP_CACHE    = ();
}


#######################################
#
#  This section of code is REALLY slow and
#  ineffecient. A basic work around of caching
#  pages based on the URL has been implemented
#  to try and avoid having to execute this code
#  at all. This is a poor work around. I need
#  to optimise this code. If you have any
#  patches to help, please send them to
#  nicolaw@cpan.org.
#
#######################################
for my $host (sort by_domain list_dir($dir{data})) {
	my $path = catfile($dir{data},$host);
	next unless -d $path || (-l $path && -d readlink($path));

	# NEECHI-HACK!
	# This is removing some templating logic from the HTML::Template .tmpl file
	# themsevles and bringing it in to this loop in order to save a number of
	# loop cycles and speed up the pre-processing before we render the HTML.
	next if defined($q{HOST}) && $q{HOST} ne $host;
	next if defined($q{LIKE}) && $tmpl{template} =~ /^by_host\.[^\.]+$/i && $host !~ /$q{LIKE}/i;

	(my $node = $host) =~ s/\..*//;
	(my $domain = $host) =~ s/^.*?\.//;
	(my $domain2 = $domain) =~ s/[^a-zA-Z0-9\_]/_/g;
	(my $host2 = $host) =~ s/[^a-zA-Z0-9\_]/_/g;

	my %host = (
			host   => $host,
			host2  => $host2,
			node   => $node,
			domain => $domain,
			domain2 => $domain2,
		);

	# Build a hash of potential files that users can slurp() or include
	# in their output template on a per host basis.
	for my $file (grep(/\.(?:te?xt|s?html?|xslt?|xml|css|tmpl)$/i,
			glob("$dir{data}/$host/include*.*"))) {
		(my $base = basename($file)) =~ s/\./_/g;
		$host{$base} = $file;
	}
		
	if (!grep(/^$host$/,@graphs)) {
		$host{no_graphs} = 1;
		push @{$tmpl_cache->{hosts}}, \%host;

	} else {
		my $all_host_rrds_stale = 1;

		for (qw(thumbnails graphs)) {
			eval {
				my @ary = ();
				for my $img (sort alpha_period 
						grep(/\.(png|jpe?g|gif)$/i,list_dir("$dir{$_}/$host"))) {
					my ($graph) = ($img =~ /^(.+)\-\w+\.\w+$/);

					# NEECHI-HACK!
					# This is another nasty hack that removed some of the logic from the
					# HTML::Template code by pre-excluding specific data from the template
					# data and thereby speeding up the rendering of the HTML.	
					next if defined($q{GRAPH}) && $q{GRAPH} ne $graph;
					next if defined($q{LIKE})
						&& $tmpl{template} =~ /^by_graph\.[^\.]+$/i
						&& $graph !~ /$q{LIKE}/i;

					my %hash = (
							src => "$tmpl{rrd_url}/$_/$host/$img",
							period => ($img =~ /.*-(\w+)\.\w+$/),
							graph => $graph,
						);

					my $gdef = graph_def($gdefs,$hash{graph});
					$hash{title} = defined $gdef->{title} ? $gdef->{title} : $hash{graph};

					# Is the RRD file that generated this image considered stale?
					my ($stale, $last_modified) = stale_rrd(catfile($dir{data},$host,"$graph.rrd"));
					if (defined($stale) && $stale) {
						$hash{stale} = $last_modified;
					} else {
						$all_host_rrds_stale = 0;
					}

					# Include the path on disk to the .txt file that is generated by the
					# output of the RRD::Simple->graph() method while generating the graphs
					$hash{txt} = catfile($dir{graphs},$host,"$img.txt")
						if $_ eq 'graphs' 
							&& -e catfile($dir{graphs},$host,"$img.txt")
							&& (stat(_))[7] > 5;

					push @ary, \%hash;

					# By graph later
					if ($_ eq 'thumbnails' && defined $hash{graph}) {
							# && defined $hash{period} && $hash{period} eq 'daily') {
						my %hash2 = %hash;
						delete $hash2{title};
						$hash2{host} = $host;
						if (defined $hash{period} && $hash{period} eq 'daily') {	
							$tmpl_cache->{hosts_per_graph}->{$hash{graph}} = 0
								unless defined $tmpl_cache->{hosts_per_graph}->{$hash{graph}};
							$tmpl_cache->{hosts_per_graph}->{$hash{graph}}++;
						}
						push @{$tmpl_cache->{graph_tmpl}->{"$hash{graph}\t$hash{title}"}}, \%hash2;
					}
				}
				$host{$_} = \@ary;
			};
			warn $@ if $@;
		}

		if ($all_host_rrds_stale) {
			$host{stale} = 1;
		}
		$host{total_graphs} = grep(/^daily$/, map { $_->{period} } @{$host{graphs}});
		push @{$tmpl_cache->{hosts}}, \%host;
	}
}

# Merge cache data in
$tmpl{hosts} = $tmpl_cache->{hosts};

# Merge by-graph cache data in
for (sort keys %{$tmpl_cache->{graph_tmpl}}) {
	my ($graph,$title) = split(/\t/,$_);
	push @{$tmpl{graphs}}, {
			graph       => $graph,
			graph_title => $title,
			total_hosts => $tmpl_cache->{hosts_per_graph}->{$graph},
			thumbnails  => $tmpl_cache->{graph_tmpl}->{$_},
		};
}

# Render the output
if (exists $q{DEBUG} && $q{DEBUG} eq 'insecure') {
	require Data::Dumper;
	$tmpl{DEBUG} = Data::Dumper::Dumper(\%tmpl);
}
my $template = HTML::Template::Expr->new(
		filename            => $tmpl{template},

		# This caching doesn't work properly with
		# HTML::Template::Expr
		#cache               => 1,
		#shared_cache        => 1,
		#file_cache          => 1,
		#file_cache_dir      => $CACHE_ROOT,
		#file_cache_dir_mode => 0700,

		associate           => $cgi,
		case_sensitive      => 1,
		loop_context_vars   => 1,
		max_includes        => 5,
		global_vars         => 1,
		die_on_bad_params   => 0,
		functions => {
			slurp => \&slurp,
			like => sub { return defined($_[0]) && defined($_[1]) && $_[0] =~ /$_[1]/i ? 1 : 0; },
			not => sub { return !$_[0]; },
			equal_or_like => sub {
				return 1 if (!defined($_[1]) || !length($_[1])) && (!defined($_[2]) || !length($_[2]));
				#(warn "$_[0] eq $_[1]\n" && return 1) if defined $_[1] && "$_[0]" eq "$_[1]";
				(return 1) if defined $_[1] && "$_[0]" eq "$_[1]";
				return 1 if defined $_[2] && "$_[0]" =~ /$_[2]/;
				return 0;
			},
		},
	);
$template->param(\%tmpl);

$html->{html} = $template->output();
$html->{html} =~ s/[ \t][ \t]+/ /g unless $q{DEBUG};
$html->{last_update} = time;
eval { $CACHE->freeze($cache_key, $html); };
warn $@ if $@;
print $cgi->header(-content => 'text/html'), $html->{html};

exit;


# Is the RRD file that generated this image considered stale?
sub stale_rrd {
	my $rrd_file = shift;
	return unless defined $rrd_file && $rrd_file;
	my $rrd_mtime = (stat($rrd_file))[9];

	if (defined(wantarray)) {
		my $modified = scalar(localtime($rrd_mtime));
		if (wantarray) {
			return (1, $modified) if time - $rrd_mtime >= STALE_THRESHOLD;
			return (0, $modified);
		} else {
			return 1 if time - $rrd_mtime >= STALE_THRESHOLD;
			return 0;
		}
	}

	return;
}

# Slurp in a file from disk, yum yum
sub slurp {
	my $rtn = $_[0];
	if (open(FH,'<',$_[0])) {
		local $/ = undef;
		$rtn = <FH>;
		close(FH);
	}
	return $rtn;
}

# Sort by domain
sub by_domain {
	sub split_domain {
		local $_ = shift || '';
		if (/(.*)\.(\w\w\w+)$/) {
			return ($2,$1);
		} elsif (/(.*)\.(\w+\.\w\w)$/) {
			return ($2,$1);
		}
		return ($_,'');
	}
	my @A = split_domain($a);
	my @B = split_domain($b);

	($A[0] cmp $B[0])
		||
	($A[1] cmp $B[1])
}

# Sort by time period
sub alpha_period {
	my %order = qw(daily 0 weekly 1 monthly 2 annual 3 3year 4);
	($a =~ /^(.+)\-/)[0] cmp ($b =~ /^(.+)\-/)[0]
		||
	$order{($a =~ /^.+\-(\w+)\./)[0]} <=> $order{($b =~ /^.+\-(\w+)\./)[0]}
}

# Return a list of items in a directory
sub list_dir {
	my $dir = shift;
	opendir(DH,$dir) || die "Unable to open file handle for directory '$dir': $!";
	my @items = grep(!/^\./,readdir(DH));
	closedir(DH) || die "Unable to close file handle for directory '$dir': $!";
	return @items;
}

# Pull out the most relevent graph definition
sub graph_def {
	my ($gdefs,$graph) = @_;
	return {} unless defined $graph;

	my $rtn = {};
	for (keys %{$gdefs->{graph}}) {
		my $graph_key = qr(^$_$);
		if ($graph =~ /$graph_key/) {
			$rtn = { %{$gdefs->{graph}->{$_}} };
			my ($var) = $graph =~ /_([^_]+)$/;
			for my $key (keys %{$rtn}) {
				$rtn->{$key} =~ s/\$1/$var/g;
			}
			last;
		}
	}

	return $rtn;
}

# Read in the graph definition config file
sub read_graph_data {
	my $filename = shift || undef;

	my %config = ();
	eval {
		my $conf = new Config::General(
			-ConfigFile		=> $filename,
			-LowerCaseNames		=> 1,
			-UseApacheInclude	=> 1,
			-IncludeRelative	=> 1,
#			-DefaultConfig		=> \%default,
			-MergeDuplicateBlocks	=> 1,
			-AllowMultiOptions	=> 1,
			-MergeDuplicateOptions	=> 1,
			-AutoTrue		=> 1,
		);
		%config = $conf->getall;
	};
	warn $@ if $@;

	return \%config;
}

1;


