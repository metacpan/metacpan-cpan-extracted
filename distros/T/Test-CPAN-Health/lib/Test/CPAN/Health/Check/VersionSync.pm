package Test::CPAN::Health::Check::VersionSync;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak carp);
use File::Spec;
use Readonly;
use Params::Validate::Strict qw(validate_strict);

use parent 'Test::CPAN::Health::Check';

our $VERSION = '0.1.0';

Readonly::Scalar my $SCORE_PASS => 90;
Readonly::Scalar my $SCORE_WARN => 50;

=head1 NAME

Test::CPAN::Health::Check::VersionSync - Check that all .pm files declare the same $VERSION

=head1 SYNOPSIS

    use Test::CPAN::Health::Check::VersionSync;

    my $check  = Test::CPAN::Health::Check::VersionSync->new;
    my $result = $check->run($dist);

    printf "%s: %s\n", $result->status, $result->summary;

=head1 DESCRIPTION

Scans all C<.pm> files under C<lib/> for C<$VERSION> declarations and
verifies that every file that declares a version uses the same value as
the distribution version reported in the META file.

Files that do not declare C<$VERSION> at all are not penalised (they may
intentionally inherit a version from a parent namespace).

Score = (in-sync files / files-with-version) * 100.
Status: pass E<ge> 90, warn E<ge> 50, fail otherwise.

=head1 LIMITATIONS

=over 4

=item * Only the first C<our $VERSION = '...';> line in each file is
checked; dynamic version assignment (e.g. via C<version::->new>) is
not supported.

=item * The META version is used as the canonical source; if no META
file is present the check is skipped.

=back

=cut

sub id          { return 'version_sync'                                            }
sub name        { return 'Version Sync'                                            }
sub description { return 'Checks that all .pm files declare the same $VERSION'    }
sub weight      { return 3                                                         }
sub category    { return 'packaging'                                               }

=head2 run

=head3 PURPOSE

Compare the C<$VERSION> declared in each C<.pm> file against the
distribution version from META, reporting any files that are out of sync.

=head3 API SPECIFICATION

=head4 INPUT

  dist     Test::CPAN::Health::Distribution  required
  context  Hashref                           optional

=head4 OUTPUT

L<Test::CPAN::Health::Result> with check_id C<'version_sync'>.

=head3 MESSAGES

  Code  | Severity | Message                                        | Resolution
  ------+----------+------------------------------------------------+-----------
  VS001 | SKIP     | No META file found                             | Add META file
  VS002 | SKIP     | No .pm files found                             | Add lib/ modules
  VS003 | SKIP     | META version not available                     | Add version to META
  VS004 | PASS     | All N file(s) with $VERSION in sync            |
  VS005 | PASS     | No .pm files declare $VERSION                  |
  VS006 | WARN     | N file(s) have mismatched $VERSION             | Update $VERSION
  VS007 | FAIL     | Most files have mismatched $VERSION            | Update $VERSION

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  VersionSyncOp
  meta_ver   : String | undefined
  files      : seq FileName
  mismatched : seq FileName
  -------------------------------------------------------
  meta = undefined       => status = skip
  meta_ver = undefined   => status = skip
  #files = 0             => status = skip
  #mismatched = 0        => status = pass /\ score = 100
  score >= 90            => status = pass
  score >= 50            => status = warn
  score < 50             => status = fail

=head3 SIDE EFFECTS

Reads each C<.pm> file once; no network I/O.

=head3 USAGE EXAMPLE

    my $result = Test::CPAN::Health::Check::VersionSync->new->run($dist);
    print $result->summary;

=cut

sub run {
	my ($self, $dist, $context) = @_;

	croak 'dist must be a Test::CPAN::Health::Distribution'
		unless ref($dist) && $dist->isa('Test::CPAN::Health::Distribution');

	my $meta = $dist->meta;
	return $self->_skip('No META file found -- cannot determine canonical version')
		unless $meta;

	my $meta_ver = $dist->version;
	return $self->_skip('META version not available')
		unless defined $meta_ver && length $meta_ver;

	my @pm_files = @{ $dist->pm_files };
	return $self->_skip('No .pm files found under lib/')
		unless @pm_files;

	my @mismatched;
	my $n_with_version = 0;

	(my $norm_meta = $meta_ver) =~ s/ ^ v //x;

	for my $file (@pm_files) {
		my $file_ver = _extract_version($file);
		next unless defined $file_ver;
		$n_with_version++;
		(my $norm_file = $file_ver) =~ s/ ^ v //x;
		if ($norm_file ne $norm_meta) {
			my $rel = File::Spec->abs2rel($file, $dist->path);
			push @mismatched, "$rel declares $file_ver (expected $norm_meta)";
		}
	}

	unless ($n_with_version) {
		return $self->_result(
			status  => 'pass',
			score   => 100,
			summary => 'No .pm files declare $VERSION',
			data    => { name => $self->name, meta_version => $norm_meta,
			             checked => 0, mismatched => 0 },
		);
	}

	my $n_bad = scalar @mismatched;
	if ($n_bad == 0) {
		return $self->_result(
			status  => 'pass',
			score   => 100,
			summary => "All $n_with_version file(s) with \$VERSION are in sync ($norm_meta)",
			data    => { name => $self->name, meta_version => $norm_meta,
			             checked => $n_with_version, mismatched => 0 },
		);
	}

	my $score  = int(100 * ($n_with_version - $n_bad) / $n_with_version);
	my $status = $n_bad == 0          ? 'pass'
	           : $score >= $SCORE_PASS ? 'pass'
	           : $score >= $SCORE_WARN ? 'warn'
	           :                         'fail';

	return $self->_result(
		status  => $status,
		score   => $score,
		summary => "$n_bad of $n_with_version file(s) have \$VERSION out of sync with META ($norm_meta)",
		details => \@mismatched,
		data    => {
			name         => $self->name,
			meta_version => $norm_meta,
			checked      => $n_with_version,
			mismatched   => $n_bad,
		},
	);
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

# Extract the first $VERSION value from a .pm file.
# Returns undef if no declaration is found.
sub _extract_version {
	my ($file) = @_;

	open my $fh, '<', $file or return;
	while (my $line = <$fh>) {
		if ($line =~ / our \s+ \$VERSION \s* = \s* ['"] ( [^'"]+ ) ['"] /x) {
			close $fh;
			return $1;
		}
	}
	close $fh;
	return;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Nigel Horne.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

=cut

1;
