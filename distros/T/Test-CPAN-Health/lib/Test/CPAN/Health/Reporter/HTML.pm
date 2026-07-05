package Test::CPAN::Health::Reporter::HTML;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak);
use Readonly;
use Params::Validate::Strict qw(validate_strict);
use Scalar::Util qw(blessed);

our $VERSION = '0.1.0';

# Status badge colours: background and foreground.
Readonly::Hash my %STATUS_BG => (
	pass  => '#d1fae5',
	warn  => '#fef3c7',
	fail  => '#fee2e2',
	skip  => '#f3f4f6',
	error => '#f3e8ff',
);

Readonly::Hash my %STATUS_FG => (
	pass  => '#065f46',
	warn  => '#92400e',
	fail  => '#991b1b',
	skip  => '#374151',
	error => '#5b21b6',
);

# Unicode glyphs expressed as HTML entities (source stays ASCII).
Readonly::Hash my %STATUS_GLYPH => (
	pass  => '&#x2713;',   # CHECK MARK
	warn  => '&#x26A0;',   # WARNING SIGN
	fail  => '&#x2717;',   # BALLOT X
	skip  => '&#x2014;',   # EM DASH
	error => '&#x2049;',   # EXCLAMATION QUESTION MARK
);

=head1 NAME

Test::CPAN::Health::Reporter::HTML - Render a health report as an HTML document

=head1 SYNOPSIS

    use Test::CPAN::Health::Reporter::HTML;

    my $reporter = Test::CPAN::Health::Reporter::HTML->new;
    my $html = $reporter->render($report);
    open my $fh, '>', 'report.html';
    print {$fh} $html;

=head1 DESCRIPTION

Produces a self-contained HTML5 document from a
L<Test::CPAN::Health::Report>.  The document includes all CSS inline and
has no external dependencies; it may be opened directly in a browser or
saved to disk.

Each check result is a colour-coded table row.  Detail strings appear
below the summary within the same row.  The overall score and status
summary are shown prominently at the top of the page.

=head1 LIMITATIONS

=over 4

=item * No JavaScript is used; the output is not interactive.

=item * Long detail strings are not wrapped.

=back

=cut

sub new {
	my ($class, %args) = @_;

	%args = %{ validate_strict(
		schema => {
			title => { type => 'string', optional => 1, default => 'CPAN Health Report' },
		},
		input => \%args,
	) };

	return bless { _title => $args{title} }, $class;
}

=head2 render

=head3 PURPOSE

Render a Report to a self-contained HTML5 string.

=head3 API SPECIFICATION

=head4 INPUT

  report  Test::CPAN::Health::Report  required

=head4 OUTPUT

Scalar string: valid HTML5 document (UTF-8).

=head3 MESSAGES

  Code  | Severity | Message                            | Resolution
  ------+----------+------------------------------------+---------------------
  HTM01 | FATAL    | report must be a Report object     | Pass a Report instance

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  RenderOp
  report : Report
  html!  : String
  -------------------------------------------------------
  html! contains report.overall_score
  valid_html5(html!)

=head3 SIDE EFFECTS

None.

=head3 USAGE EXAMPLE

    my $html = $reporter->render($report);
    open my $fh, '>', 'report.html' or die $!;
    print {$fh} $html;

=cut

sub render {
	my ($self, $report) = @_;

	croak 'report must be a Test::CPAN::Health::Report'
		unless blessed($report) && $report->isa('Test::CPAN::Health::Report');

	my $score = $report->overall_score;
	my $score_colour = $score >= 90 ? '#065f46'
		             : $score >= 70 ? '#92400e'
		             :                '#991b1b';
	my $score_bg = $score >= 90 ? '#d1fae5'
		         : $score >= 70 ? '#fef3c7'
		         :                '#fee2e2';

	my $title     = _esc($self->{_title});
	my $score_str = _esc(sprintf('%d/100', $score));
	my $summary   = _esc(sprintf(
		'Passed: %d  Warned: %d  Failed: %d  Skipped: %d',
		$report->pass_count,
		$report->warn_count,
		$report->fail_count,
		$report->skip_count,
	));

	my $rows = '';
	for my $result (sort { $a->check_id cmp $b->check_id } @{$report->results}) {
		$rows .= $self->_render_row($result);
	}

	return <<"END_HTML";
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>$title</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:system-ui,sans-serif;background:#f9fafb;color:#111827;padding:2rem}
h1{font-size:1.5rem;margin-bottom:1.5rem}
.score-box{display:inline-block;padding:.75rem 1.5rem;border-radius:.5rem;font-size:2rem;font-weight:700;background:$score_bg;color:$score_colour;margin-bottom:1rem}
.summary{color:#6b7280;margin-bottom:1.5rem;font-size:.9rem}
table{width:100%;border-collapse:collapse;background:#fff;border-radius:.5rem;overflow:hidden;box-shadow:0 1px 3px rgba(0,0,0,.1)}
thead th{background:#374151;color:#fff;padding:.75rem 1rem;text-align:left;font-size:.85rem;font-weight:600}
tbody tr{border-bottom:1px solid #e5e7eb}
tbody tr:last-child{border-bottom:none}
td{padding:.75rem 1rem;vertical-align:top;font-size:.9rem}
.badge{display:inline-block;padding:.2rem .6rem;border-radius:.25rem;font-size:.8rem;font-weight:600}
.detail{font-size:.8rem;color:#6b7280;margin-top:.25rem}
</style>
</head>
<body>
<h1>$title</h1>
<div class="score-box">$score_str</div>
<div class="summary">$summary</div>
<table>
<thead><tr><th>Check</th><th>Status</th><th>Score</th><th>Summary</th></tr></thead>
<tbody>
$rows</tbody>
</table>
</body>
</html>
END_HTML
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

sub _render_row {
	my ($self, $result) = @_;

	my $status = $result->status;
	my $bg     = $STATUS_BG{$status} // '#f9fafb';
	my $fg     = $STATUS_FG{$status} // '#111827';
	my $glyph  = $STATUS_GLYPH{$status} // '?';

	my $name    = _esc($result->data->{name} // $result->check_id);
	my $summary = _esc($result->summary);
	my $score   = defined $result->score ? _esc($result->score . '/100') : '';

	my $details_html = '';
	for my $d (@{$result->details}) {
		$details_html .= '<div class="detail">' . _esc($d) . '</div>';
	}

	return <<"END_ROW";
<tr style="background:$bg">
<td>$name</td>
<td><span class="badge" style="background:$bg;color:$fg">$glyph $status</span></td>
<td>$score</td>
<td>$summary$details_html</td>
</tr>
END_ROW
}

# Escape the five HTML-special characters to prevent XSS.
sub _esc {
	my ($str) = @_;
	return '' unless defined $str;
	$str =~ s/ & /&amp;/gx;
	$str =~ s/ < /&lt;/gx;
	$str =~ s/ > /&gt;/gx;
	$str =~ s/ " /&quot;/gx;
	$str =~ s/ ' /&#39;/gx;
	return $str;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2025-2026 Nigel Horne.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

=cut

1;
