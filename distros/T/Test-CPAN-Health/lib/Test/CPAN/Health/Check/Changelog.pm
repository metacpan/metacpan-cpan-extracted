package Test::CPAN::Health::Check::Changelog;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak carp);
use File::Spec;
use Readonly;
use Params::Validate::Strict qw(validate_strict);

use parent 'Test::CPAN::Health::Check';

our $VERSION = '0.1.0';

Readonly::Scalar my $SCORE_PASS        => 100;
Readonly::Scalar my $SCORE_NO_VERSION  =>  50;
Readonly::Scalar my $SCORE_EMPTY       =>  10;
Readonly::Scalar my $SCORE_NONE        =>   0;

# Recognised changelog filenames, checked in preference order.
# 'Changes' is the CPAN convention; others are common alternatives.
Readonly::Array my @CHANGELOG_NAMES => qw(
	Changes Changelog CHANGES ChangeLog CHANGELOG CHANGELOG.md NEWS NEWS.md
);

=head1 NAME

Test::CPAN::Health::Check::Changelog - Check that a changelog file is present and has an entry for the current version

=head1 SYNOPSIS

    use Test::CPAN::Health::Check::Changelog;

    my $check  = Test::CPAN::Health::Check::Changelog->new;
    my $result = $check->run($dist);

    printf "%s: %s\n", $result->status, $result->summary;

=head1 DESCRIPTION

Verifies that the distribution root contains a changelog file
(C<Changes>, C<Changelog>, C<CHANGES>, C<ChangeLog>, C<CHANGELOG>,
C<CHANGELOG.md>, C<NEWS>, or C<NEWS.md>) and, when the distribution version
is determinable from META, that the file contains a release entry for that
version.

Score matrix:

=over 4

=item * 100 -- Changelog found with an entry for the current version (or version is unknown).

=item *  50 -- Changelog file found with content, but no entry for the current version.

=item *  10 -- Changelog file exists but is empty.

=item *   0 -- No changelog file found.

=back

=head1 LIMITATIONS

=over 4

=item * Version-entry detection is heuristic.  It matches the most common
CPAN (C<0.01  YYYY-MM-DD>) and Keep a Changelog (C<[0.01] - YYYY-MM-DD>)
formats but may miss exotic styles.

=item * Only the distribution root directory is searched; changelogs in
subdirectories are not recognised.

=back

=cut

sub id          { return 'changelog'                                                     }
sub name        { return 'Changelog'                                                     }
sub description { return 'Checks that a changelog file exists with a version entry'     }
sub weight      { return 3                                                               }
sub category    { return 'packaging'                                                     }

=head2 run

=head3 PURPOSE

Locate a changelog file in the distribution root and verify it contains a
release entry for the current version.

=head3 API SPECIFICATION

=head4 INPUT

  dist     Test::CPAN::Health::Distribution  required
  context  Hashref                           optional

=head4 OUTPUT

L<Test::CPAN::Health::Result> with check_id C<'changelog'>.

=head3 MESSAGES

  Code  | Severity | Message                                          | Resolution
  ------+----------+--------------------------------------------------+-----------
  CL001 | FAIL     | No changelog file found                          | Create a Changes file
  CL002 | FAIL     | Changes exists but is empty                      | Add release notes
  CL003 | WARN     | Changes found but no entry for version N.NN      | Add a version entry
  CL004 | PASS     | Changes found with entry for version N.NN        |
  CL005 | PASS     | Changes found (version not determinable)         |

=head3 FORMAL SPECIFICATION

  Pre:  dist isa Test::CPAN::Health::Distribution
  Post: (no changelog)  => status = fail  /\ score = 0
        (empty file)    => status = fail  /\ score = 10
        (no ver entry)  => status = warn  /\ score = 50
        (ver entry ok)  => status = pass  /\ score = 100

=head3 SIDE EFFECTS

Reads at most one file from disk.

=head3 USAGE EXAMPLE

    my $result = Test::CPAN::Health::Check::Changelog->new->run($dist);
    print $result->summary;

=cut

sub run {
	my ($self, $dist, $context) = @_;

	croak 'dist must be a Test::CPAN::Health::Distribution'
		unless ref($dist) && $dist->isa('Test::CPAN::Health::Distribution');

	# Locate the first changelog file that exists in the distribution root.
	my $changelog_path;
	my $changelog_name;
	for my $name (@CHANGELOG_NAMES) {
		my $p = $dist->file_path($name);
		if (defined $p) {
			$changelog_path = $p;
			$changelog_name = $name;
			last;
		}
	}

	unless (defined $changelog_path) {
		my $list = join ', ', @CHANGELOG_NAMES;
		return $self->_result(
			status  => 'fail',
			score   => $SCORE_NONE,
			summary => 'No changelog file found',
			details => [
				"Create a 'Changes' file in the distribution root",
				"Recognised names: $list",
				"Recommended format: \"0.01  YYYY-MM-DD\" followed by indented bullet points",
			],
			data    => { name => $self->name },
		);
	}

	# Read the changelog content.  file_path verified existence so open
	# failures are unexpected (permissions race); autodie will propagate them.
	open my $fh, '<', $changelog_path;
	local $/ = undef;
	my $content = <$fh>;
	close $fh;

	if (!defined $content || $content !~ /\S/x) {
		return $self->_result(
			status  => 'fail',
			score   => $SCORE_EMPTY,
			summary => "$changelog_name exists but is empty",
			details => [ "Add release notes for the current version to $changelog_name" ],
			data    => { name => $self->name, file => $changelog_name },
		);
	}

	# Try to locate an entry for the current distribution version.
	my $dist_version = $dist->version;
	unless (defined $dist_version && length $dist_version) {
		return $self->_result(
			status  => 'pass',
			score   => $SCORE_PASS,
			summary => "$changelog_name found with content (distribution version not determinable)",
			data    => { name => $self->name, file => $changelog_name },
		);
	}

	# Match common release-entry formats (split into qr// per PBP):
	#   0.1.0  2026-07-03              (CPAN standard)
	#   v0.1.0  2026-07-03            (with v prefix)
	#   ## [0.1.0] - 2026-07-03       (Keep a Changelog)
	#   version 0.1.0  /  release 0.1.0
	# Strip any leading 'v' before quotemeta so that the v? in each regex
	# handles both "v0.1.0" and "0.1.0" in the file regardless of whether
	# CPAN::Meta normalized the version string to include a v prefix.
	(my $bare_version = $dist_version) =~ s/ ^ v //ix;
	my $v           = quotemeta($bare_version);
	my $re_standard = qr/ (?: ^ | \n ) [^\n]* v? $v \s              /xi;
	my $re_keepal   = qr/ \[ \s* v? $v \s* \]                       /xi;
	my $re_prose    = qr/ (?: version | release ) \s+ v? $v \b      /xi;
	my $has_entry   = $content =~ $re_standard
	               || $content =~ $re_keepal
	               || $content =~ $re_prose;

	unless ($has_entry) {
		return $self->_result(
			status  => 'warn',
			score   => $SCORE_NO_VERSION,
			summary => "$changelog_name found but contains no entry for version $dist_version",
			details => [
				"Add a release entry for version $dist_version to $changelog_name",
				"Example: \"$dist_version  " . _today() . "\"",
			],
			data    => {
				name    => $self->name,
				file    => $changelog_name,
				version => $dist_version,
			},
		);
	}

	return $self->_result(
		status  => 'pass',
		score   => $SCORE_PASS,
		summary => "$changelog_name found with entry for version $dist_version",
		data    => {
			name    => $self->name,
			file    => $changelog_name,
			version => $dist_version,
		},
	);
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

sub _today {
	my @t = localtime;
	return sprintf '%04d-%02d-%02d', $t[5] + 1900, $t[4] + 1, $t[3];
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
