package Test::CPAN::Health::Check::DuplicateCode;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak carp);
use File::Spec;
use Readonly;
use Params::Validate::Strict qw(validate_strict);

use parent 'Test::CPAN::Health::Check';

our $VERSION = '0.1.0';

# Minimum consecutive code lines that form a "chunk" worth tracking.
# Smaller values produce many false positives (e.g. matching "use strict").
Readonly::Scalar my $CHUNK_SIZE => 6;

# Score thresholds.
Readonly::Scalar my $SCORE_PASS  => 90;
Readonly::Scalar my $SCORE_WARN  => 50;

=head1 NAME

Test::CPAN::Health::Check::DuplicateCode - Detect copy-paste code blocks across source files

=head1 SYNOPSIS

    use Test::CPAN::Health::Check::DuplicateCode;

    my $check  = Test::CPAN::Health::Check::DuplicateCode->new;
    my $result = $check->run($dist);

    printf "%s: %s\n", $result->status, $result->summary;

=head1 DESCRIPTION

Implements a lightweight, dependency-free clone detector using a sliding-window
hash approach:

=over 4

=item 1.

Each source file is reduced to a sequence of I<code lines>: lines that are
not blank, not pure comments, and not POD.  Each line is whitespace-normalised
(leading/trailing whitespace stripped; runs of whitespace collapsed to a single
space).

=item 2.

A sliding window of C<6> consecutive normalised lines forms a "chunk".  The
hash (MD5-free: joined as a string) of each chunk is recorded along with the
originating file.

=item 3.

Chunks whose hash appears in more than one distinct file are cross-file
duplicates.

=back

Score = round((1 - dup_chunks / total_chunks) * 100) when total_chunks > 0,
else 100.  Status: pass E<ge> 90, warn E<ge> 50, fail below 50.

=head1 LIMITATIONS

=over 4

=item * Whitespace normalisation is basic: it does not account for string
literals or heredocs that span multiple lines.

=item * The detector only finds B<cross-file> duplicates; intra-file
repetition is not flagged.

=item * Short common boilerplate (e.g. C<use strict; use warnings; 1;>) is
naturally filtered out because consecutive boilerplate lines rarely reach the
minimum chunk size of 6 in the same relative order.

=back

=cut

sub id          { return 'duplicate_code'                                       }
sub name        { return 'Duplicate Code'                                       }
sub description { return 'Detects copy-paste code blocks across source files'   }
sub weight      { return 3                                                      }
sub category    { return 'quality'                                              }

=head2 run

=head3 PURPOSE

Extract code chunks from all source files, identify cross-file duplicates, and
return a scored Result.

=head3 API SPECIFICATION

=head4 INPUT

  dist     Test::CPAN::Health::Distribution  required
  context  Hashref                           optional

=head4 OUTPUT

L<Test::CPAN::Health::Result> with check_id C<'duplicate_code'>.

=head3 MESSAGES

  Code  | Severity | Message                                     | Resolution
  ------+----------+---------------------------------------------+-----------
  DC001 | SKIP     | No source files found                       | Add source files
  DC002 | PASS     | No cross-file duplicate code blocks found   |
  DC003 | WARN     | N duplicate code block(s) found             | Refactor to shared sub
  DC004 | FAIL     | Many duplicate code blocks found            | Refactor to shared sub

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  DuplicateCodeOp
  total_chunks : N
  dup_chunks   : N
  score        : 0..100
  -------------------------------------------------------
  total_chunks = 0    => status = pass /\ score = 100
  score >= 90         => status = pass
  score >= 50         => status = warn
  score < 50          => status = fail

=head3 SIDE EFFECTS

Reads source files only; no network or subprocess I/O.

=head3 USAGE EXAMPLE

    my $result = Test::CPAN::Health::Check::DuplicateCode->new->run($dist);
    print $result->summary;

=cut

sub run {
	my ($self, $dist, $context) = @_;

	croak 'dist must be a Test::CPAN::Health::Distribution'
		unless ref($dist) && $dist->isa('Test::CPAN::Health::Distribution');

	my @files = @{ $dist->all_source_files };

	unless (@files) {
		return $self->_skip('No source files found');
	}

	# Map: chunk_key => { file => 1, ... }  (track unique files per chunk)
	my %chunk_files;
	my $total_chunks = 0;

	for my $file (@files) {
		$total_chunks += _index_file_chunks($file, \%chunk_files);
	}

	unless ($total_chunks) {
		return $self->_result(
			status  => 'pass',
			score   => 100,
			summary => 'No code chunks large enough to analyse',
			data    => { name => $self->name, total => 0, duplicates => 0 },
		);
	}

	my @dup_keys = grep { scalar keys %{ $chunk_files{$_} } > 1 } keys %chunk_files;

	my $dup_count = scalar @dup_keys;
	my $score     = int((1 - $dup_count / $total_chunks) * 100);
	$score        = 0 if $score < 0;
	my $status    = $score >= $SCORE_PASS ? 'pass'
	              : $score >= $SCORE_WARN ? 'warn'
	              :                         'fail';

	my @details;
	for my $key (@dup_keys) {
		my @locs = sort keys %{ $chunk_files{$key} };
		my @rels = map { File::Spec->abs2rel($_, $dist->path) } @locs;
		push @details, 'Duplicate block in: ' . join(', ', @rels);
	}

	return $self->_result(
		status  => $status,
		score   => $score,
		summary => $dup_count
			? sprintf('%d duplicate code block(s) found across source files', $dup_count)
			: 'No cross-file duplicate code blocks found',
		details => \@details,
		data    => {
			name       => $self->name,
			total      => $total_chunks,
			duplicates => $dup_count,
		},
	);
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

# Add all CHUNK_SIZE-line windows from $file into %$chunk_files.
# Returns the count of windows added.
sub _index_file_chunks {
	my ($file, $chunk_files) = @_;

	my @code_lines = _code_lines($file);
	return 0 if @code_lines < $CHUNK_SIZE;

	my %seen;
	my $added = 0;
	for my $i (0 .. $#code_lines - $CHUNK_SIZE + 1) {
		my $key = join("\x00", @code_lines[$i .. $i + $CHUNK_SIZE - 1]);
		next if $seen{$key}++;
		$chunk_files->{$key}{$file} = 1;
		$added++;
	}
	return $added;
}

# Return normalised, non-blank, non-comment, non-POD code lines from $file.
sub _code_lines {
	my ($file) = @_;

	open my $fh, '<', $file or return ();
	my @raw = <$fh>;
	close $fh;

	my @lines;
	my $in_pod = 0;

	for my $line (@raw) {
		chomp $line;
		if ($line =~ / ^ = (\w+) /x) {
			$in_pod = ($1 ne 'cut');
			next;
		}
		next if $in_pod;
		my $norm = _normalise_line($line);
		push @lines, $norm if defined $norm;
	}
	return @lines;
}

# Normalise one line; return undef if it should be excluded.
sub _normalise_line {
	my ($line) = @_;

	$line =~ s/ ^ \s+ | \s+ $ //gx;
	$line =~ s/ \s+ / /gx;

	return unless length $line;
	return if $line =~ / ^ [#] /x;
	return if $line eq '1;';
	return if $line =~ / ^ use \s+ (?:strict|warnings|autodie|utf8|parent|base) \b /x;
	return $line;
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
