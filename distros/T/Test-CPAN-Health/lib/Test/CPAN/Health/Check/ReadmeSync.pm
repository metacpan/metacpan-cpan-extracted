package Test::CPAN::Health::Check::ReadmeSync;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak carp);
use File::Spec;
use Readonly;
use Params::Validate::Strict qw(validate_strict);

use parent 'Test::CPAN::Health::Check';

our $VERSION = '0.1.0';

Readonly::Scalar my $SCORE_HAS_README     => 60;
Readonly::Scalar my $SCORE_NAME_MATCH     => 80;
Readonly::Scalar my $SCORE_FULL           => 100;
Readonly::Scalar my $MIN_README_BYTES     => 100;

# Recognised README filenames, in preference order.
Readonly::Array my @README_NAMES => qw(
	README.md
	README.markdown
	README.pod
	README.txt
	README
);

=head1 NAME

Test::CPAN::Health::Check::ReadmeSync - Check that a README exists and reflects the main module

=head1 SYNOPSIS

    use Test::CPAN::Health::Check::ReadmeSync;

    my $check  = Test::CPAN::Health::Check::ReadmeSync->new;
    my $result = $check->run($dist);

    printf "%s: %s\n", $result->status, $result->summary;

=head1 DESCRIPTION

Verifies that the distribution includes a non-trivial README file and that
it mentions the distribution name, indicating it has not been left as a
boilerplate stub.

Score breakdown:

  0    No README file found at all
  60   README found but very short (< 100 bytes) -- likely a placeholder
  80   README found and non-trivial, but distribution name not mentioned
  100  README found, non-trivial, and mentions the distribution name

=head1 LIMITATIONS

=over 4

=item * Only the content of the README is checked, not whether it is
up-to-date with the current C<DESCRIPTION> or C<SYNOPSIS> in the POD.

=item * The distribution name match is case-insensitive and converts
C<::> to C<-> before searching.

=back

=cut

sub id          { return 'readme_sync'                                               }
sub name        { return 'README Sync'                                               }
sub description { return 'Checks that a non-trivial README mentioning the dist exists' }
sub weight      { return 2                                                           }
sub category    { return 'packaging'                                                 }

=head2 run

=head3 PURPOSE

Locate a README file and verify it is populated and references the
distribution name.

=head3 API SPECIFICATION

=head4 INPUT

  dist     Test::CPAN::Health::Distribution  required
  context  Hashref                           optional

=head4 OUTPUT

L<Test::CPAN::Health::Result> with check_id C<'readme_sync'>.

=head3 MESSAGES

  Code  | Severity | Message                                             | Resolution
  ------+----------+-----------------------------------------------------+-----------
  RS001 | FAIL     | No README file found                                | Add README.md
  RS002 | WARN     | README is very short (< 100 bytes)                  | Expand README
  RS003 | WARN     | README does not mention the distribution name       | Update README
  RS004 | PASS     | README found and mentions the distribution name     |

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  ReadmeSyncOp
  dist_name  : String | undefined
  readme     : FileName | undefined
  content    : String
  -------------------------------------------------------
  readme = undefined          => status = fail /\ score = 0
  #content < 100              => status = warn /\ score = 60
  dist_name not in content    => status = warn /\ score = 80
  dist_name in content        => status = pass /\ score = 100

=head3 SIDE EFFECTS

Reads at most one file from disk; no network I/O.

=head3 USAGE EXAMPLE

    my $result = Test::CPAN::Health::Check::ReadmeSync->new->run($dist);
    print $result->summary;

=cut

sub run {
	my ($self, $dist, $context) = @_;

	croak 'dist must be a Test::CPAN::Health::Distribution'
		unless ref($dist) && $dist->isa('Test::CPAN::Health::Distribution');

	my ($readme_path, $readme_name) = _find_readme($dist->path);

	unless (defined $readme_path) {
		return $self->_result(
			status  => 'fail',
			score   => 0,
			summary => 'No README file found',
			details => [
				'Add README.md (or README.pod / README.txt)',
				'Tools: Pod::Markdown, pod2text, or Dist::Zilla::Plugin::ReadmeAnyFromPod',
			],
			data => { name => $self->name, readme => undef },
		);
	}

	my $content = _read_file($readme_path);

	if (length($content) < $MIN_README_BYTES) {
		return $self->_result(
			status  => 'warn',
			score   => $SCORE_HAS_README,
			summary => "README ($readme_name) is very short -- likely a placeholder",
			details => [ "Expand $readme_name with at least a NAME, SYNOPSIS, and DESCRIPTION" ],
			data    => { name => $self->name, readme => $readme_name },
		);
	}

	my $dist_name = $dist->name // '';
	(my $hyphen_form  = $dist_name) =~ s/ :: /-/gx;
	(my $module_form  = $dist_name) =~ s/ -  /::/gx;

	my $mentions = ($hyphen_form && $content =~ / \Q$hyphen_form\E /xi)
	            || ($module_form && $content =~ / \Q$module_form\E /xi);

	unless ($mentions) {
		return $self->_result(
			status  => 'warn',
			score   => $SCORE_NAME_MATCH,
			summary => "README ($readme_name) does not mention the distribution name",
			details => [
				"Update $readme_name to mention '$hyphen_form' or '$module_form'",
			],
			data => { name => $self->name, readme => $readme_name, dist_name => $dist_name },
		);
	}

	return $self->_result(
		status  => 'pass',
		score   => $SCORE_FULL,
		summary => "README ($readme_name) found and mentions the distribution name",
		data    => { name => $self->name, readme => $readme_name, dist_name => $dist_name },
	);
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

# Locate the first recognised README file under $root.
# Returns (absolute_path, basename) or (undef, undef).
sub _find_readme {
	my ($root) = @_;
	for my $name (@README_NAMES) {
		my $path = File::Spec->catfile($root, $name);
		return ($path, $name) if -f $path;
	}
	return (undef, undef);
}

# Read the full contents of $file; return empty string on failure.
sub _read_file {
	my ($file) = @_;
	open my $fh, '<', $file or return '';
	local $/ = undef;
	my $content = <$fh>;
	close $fh;
	return $content // '';
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
