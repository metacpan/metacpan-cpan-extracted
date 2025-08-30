#!/usr/bin/env perl

use strict;
use warnings;
use JSON::MaybeXS;
use File::Slurp;
use POSIX qw(strftime);
use File::stat;

my $cover_db = 'cover_db/cover.json';
my $output = 'cover_html/index.html';

# Read and decode coverage data
my $json_text = read_file($cover_db);
my $data = decode_json($json_text);

my $coverage_pct = 0;
my $badge_color = 'red';

if(my $total_info = $data->{summary}{Total}) {
	$coverage_pct = int($total_info->{total}{percentage} // 0);
	$badge_color = $coverage_pct > 80 ? 'brightgreen' : $coverage_pct > 50 ? 'yellow' : 'red';
}

my $coverage_badge_url = "https://img.shields.io/badge/coverage-${coverage_pct}%25-${badge_color}";

# Start HTML
my $html = <<"HTML";
<!DOCTYPE html>
<html>
	<head>
	<title>SEO::Inspector Coverage Report</title>
	<style>
		body { font-family: sans-serif; }
		table { border-collapse: collapse; width: 100%; }
		th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
		th { background-color: #f2f2f2; }
		.low { background-color: #fdd; }
		.med { background-color: #ffd; }
		.high { background-color: #dfd; }
		.badges img { margin-right: 10px; }
		.disabled-icon {
			opacity: 0.4;
			cursor: default;
		}
		.icon-link {
			text-decoration: none;
		}
		.icon-link:hover {
			opacity: 0.7;
			cursor: pointer;
		}
		.coverage-badge {
			padding: 2px 6px;
			border-radius: 4px;
			font-weight: bold;
			color: white;
			font-size: 0.9em;
		}
		.badge-good { background-color: #4CAF50; }
		.badge-warn { background-color: #FFC107; }
		.badge-bad { background-color: #F44336; }
		.summary-row {
			font-weight: bold;
			background-color: #f0f0f0;
		}
	</style>
</head>
<body>
<div class="badges">
	<a href="https://github.com/nigelhorne/SEO-Inspector">
		<img src="https://img.shields.io/github/stars/nigelhorne/SEO-Inspector?style=social" alt="GitHub stars">
	</a>
	<img src="$coverage_badge_url" alt="Coverage badge">
</div>
<h1>SEO::Inspector Coverage Report</h1>
<table>
<tr><th>File</th><th>Stmt</th><th>Branch</th><th>Cond</th><th>Sub</th><th>Total</th></tr>
HTML

my $commit_sha = `git rev-parse HEAD`;
chomp $commit_sha;
my $github_base = "https://github.com/nigelhorne/SEO-Inspector/blob/$commit_sha/";

# Add rows
my ($total_files, $total_coverage, $low_coverage_count) = (0, 0, 0);

for my $file (sort keys %{$data->{summary}}) {
	next if $file eq 'Total';

	my $info = $data->{summary}{$file};
	my $html_file = $file;
	$html_file =~ s|/|-|g;
	$html_file =~ s|\.pm$|-pm|;
	$html_file =~ s|\.pl$|-pl|;
	$html_file .= '.html';

	my $total = $info->{total}{percentage} // 0;
	$total_files++;
	$total_coverage += $total;
	$low_coverage_count++ if $total < 70;

	my $badge_class = $total >= 90 ? 'badge-good'
					: $total >= 70 ? 'badge-warn'
					: 'badge-bad';

	my $tooltip = $total >= 90 ? 'Excellent coverage'
				 : $total >= 70 ? 'Moderate coverage'
				 : 'Needs improvement';

	my $row_class = $total >= 90 ? 'high'
			: $total >= 70 ? 'med'
			: 'low';

	my $badge_html = sprintf(
		'<span class="coverage-badge %s" title="%s">%.1f%%</span>',
		$badge_class, $tooltip, $total
	);

	my $source_url = $github_base . $file;
	my $has_coverage = (
		defined $info->{statement}{percentage} ||
		defined $info->{branch}{percentage} ||
		defined $info->{condition}{percentage} ||
		defined $info->{subroutine}{percentage}
	);

	my $source_link = $has_coverage
		? sprintf('<a href="%s" class="icon-link" title="View source on GitHub">&#128269;</a>', $source_url)
		: '<span class="disabled-icon" title="No coverage data">&#128269;</span>';

	$html .= sprintf(
		qq{<tr class="%s"><td><a href="%s" title="View coverage line by line">%s</a> %s</td><td>%.1f</td><td>%.1f</td><td>%.1f</td><td>%.1f</td><td>%s</td></tr>\n},
		$row_class, $html_file, $file, $source_link,
		$info->{statement}{percentage} // 0,
		$info->{branch}{percentage} // 0,
		$info->{condition}{percentage} // 0,
		$info->{subroutine}{percentage} // 0,
		$badge_html
	);
}

# Summary row
my $avg_coverage = $total_files ? int($total_coverage / $total_files) : 0;

$html .= sprintf(
	qq{<tr class="summary-row"><td colspan="2"><strong>Summary</strong></td><td colspan="2">%d files</td><td colspan="2">Avg: %d%%, Low: %d</td></tr>\n},
	$total_files, $avg_coverage, $low_coverage_count
);

# Add totals row
if (my $total_info = $data->{summary}{Total}) {
	my $total_pct = $total_info->{total}{percentage} // 0;
	my $class = $total_pct > 80 ? 'high' : $total_pct > 50 ? 'med' : 'low';

	$html .= sprintf(
		qq{<tr class="%s"><td><strong>Total</strong></td><td>%.1f</td><td>%.1f</td><td>%.1f</td><td>%.1f</td><td><strong>%.1f</strong></td></tr>\n},
		$class,
		$total_info->{statement}{percentage} // 0,
		$total_info->{branch}{percentage} // 0,
		$total_info->{condition}{percentage} // 0,
		$total_info->{subroutine}{percentage} // 0,
		$total_pct
	);
}

my $timestamp = 'Unknown';
if (my $stat = stat($cover_db)) {
	$timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime($stat->mtime));
}

my $commit_url = "https://github.com/nigelhorne/SEO-Inspector/commit/$commit_sha";
my $short_sha = substr($commit_sha, 0, 7);

$html .= <<"HTML";
</table>
<footer>
	<p>Project: <a href="https://github.com/nigelhorne/SEO-Inspector">SEO-Inspector</a></p>
	<p><em>Last updated: $timestamp - <a href="$commit_url">commit <code>$short_sha</code></a></em></p>
</footer>
</body>
</html>
HTML

# Write to index.html
write_file($output, $html);
