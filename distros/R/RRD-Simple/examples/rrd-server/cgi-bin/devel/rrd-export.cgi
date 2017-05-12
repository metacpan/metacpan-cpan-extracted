#!/usr/bin/perl -w
############################################################
#
#   $Id: rrd-browse.cgi 692 2006-06-26 19:11:14Z nicolaw $
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
use constant CACHE   => 1;

############################################################




use 5.8.0;
use warnings;
use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use HTML::Template::Expr;
use File::Basename qw(basename);
use File::Spec::Functions qw(tmpdir catdir catfile);
use vars qw(%LIST_CACHE %GRAPH_CACHE);

use lib (BASEDIR.'/cgi-bin');
use RRDBrowseCommon qw(slurp by_domain alpha_period list_dir graph_def read_graph_data);

# Enable some basic caching
if (CACHE) {
	# Cache calls to list_dir() and graph_def()
	require Memoize;
	Memoize::memoize('list_dir',  LIST_CACHE   => [HASH => \%LIST_CACHE]);
	Memoize::memoize('graph_def', SCALAR_CACHE => [HASH => \%GRAPH_CACHE]);
}


# Grab CGI paramaters
my $cgi = new CGI;
my %q = $cgi->Vars;

# cd to the righr location and define directories
my %dir = map { ( $_ => BASEDIR."/$_" ) } qw(data etc graphs cgi-bin thumbnails);
chdir $dir{'cgi-bin'} || die sprintf("Unable to chdir to '%s': %s", $dir{'cgi-bin'}, $!);

# Create the initial %tmpl data hash
my %tmpl = %ENV;
$tmpl{template} = defined $q{template} && -f $q{template} ? $q{template} : 'export.tmpl';
$tmpl{title}    = ucfirst(basename($tmpl{template},'.tmpl')); $tmpl{title} =~ s/[_\-]/ /g;
$tmpl{self_url} = $cgi->self_url(-absolute => 1, -query_string => 0, -path_info => 0);
$tmpl{rrd_url}  = RRDURL;

# Generate and send an XLS document
if ($q{HOST} && $q{RRD}) {
	my $xls = '';
	eval { $xls = generate_xls(catfile($dir{data},$q{HOST},$q{RRD})); };

	if ($@ || !defined($xls) || !length($xls)) {
		$tmpl{error} = $@;
		$tmpl{template} = 'error.tmpl';

	} else {
		print $cgi->header(
				-type => 'application/vnd.ms-excel',
				-content_disposition => sprintf('attachment; filename=%s', 'filename.xls'),
				-content_length => length($xls),
				-cache_control => 'no-cache',
				-expires => '0',
			);
		print $xls;
		exit;
	}
}

# Go read a bunch of stuff from disk to pump in to %tmpl in a moment
my $gdefs = read_graph_data("$dir{etc}/graph.defs");
my @graphs = list_dir($dir{graphs});
my $tmpl_cache = { hosts => [], };
my $html = { last_update => 0, html => '' };

# Build the data
for my $host (sort by_domain list_dir($dir{data})) {
	next unless -d catfile($dir{data},$host);

	# NEECHI-HACK!
	next if defined($q{HOST}) && $q{HOST} ne $host;
	next if defined($q{LIKE}) && $tmpl{template} =~ /^by_host\.[^\.]+$/i && $host !~ /$q{LIKE}/i;

	(my $node = $host) =~ s/\..*//;
	(my $domain = $host) =~ s/^.*?\.//;
	(my $domain2 = $domain) =~ s/[^a-zA-Z0-9\_]/_/g;
	(my $host2 = $host) =~ s/[^a-zA-Z0-9\_]/_/g;

	my %host = (	node   => $node,
			host   => $host,	host2  => $host2,
			domain => $domain,	domain2 => $domain2,	);

	# Build a hash of potential files that users can slurp() or include
	# in their output template on a per host basis.
	for my $file (grep(/\.(?:te?xt|s?html?|xslt?|xml|css|tmpl)$/i,
			glob("$dir{data}/$host/include*.*"))) {
		(my $base = basename($file)) =~ s/\./_/g;
		$host{$base} = $file;
	}
		
	push @{$tmpl_cache->{hosts}}, \%host;
}

# Merge cache data in
$tmpl{hosts} = $tmpl_cache->{hosts};

# Render the output
if (exists $q{DEBUG} && $q{DEBUG} eq 'insecure') {
	require Data::Dumper;
	$tmpl{DEBUG} = Data::Dumper::Dumper(\%tmpl);
}
my $template = HTML::Template::Expr->new(
		filename            => $tmpl{template},
		associate           => $cgi,
		case_sensitive      => 1,
		loop_context_vars   => 1,
		max_includes        => 5,
		global_vars         => 1,
		die_on_bad_params   => 0,
		functions => {
			slurp => \&slurp,
			like => sub { return defined($_[0]) && defined($_[1]) && $_[0] =~ /$_[1]/i ? 1 : 0; },
			not => sub { !$_[0]; },
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
$html->{last_update} = time;
print $cgi->header(-content => 'text/html'), $html->{html};

exit;

1;


sub generate_xls {
	my $rrdfile = shift;
	return unless defined($rrdfile) && -f $rrdfile;

	require RRDs;
	require RRD::Simple;
	require Spreadsheet::WriteExcel;

	# Create an RRD object
	my $rrd = RRD::Simple->new(file => $rrdfile)
		|| die "Unable to instanciate RRD::Simple object for file '$rrdfile'";
	my @sources = $rrd->sources;
	my $info = $rrd->info;

	# Create a workbook
	open my $fh, '>', \my $xls or die "Failed to open filehandle: $!";
	my $workbook = Spreadsheet::WriteExcel->new($fh);

	my %labels = (
			'300-1'   => 'Daily',
			'300-6'   => 'Weekly',
			'300-24'  => 'Monthly',
			'300-288' => 'Annual',
		);

	# Create the overview worksheet
	my @sheet;
	OVERVIEW: {
		my $sheet = $workbook->add_worksheet('Summary');
		$sheet->set_zoom(80);
		$sheet->freeze_panes(1, 1);
		my ($row, $col) = (0, 0);

		my @fields = sort(keys(%{$info->{rra}->[0]}));
		$sheet->write_row($row, $col, [( '', @fields )] );

		for my $rra (@{$info->{rra}}) { $row++;
			my $label = sprintf('%s %s', 
				(exists $labels{"$info->{step}-$rra->{pdp_per_row}"} ? 
				$labels{"$info->{step}-$rra->{pdp_per_row}"} : rand(999) ),
				ucfirst(lc($rra->{cf})));
			$sheet->write_row($row, $col, [( $label, map { $rra->{$_} } @fields )] );
		}

		push @sheet, $sheet;
	}

	# Create the detail worksheets
	for my $rra (@{$info->{rra}}) {
		my $label = sprintf('%s %s', 
			(exists $labels{"$info->{step}-$rra->{pdp_per_row}"} ? 
			$labels{"$info->{step}-$rra->{pdp_per_row}"} : rand(999) ),
			ucfirst(lc($rra->{cf})));

		my $sheet = $workbook->add_worksheet($label);
		$sheet->set_zoom(80);
		$sheet->freeze_panes(1, 1);
		my ($row, $col) = (0, 0);

		my ($start,$step,$names,$data) = RRDs::fetch($rrdfile, $rra->{cf}, '-s', 60*60*24*365*10);
		$sheet->write_row($row, $col, [( '', @{$names} )] );
		for my $line (@{$data}) { $row++;
			$sheet->write_row($row, $col, [( '', @{$line} )] );
		}

#         my ($start,$step,$names,$data) = RRDs::fetch ...
#         print "Start:       ", scalar localtime($start), " ($start)\n";
#         print "Step size:   $step seconds\n";
#         print "DS names:    ", join (", ", @$names)."\n";
#         print "Data points: ", $#$data + 1, "\n";
#         print "Data:\n";
#         foreach my $line (@$data) {
#           print "  ", scalar localtime($start), " ($start) ";
#           $start += $step;
#           foreach my $val (@$line) {
#             printf "%12.1f ", $val;
#           }
#           print "\n";
#         }

		push @sheet, $sheet;
	}

	$workbook->close;
	return $xls;
}

