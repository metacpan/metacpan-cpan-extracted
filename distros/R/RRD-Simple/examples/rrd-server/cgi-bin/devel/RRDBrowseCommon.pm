############################################################
#
#   $Id: rrd-common.pm 692 2006-06-26 19:11:14Z nicolaw $
#   rrd-common.pm - Common shared module
#
#   Copyright 2007 Nicola Worthington
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

package RRDBrowseCommon;

use 5.6.1;
use warnings;
use strict;
use Config::General qw();
use vars qw(@ISA @EXPORT @EXPORT_OK);

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(slurp by_domain alpha_period list_dir graph_def read_graph_data); 
@EXPORT = @EXPORT_OK;

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


