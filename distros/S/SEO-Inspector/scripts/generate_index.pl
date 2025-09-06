#!/usr/bin/env perl

use strict;
use warnings;
use autodie qw(:all);

use JSON::MaybeXS;
use File::Glob ':glob';
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
my @html;	# build in array, join later
push @html, <<"HTML";
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
		td.positive { color: green; font-weight: bold; }
		td.negative { color: red; font-weight: bold; }
		td.neutral { color: gray; }
	</style>
</head>
<body>
<div class="badges">
	<a href="https://github.com/nigelhorne/SEO-Inspector">
		<img src="https://img.shields.io/github/stars/nigelhorne/SEO-Inspector?style=social" alt="GitHub stars">
	</a>
	<img src="$coverage_badge_url" alt="Coverage badge">
</div>
<h1>SEO::Inspector</h1><h2>Coverage Report</h2>
<table>
<tr><th>File</th><th>Stmt</th><th>Branch</th><th>Cond</th><th>Sub</th><th>Total</th><th>&Delta;</th></tr>
HTML

# Load previous snapshot for delta comparison
my @history = sort { $a cmp $b } bsd_glob("coverage_history/*.json");
my $prev_data;

if (@history >= 1) {
	my $prev_file = $history[-1];	# Most recent before current
	eval {
		$prev_data = decode_json(read_file($prev_file));
	};
}
my %deltas;
if ($prev_data) {
	for my $file (keys %{$data->{summary}}) {
		next if $file eq 'Total';
		my $curr = $data->{summary}{$file}{total}{percentage} // 0;
		my $prev = $prev_data->{summary}{$file}{total}{percentage} // 0;
		my $delta = sprintf('%.1f', $curr - $prev);
		$deltas{$file} = $delta;
	}
}

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

	my $delta_html = '';
	if (exists $deltas{$file}) {
		my $delta = $deltas{$file};
		my $delta_class = $delta > 0 ? 'positive' : $delta < 0 ? 'negative' : 'neutral';
		my $delta_icon = $delta > 0 ? '&#9650;' : $delta < 0 ? '&#9660;' : '&#9679;';
		my $prev_pct = $prev_data->{summary}{$file}{total}{percentage} // 0;

		$delta_html = sprintf(
			'<td class="%s" title="Previous: %.1f%%">%s %.1f%%</td>',
			$delta_class, $prev_pct, $delta_icon, abs($delta)
		);
	} else {
		$delta_html = '<td class="neutral" title="No previous data">&#9679;</td>';
	}

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

	push @html, sprintf(
		qq{<tr class="%s"><td><a href="%s" title="View coverage line by line">%s</a> %s</td><td>%.1f</td><td>%.1f</td><td>%.1f</td><td>%.1f</td><td>%s</td>%s</tr>\n},
		$row_class, $html_file, $file, $source_link,
		$info->{statement}{percentage} // 0,
		$info->{branch}{percentage} // 0,
		$info->{condition}{percentage} // 0,
		$info->{subroutine}{percentage} // 0,
		$badge_html,
		$delta_html
	);
}

# Summary row
my $avg_coverage = $total_files ? int($total_coverage / $total_files) : 0;

push @html, sprintf(
	qq{<tr class="summary-row"><td colspan="2"><strong>Summary</strong></td><td colspan="2">%d files</td><td colspan="3">Avg: %d%%, Low: %d</td></tr>\n},
	$total_files, $avg_coverage, $low_coverage_count
);

# Add totals row
if (my $total_info = $data->{summary}{Total}) {
	my $total_pct = $total_info->{total}{percentage} // 0;
	my $class = $total_pct > 80 ? 'high' : $total_pct > 50 ? 'med' : 'low';

	push @html, sprintf(
		qq{<tr class="%s"><td><strong>Total</strong></td><td>%.1f</td><td>%.1f</td><td>%.1f</td><td>%.1f</td><td colspan="2"><strong>%.1f</strong></td></tr>\n},
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
	$timestamp = strftime('%Y-%m-%d %H:%M:%S', localtime($stat->mtime));
}

my $commit_url = "https://github.com/nigelhorne/SEO-Inspector/commit/$commit_sha";
my $short_sha = substr($commit_sha, 0, 7);

push @html, '</table>';

# Parse historical snapshots
my @history_files = bsd_glob("coverage_history/*.json");
my @trend_points;

foreach my $file (sort @history_files) {
	my $json = eval { decode_json(read_file($file)) };
	next unless $json && $json->{summary}{Total};

	my $pct = $json->{summary}{Total}{total}{percentage} // 0;
	my ($date) = $file =~ /(\d{4}-\d{2}-\d{2})/;
	push @trend_points, { date => $date, coverage => sprintf('%.1f', $pct) };
}

# Inject chart if we have data
my %commit_times;
open(my $log, '-|', 'git log --all --pretty=format:"%H %h %ci"') or die "Can't run git log: $!";
while (<$log>) {
	chomp;
	my ($full_sha, $short_sha, $datetime) = split ' ', $_, 3;
	$commit_times{$short_sha} = $datetime;
}
close $log;

my %commit_messages;
open($log, '-|', 'git log --pretty=format:"%h %s"') or die "Can't run git log: $!";
while (<$log>) {
	chomp;
	my ($short_sha, $message) = /^(\w+)\s+(.*)$/;
	if($message =~ /^Merge branch /) {
		delete $commit_times{$short_sha};
	} else {
		$commit_messages{$short_sha} = $message;
	}
}
close $log;

# Only display the last 15 commits
my $elements_to_keep = 15;

# Calculate the number of elements to remove from the beginning
my $elements_to_remove = scalar(@history_files) - $elements_to_keep;

# Use splice to remove elements from the beginning of the array
@history_files = sort(@history_files);
splice(@history_files, 0, $elements_to_remove);

my @data_points;
my $prev_pct;

foreach my $file (@history_files) {
	my $json = eval { decode_json(read_file($file)) };
	next unless $json && $json->{summary}{Total};

	my ($sha) = $file =~ /-(\w{7})\.json$/;
	next unless $commit_messages{$sha};

	my $timestamp = $commit_times{$sha} // strftime('%Y-%m-%dT%H:%M:%S', localtime((stat($file))->mtime));
	$timestamp =~ s/ /T/;
	$timestamp =~ s/\s+([+-]\d{2}):?(\d{2})$/$1:$2/;	# Fix space before timezone
	$timestamp =~ s/ //g;	# Remove any remaining spaces

	my $pct = $json->{summary}{Total}{total}{percentage} // 0;
	my $delta = defined $prev_pct ? sprintf('%.1f', $pct - $prev_pct) : 0;
	$prev_pct = $pct;

	my $color = $delta > 0 ? 'green' : $delta < 0 ? 'red' : 'gray';
	my $url = "https://github.com/nigelhorne/SEO-Inspector/commit/$sha";

	my $comment = $commit_messages{$sha};
	push @data_points, qq{{ x: "$timestamp", y: $pct, delta: $delta, url: "$url", label: "$timestamp", pointBackgroundColor: "$color", comment: "$comment" }};
}

@data_points = sort { $a cmp $b } @data_points;

my $js_data = join(",\n", @data_points);

if(scalar(@data_points)) {
	push @html, <<'HTML';
<p>
	<label>
		<input type="checkbox" id="toggleTrend" checked>
		Show regression trend
	</label>
</p>
HTML
}

push @html, <<"HTML";
<canvas id="coverageTrend" width="600" height="300"></canvas>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chartjs-adapter-date-fns"></script>
<script>
function linearRegression(data) {
	const xs = data.map(p => new Date(p.x).getTime());
	const ys = data.map(p => p.y);
	const n = xs.length;

	const sumX = xs.reduce((a, b) => a + b, 0);
	const sumY = ys.reduce((a, b) => a + b, 0);
	const sumXY = xs.reduce((acc, val, i) => acc + val * ys[i], 0);
	const sumX2 = xs.reduce((acc, val) => acc + val * val, 0);

	const slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
	const intercept = (sumY - slope * sumX) / n;

	return xs.map(x => ({
		x: new Date(x).toISOString(),
		y: slope * x + intercept
	}));
}

const dataPoints = [ $js_data ];
HTML

push @html, <<'HTML';
const regressionPoints = linearRegression(dataPoints);
const ctx = document.getElementById('coverageTrend').getContext('2d');
const chart = new Chart(ctx, {
	type: 'line',
	data: {
		datasets: [{
			label: 'Total Coverage (%)',
			data: dataPoints,
			borderColor: 'green',
			backgroundColor: 'rgba(0,128,0,0.1)',
			pointRadius: 5,
			pointHoverRadius: 7,
			pointStyle: 'circle',
			fill: false,
			tension: 0.3,
			pointBackgroundColor: function(context) {
				return context.raw.pointBackgroundColor || 'gray';
			}
		}, {
			label: 'Regression Line',
			data: regressionPoints,
			borderColor: 'blue',
			borderDash: [5, 5],
			pointRadius: 0,
			fill: false,
			tension: 0.0
		}]
	}, options: {
		scales: {
			x: {
				type: 'time',
				time: {
					tooltipFormat: 'MMM d, yyyy HH:mm:ss',
					unit: 'minute'
				},
				title: { display: true, text: 'Timestamp' }
			},
			y: { beginAtZero: true, max: 100, title: { display: true, text: 'Coverage (%)' } }
		}, plugins: {
			legend: {
				display: true,
				position: 'top', // You can also use 'bottom', 'left', or 'right'
				labels: {
					boxWidth: 12,
					padding: 10,
					font: {
						size: 12,
						weight: 'bold'
					}
				}
			}, tooltip: {
				callbacks: {
					label: function(context) {
						const raw = context.raw;
						const coverage = raw.y.toFixed(1);
						const delta = raw.delta?.toFixed(1) ?? '0.0';
						const sign = delta > 0 ? '+' : delta < 0 ? '-' : '±';
						// const baseLine = `${raw.label}: ${coverage}% (${sign}${Math.abs(delta)}%)`;
						const baseLine = `${coverage}% (${sign}${Math.abs(delta)}%)`;
						const commentLine = raw.comment ? raw.comment : null;
						return commentLine ? [baseLine, commentLine] : [baseLine];
					}
				}
			}
		}, onClick: (e) => {
			const points = chart.getElementsAtEventForMode(e, 'nearest', { intersect: true }, true);
			if (points.length) {
				const url = chart.data.datasets[0].data[points[0].index].url;
				window.open(url, '_blank');
			}
		}
	}
});
document.getElementById('toggleTrend').addEventListener('change', function(e) {
	const show = e.target.checked;
	const trendDataset = chart.data.datasets.find(ds => ds.label === 'Regression Line');
	trendDataset.hidden = !show;
	chart.update();
});
</script>
HTML

push @html, <<"HTML";
<footer>
	<p>Project: <a href="https://github.com/nigelhorne/SEO-Inspector">SEO-Inspector</a></p>
	<p><em>Last updated: $timestamp - <a href="$commit_url">commit <code>$short_sha</code></a></em></p>
</footer>
</body>
</html>
HTML

# Write to index.html
write_file($output, join("\n", @html));
